
`include "scmem.vh"
`define DR_PASSTHROUGH

`define TEST_OLD


// Directory. Cache equivalent to 2MBytes/ 16 Way assoc
//
// Config size: 1M, 2M, 4M, 16M 16 way
//
// Assume a 64bytes line
//
// Conf Pending Requests. Two queues: one for request another for prefetch
//
// If prefetch queue is full, drop oldest 
//
// Parameter for the # of entry to remember: 4,8,16
// 
// For replacement use HawkEye or RRIP

//This has to be here for snoop acks. Current unused signals are allf ro snoop acks which the passthrough does not use
//because the directory does not snoop in the passthrough.
/* verilator lint_off UNUSED */



module directory_bank
#(parameter Directory_Id=0)
(
   input                           clk
  ,input                           reset

  // L2s interface
  ,input                           l2todr_pfreq_valid
  ,output                          l2todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2todr_pfreq       // NOTE: pfreq does not have ack if dropped

  ,input                           l2todr_req_valid
  ,output logic                    l2todr_req_retry
  ,input  I_l2todr_req_type        l2todr_req

  ,output                          drtol2_snack_valid
  ,input                           drtol2_snack_retry
  ,output I_drtol2_snack_type      drtol2_snack

  ,input                           l2todr_disp_valid
  ,output                          l2todr_disp_retry
  ,input  I_l2todr_disp_type       l2todr_disp

  ,output                          drtol2_dack_valid
  ,input                           drtol2_dack_retry
  ,output I_drtol2_dack_type       drtol2_dack

  ,input                           l2todr_snoop_ack_valid
  ,output                          l2todr_snoop_ack_retry
  ,input I_drsnoop_ack_type        l2todr_snoop_ack

  // Memory interface
  // If nobody has the data, send request to memory

  ,output logic                    drtomem_req_valid
  ,input                           drtomem_req_retry
  ,output I_drtomem_req_type       drtomem_req

  ,input                           memtodr_ack_valid
  ,output                          memtodr_ack_retry
  ,input  I_memtodr_ack_type       memtodr_ack

  ,output                          drtomem_wb_valid
  ,input                           drtomem_wb_retry
  ,output I_drtomem_wb_type        drtomem_wb // Plain WB, no disp ack needed

  ,output logic                    drtomem_pfreq_valid
  ,input  logic                    drtomem_pfreq_retry
  ,output I_drtomem_pfreq_type     drtomem_pfreq

  );
  
`ifdef DR_PASSTHROUGH
  
  
  
  //The fflop below uses type I_l2todr_pfreq_type as its input and output. While I_drtomem_pfreq_type is basically the same struct,
  //I divided the fflop output and assignment so there would not be any conflicts.
  I_l2todr_pfreq_type          drff_pfreq;
  assign drtomem_pfreq.paddr = drff_pfreq.paddr;
  assign drtomem_pfreq.nid   = drff_pfreq.nid;
  
  fflop #(.Size($bits(I_l2todr_pfreq_type))) pfreq_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_pfreq),
    .dinValid (l2todr_pfreq_valid),
    .dinRetry (l2todr_pfreq_retry),

    .q        (drff_pfreq),
    .qValid   (drtomem_pfreq_valid),
    .qRetry   (drtomem_pfreq_retry)
  );
  


  
  
`ifdef TEST_OLD
//Din will be mostly entries from the l2todr_req
  I_drtomem_req_type              drtomem_req_next;
  logic                           drtomem_req_next_valid;
  logic                           drtomem_req_next_retry;
  logic                           id_ram_write_next_valid;
  logic                           id_ram_write_next_retry;
  
  
  assign drtomem_req_next.paddr = l2todr_req.paddr;
  assign drtomem_req_next.cmd   = l2todr_req.cmd;
  assign drtomem_req_next.drid  = drid_valid_encoder;
  
  //valid will depend on: available DRID, RAM ready for writing, and drtomem_fflop ready
  assign l2todr_req_retry        = !drid_valid || drtomem_req_next_retry || id_ram_write_next_retry;
  assign drtomem_req_next_valid  = l2todr_req_valid && drid_valid && !id_ram_write_next_retry;
  assign id_ram_write_next_valid = l2todr_req_valid && drid_valid && !drtomem_req_next_retry;

  fflop #(.Size($bits(I_drtomem_req_type))) drtomem_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtomem_req_next),
    .dinValid (drtomem_req_next_valid),
    .dinRetry (drtomem_req_next_retry),

    .q        (drtomem_req),
    .qValid   (drtomem_req_valid),
    .qRetry   (drtomem_req_retry)
  );
  
  
`else
  //Creating this temporary area to test a new way to manage requests
  //The first stage in a request is accessing the Tag bank. However, there are some prerequisites required
  //before a request can get to this stage.
  //1) The Tag bank is not signalling a retry. Obviously if the Tag bank is not ready, then we have to wait.
  //2) There needs to be space available in the request buffer which holds requests that are currently being snooped. The question
  //   obviously is why does this need space for every request? This is because we do not know if we need to snoop until after the Tag
  //   bank access, but we do not want the request to get stuck in this stage of the pipeline if the request buffer is full.
  //   This can cause a deadlock because other parts of the directory need access to the Tag and Entry banks but a blocked request could
  //   cause these parts to also be blocked (disp, ack) which we want to avoid. There is a solution to allow snoop requests to be queued
  //   but this would need a queue implemented which there currently is not.
  //3) There needs to be an available DRID. The directory can maintain 63 different DRIDs and we need to make sure there is one available.
  //4) The fflop that maintains the pipeline of the RAM banks are available. This availability is mostly trivial but still required to
  //   check when processing a request.
  
  //Number of requests that the directly can currently handle. This number should refer to the snoops it can handle, but right now it refers
  //to all requests. Max number of requests is currently 4. Will eventually change with an input parameter.
  localparam OUTSTANDING_REQUEST_BITS = 2;
  localparam MAX_OUTSTANDING_REQUESTS = 1<<OUTSTANDING_REQUEST_BITS;
  
  //Forgetting the -1 on the size is not a mistake, the extra bit is for valid.
  logic [$bits(I_drtomem_req_type):0] req_buf [0:MAX_OUTSTANDING_REQUESTS-1];
  logic [$bits(I_drtomem_req_type):0] req_buf_next [0:MAX_OUTSTANDING_REQUESTS-1];
  
  always_comb begin
    req_buf_next = req_buf;
    
    if(l2todr_req_valid && !l2todr_req_retry) begin
    //acquire space in buffer
      req_buf_next[req_buf_valid_encoder] = {1'b1, tag_req_ff_stage_next};
    end
    
    if(drtomem_req_next_valid && !drtomem_req_next_retry) begin
    //release the request buffer slot...
    //Whole value is reset rather than just the valid bit because it is really annoying
    //to set just that bit and this is simpler. Will come back to fix this later, but will
    //not affect behaviour.
      req_buf_next[req_buf_release_pos] = {1'b0,{$bits(I_drtomem_req_type){1'b0}}};
    end
  end
  
  genvar i;  
  generate  
    for (i=0; i < MAX_OUTSTANDING_REQUESTS; i=i+1) begin: req_buf_gen 
      flop_r #(.Size($bits(I_drtomem_req_type) + 1), .Reset_Value({1'b0,{$bits(I_drtomem_req_type){1'b0}}}))
        flop_buf_inst 
        (
           .clk(clk)
          ,.reset(reset)
          ,.din(req_buf_next[i])
          ,.q(req_buf[i])
        ); 
    end  
  endgenerate 
  
  //Below is priority encoder to determine the next request buffer position to use when processing a request.
  //Might separate the valid bit to make it simpler.
  localparam MAX_REQ_BUF_VALUE = MAX_OUTSTANDING_REQUESTS-1;
  localparam REQ_BUF_VALID_POS = $bits(I_drtomem_req_type);
 
  logic [OUTSTANDING_REQUEST_BITS-1:0] req_buf_valid_encoder;
  logic req_buf_valid;
  logic [REQ_BUF_VALID_POS:0] req_buf_value_temp;
  always_comb begin  
    //This code was adapted from https://github.com/AmeerAbdelhadi/Indirectly-Indexed-2D-Binary-Content-Addressable-Memory-BCAM/blob/master/pe_bhv.v
    req_buf_valid_encoder = 'b0;
    //illegal assignment supposedly, change to:
    //logic [REQ_BUF_VALID_POS:0] req_buf_value_temp;
    req_buf_value_temp = req_buf[0];
    req_buf_valid = !req_buf_value_temp[REQ_BUF_VALID_POS];
    //Also would need to change the value below. Do this or separate the valid but into separate flops.
    //req_buf_valid = req_buf[0][REQ_BUF_VALID_POS];
    while ((!req_buf_valid) && (req_buf_valid_encoder != MAX_REQ_BUF_VALUE)) begin
      req_buf_valid_encoder = req_buf_valid_encoder + 1 ;
      req_buf_value_temp = req_buf[req_buf_valid_encoder];
      req_buf_valid = !req_buf_value_temp[REQ_BUF_VALID_POS];
    end
  end
  
  
  I_drtomem_req_type              tag_req_ff_stage_next;
  logic                           tag_req_ff_stage_next_valid;
  logic                           tag_req_ff_stage_next_retry;
  logic                           id_ram_write_next_valid;
  logic                           id_ram_write_next_retry;
  
  I_drtomem_req_type              tag_req_ff_stage;
  logic                           tag_req_ff_stage_valid;
  logic                           tag_req_ff_stage_retry;
  
  
  assign tag_req_ff_stage_next.paddr = l2todr_req.paddr;
  assign tag_req_ff_stage_next.cmd   = l2todr_req.cmd;
  assign tag_req_ff_stage_next.drid  = drid_valid_encoder;
  
  //valid will depend on: available DRID, available request buffer space, ID RAM ready for writing, and tag pipeline fflop ready, and Tag bank is available.
  assign l2todr_req_retry = !drid_valid || !req_buf_valid || tag_req_ff_stage_next_retry || id_ram_write_next_retry || tag_bank_next_retry;
  assign tag_req_ff_stage_next_valid = l2todr_req_valid && drid_valid && req_buf_valid && !id_ram_write_next_retry && !tag_bank_next_retry;
  assign id_ram_write_next_valid = l2todr_req_valid && drid_valid && req_buf_valid && !tag_req_ff_stage_next_retry && !tag_bank_next_retry;
  
  //fflop that maintains the pipeline of the request,
  fflop #(.Size($bits(I_drtomem_req_type))) tag_req_stage_fflop (
    .clk      (clk),
    .reset    (reset),

    .din      (tag_req_ff_stage_next),
    .dinValid (tag_req_ff_stage_next_valid),
    .dinRetry (tag_req_ff_stage_next_retry),

    .q        (tag_req_ff_stage),
    .qValid   (tag_req_ff_stage_valid),
    .qRetry   (tag_req_ff_stage_retry)
  );
  
  logic        tag_bank_next_valid;
  logic        tag_bank_next_retry;
  logic        tag_bank_next_we;
  logic [6:0]  tag_bank_next_pos;
  logic [63:0] tag_bank_next_data;
  
  assign tag_bank_next_valid = l2todr_req_valid && drid_valid && req_buf_valid && !tag_req_ff_stage_next_retry && !id_ram_write_next_retry;
  assign tag_bank_next_we = 'b0; //currently not writing
  assign tag_bank_next_pos = l2todr_req.paddr[12:6];
  assign tag_bank_next_data = 'b0;
  
  logic        tag_bank_valid;
  logic        tag_bank_retry;
  logic [63:0] tag_bank_data;
  
  //The Tag bank implemented as a dense 2-cycle RAM which is 8 way associative. Therefore, each entry
  //holds 8 tags. These tags are hashes of the original Tag, so they are only 8 bits long rather than ~35 bits.
  ram_1port_dense 
  #(.Width(64), .Size(128), .Forward(1))
  ram_dense_tag_bank
  ( 
    .clk          (clk)
   ,.reset        (reset)

   ,.req_valid    (tag_bank_next_valid)
   ,.req_retry    (tag_bank_next_retry)
   ,.req_we       (tag_bank_next_we)
   ,.req_pos      (tag_bank_next_pos)
   ,.req_data     (tag_bank_next_data)

   ,.ack_valid    (tag_bank_valid)
   ,.ack_retry    (tag_bank_retry)
   ,.ack_data     (tag_bank_data)
  );
  
  logic       tag_hit;
  logic [7:0] tag_comp_result;
  integer j;
  
  always_comb begin
    //compare all 8 tags to the hash of the request tag. Should always result in a one-hot encoding result
    //or nothing
    //Did not want to remove this look because it look nice but is not compiling.
    // for(j = 0; j < 8; j = j + 1) begin
      // tag_comp_result[j] = (tag_bank_data[(j+1)*8-1:j*8] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    // end
    tag_comp_result[0] = (tag_bank_data[7:0] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    tag_comp_result[1] = (tag_bank_data[15:8] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    tag_comp_result[2] = (tag_bank_data[23:16] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    tag_comp_result[3] = (tag_bank_data[31:24] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    tag_comp_result[4] = (tag_bank_data[39:32] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    tag_comp_result[5] = (tag_bank_data[47:40] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    tag_comp_result[6] = (tag_bank_data[55:48] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    tag_comp_result[7] = (tag_bank_data[63:56] == compute_dr_hpaddr_hash(tag_req_ff_stage.paddr));
    
    //OR all bits of the result to check if there is a hit in the Tags
    //A miss would result in a request to memory. A hit would result in a check of the Entry bank and then a snoop.
    tag_hit = |tag_comp_result;
  end
  
  I_drtomem_req_type              drtomem_req_next;
  logic                           drtomem_req_next_valid;
  logic                           drtomem_req_next_retry;
  
  always_comb begin
    if(!tag_hit) begin
      drtomem_req_next = tag_req_ff_stage;
      drtomem_req_next_valid = tag_bank_valid && tag_req_ff_stage_valid;
      tag_bank_retry = drtomem_req_next_retry || (!drtomem_req_next_valid && tag_bank_valid);
      tag_req_ff_stage_retry = drtomem_req_next_retry || (!drtomem_req_next_valid && tag_req_ff_stage_valid);
    end else begin
      //should not enter this... something went wrong if this is entered for now since all tag accesses should be a miss.
      //Turns out, tag hits can occur with nothing written, but mostly bugs out since I was not checking if the tag_bank data was valid.
      //Setting this temporarily.
      drtomem_req_next = tag_req_ff_stage;
      drtomem_req_next_valid = tag_bank_valid && tag_req_ff_stage_valid;
      tag_bank_retry = drtomem_req_next_retry || (!drtomem_req_next_valid && tag_bank_valid);
      tag_req_ff_stage_retry = drtomem_req_next_retry || (!drtomem_req_next_valid && tag_req_ff_stage_valid);
    end
  end
  
  
  
  //This fflop determines the next request sent to memory. Right now, only misses from an invalid tag can occur.
  //However, a miss can also occur from a snoop.
  fflop #(.Size($bits(I_drtomem_req_type))) drtomem_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtomem_req_next),
    .dinValid (drtomem_req_next_valid),
    .dinRetry (drtomem_req_next_retry),

    .q        (drtomem_req),
    .qValid   (drtomem_req_valid),
    .qRetry   (drtomem_req_retry)
  );
  
  logic temp_buf_valid_0;
  logic temp_buf_valid_1;
  logic temp_buf_valid_2;
  logic temp_buf_valid_3;
  I_drtomem_req_type temp_buf_req_0;
  I_drtomem_req_type temp_buf_req_1;
  I_drtomem_req_type temp_buf_req_2;
  I_drtomem_req_type temp_buf_req_3;
  logic [OUTSTANDING_REQUEST_BITS-1:0] req_buf_release_pos;
  
  // //This is somewhat of an encoder to determine which buffer value needs to be released. 
  // //To Recap: When a request occurs, the directory will assign buffer space to it just in case in might snoop. When it gets to this point and
  // //is determined a miss, we need to release that buffer space. The release happens above in a comb block near where the buffer is instantiated
  // //but this block determines which space needs to be released.
  // always_comb begin
    // //this assumes that there is a position in the buffer that this request takes up. Other parts may clear that
    // //so I may add some sort of abort boolean to prevent clearing not in use buffers.
    // {temp_buf_valid,temp_buf_req} = req_buf[0];
    // req_buf_release_pos = 'b0;
    // while((!temp_buf_valid && temp_buf_req.drid != drtomem_req_next.drid) || req_buf_release_pos == MAX_REQ_BUF_VALUE) begin
      // req_buf_release_pos = req_buf_release_pos + 1;
      // {temp_buf_valid,temp_buf_req} = req_buf[req_buf_release_pos];
    // end
  // end
  
  always_comb begin
    {temp_buf_valid_0,temp_buf_req_0} = req_buf[0];
    {temp_buf_valid_1,temp_buf_req_1} = req_buf[1];
    {temp_buf_valid_2,temp_buf_req_2} = req_buf[2];
    {temp_buf_valid_3,temp_buf_req_3} = req_buf[3];
    req_buf_release_pos = 'b0;
    if         (temp_buf_valid_0 && temp_buf_req_0.drid == drtomem_req_next.drid) begin
      req_buf_release_pos = 2'd0;
    end else if(temp_buf_valid_1 && temp_buf_req_1.drid == drtomem_req_next.drid) begin
      req_buf_release_pos = 2'd1;
    end else if(temp_buf_valid_2 && temp_buf_req_2.drid == drtomem_req_next.drid) begin
      req_buf_release_pos = 2'd2;
    end else if(temp_buf_valid_3 && temp_buf_req_3.drid == drtomem_req_next.drid) begin
      req_buf_release_pos = 2'd3;
    end 
  end
  
  //Number of bits per entry. Arbitrary for now. Will be parametrically defined at some time.
  localparam DR_ENTRY_SIZE = 20;
  
  logic        entry_bank_next_valid;
  logic        entry_bank_next_retry;
  logic        entry_bank_next_we;
  logic [9:0]  entry_bank_next_pos;
  logic [DR_ENTRY_SIZE-1:0] entry_bank_next_data;
  
  assign entry_bank_next_valid = 'b0;
  assign entry_bank_next_we = 'b0;
  assign entry_bank_next_pos = 'b0;
  assign entry_bank_next_data = 'b0;
  
  logic        entry_bank_valid;
  logic        entry_bank_retry;
  logic [DR_ENTRY_SIZE-1:0] entry_bank_data;
  
  assign entry_bank_retry = 'b0;
  
  //The Directory Entry bank implemented as a dense 2-cycle RAM which is direct mapped. However, we use information from the Tag
  //bank in order to index this RAM in addition to bits from the paddr
  ram_1port_dense 
  #(.Width(DR_ENTRY_SIZE), .Size(1024), .Forward(1))
  ram_dense_entry_bank
  ( 
    .clk          (clk)
   ,.reset        (reset)

   ,.req_valid    (entry_bank_next_valid)
   ,.req_retry    (entry_bank_next_retry)
   ,.req_we       (entry_bank_next_we)
   ,.req_pos      (entry_bank_next_pos)
   ,.req_data     (entry_bank_next_data)

   ,.ack_valid    (entry_bank_valid)
   ,.ack_retry    (entry_bank_retry)
   ,.ack_data     (entry_bank_data)
  );
`endif
  
  //Adding some temporary code here
  logic [`DR_REQIDS-1:0] drid_valid_vector;
  logic [`DR_REQIDS-1:0] drid_valid_vector_next;
  
  
  //This always block combined with the flop represents the logic used to maintain a vector which remembers which DRIDs are in use 
  //and which are available. This valid is sent to a priority encoder which determines the next available DRID to be used in the pending
  //request.
  //DRID are marked in use when a request from the L2 has been accepted by the directory and they are released when an ACK for that request 
  //has been processed by the directory.
  always_comb begin
    drid_valid_vector_next = drid_valid_vector;
    
    if(id_ram_write_next_valid && !id_ram_write_next_retry) begin
        drid_valid_vector_next[drid_valid_encoder] = 1'b0;
    end
    
    //releasing DRIDs will probably change because this logic release them after I read the ram values
    if(id_ram_read_next_valid && !id_ram_read_next_retry) begin
      drid_valid_vector_next[memtodr_ack.drid] = 1'b1;
    end
    
  end
  
  //should probably change this is an fflop
  //That way, the valids can come from inputs
  flop_r #(.Size(`DR_REQIDS), .Reset_Value({`DR_REQIDS{1'b1}})) drid_vector_flop_r (
    .clk      (clk)
   ,.reset    (reset)
   ,.din      (drid_valid_vector_next)
   ,.q        (drid_valid_vector)
  );
  
  

  //Logic for acknowledgements
  logic                   memtodr_ack_ff_next_valid;
  logic                   memtodr_ack_ff_next_retry;
  logic                   id_ram_read_next_valid;
  logic                   id_ram_read_next_retry;
  
  always_comb begin
    if(memtodr_ack.drid == {`DR_REQIDBITS{1'b0}}) begin //0 is an invalid drid, this is checked here
      //this indicates we do not need to use the RAM, so only base handshake on fflop valid/retry
      memtodr_ack_ff_next_valid = memtodr_ack_valid; 
      memtodr_ack_retry = memtodr_ack_ff_next_retry;
    end else begin
      //otherwise, handshake logic becomes similar to that of a fork
      memtodr_ack_ff_next_valid = memtodr_ack_valid && !id_ram_read_next_retry;
      memtodr_ack_retry = memtodr_ack_ff_next_retry || id_ram_read_next_retry;
    end
  end
  
  //This is moved into another always block because it causes warnings if placed into the same block as the one above.
  always_comb begin
    if(memtodr_ack.drid == {`DR_REQIDBITS{1'b0}}) begin //0 is an invalid drid, this is checked here
      //this indicates we do not need to use the RAM, so only base handshake on fflop valid/retry
      id_ram_read_next_valid = 1'b0;
    end else begin
      //otherwise, handshake logic becomes similar to that of a fork
      id_ram_read_next_valid = memtodr_ack_valid && !memtodr_ack_ff_next_retry;
    end
  end
  
  I_memtodr_ack_type      memtodr_ack_ff;
  logic                   memtodr_ack_ff_valid;
  logic                   memtodr_ack_ff_retry;

  
  //This is a pipeline stage for the memory acknowledgement. This operation requires a RAM lookup which takes one cycle.
  //A pipeline stage is used to remember the acknowledgement during the RAM cycle.
  fflop #(.Size($bits(I_memtodr_ack_type))) memtodr_ack_fflop (
    .clk      (clk),
    .reset    (reset),

    .din      (memtodr_ack),
    .dinValid (memtodr_ack_ff_next_valid),
    .dinRetry (memtodr_ack_ff_next_retry),

    .q        (memtodr_ack_ff),
    .qValid   (memtodr_ack_ff_valid),
    .qRetry   (memtodr_ack_ff_retry)
  );
 
  
  //The ack is more complicated because we have to wait for a read on the RAM. 
  I_drtol2_snack_type     drtol2_snack_next;
  logic                   drtol2_snack_next_valid;
  logic                   drtol2_snack_next_retry;

  always_comb begin
    if(memtodr_ack_ff.drid == {`DR_REQIDBITS{1'b0}}) begin
      //if drid is invalid then this is an ack for a prefetch. Therefore, use the terms in the ack that that are meant for the
      //prefetch. 
      drtol2_snack_next.nid = memtodr_ack_ff.nid; 
      drtol2_snack_next.l2id = {`L2_REQIDBITS{1'b0}};
	    drtol2_snack_next.hpaddr_base = 'b0;
	    drtol2_snack_next.hpaddr_hash = 'b0;
      drtol2_snack_next.paddr = memtodr_ack_ff.paddr;
      
      drtol2_snack_next_valid = memtodr_ack_ff_valid; 
      memtodr_ack_ff_retry = drtol2_snack_next_retry;
      id_ram_retry = 1'b1;
    end else begin
      //If the DRID is valid then ignore the prefetch terms and nid, l2id are set by the RAM
      drtol2_snack_next.nid = id_ram_data[10:6]; //These needs to be changed to match the request nid and l2id.
      drtol2_snack_next.l2id = id_ram_data[5:0];
	    drtol2_snack_next.hpaddr_base = compute_dr_hpaddr_base(memtodr_ack_ff.paddr);
	    drtol2_snack_next.hpaddr_hash = compute_dr_hpaddr_hash(memtodr_ack_ff.paddr);
      //drtol2_snack_next.paddr = 'b0;
      //Paddr should be set to 0 but not doing this to allow testbench to pass for now...
      drtol2_snack_next.paddr = memtodr_ack_ff.paddr;
      
      drtol2_snack_next_valid = memtodr_ack_ff_valid && id_ram_valid; 
      memtodr_ack_ff_retry = drtol2_snack_next_retry || (!drtol2_snack_next_valid && memtodr_ack_ff_valid);
      id_ram_retry = drtol2_snack_next_retry || (!drtol2_snack_next_valid && id_ram_valid);
    end
  end
  
  //The other values are independent of the DRID validity. However, this is an assumption that the "ack", which refers to
  //some command bits, is set by main memory correctly for prefetches and normal requests.
  assign drtol2_snack_next.drid =  {`DR_REQIDBITS{1'b0}}; //This is not a mistake in this case because the drid is required to be 0 on acks, and we do not snoop in passthrough
  assign drtol2_snack_next.snack = memtodr_ack_ff.ack;
  assign drtol2_snack_next.line =  memtodr_ack_ff.line;
  
  //need to set param to assign directory id to input parameter.
  assign drtol2_snack_next.directory_id = Directory_Id[`DR_NDIRSBITS-1:0];
  
  
  fflop #(.Size($bits(I_drtol2_snack_type))) drotol2_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtol2_snack_next),
    .dinValid (drtol2_snack_next_valid),
    .dinRetry (drtol2_snack_next_retry),

    .q        (drtol2_snack),
    .qValid   (drtol2_snack_valid),
    .qRetry   (drtol2_snack_retry)
  );
 
 
  
  
  localparam MAX_DRID_VALUE = `DR_REQIDS-1;
 
  logic [`DR_REQIDBITS-1:0] drid_valid_encoder;
  logic drid_valid;
  always_comb begin 
    //Yes, I know the while loop looks bad, and I agree. The while loop is to allow for parametrization, but this scheme may
    //affect synthesis and may be forced to change.    
    //This for loop implements a priority encoder. It uses a 64 bit vector input which holds
    //a valid bit for every possible DRID. This encoder looks at the bit vector and determines a 
    //valid DRID which can be used for a memory request. The encoder is likely huge based on seeing examples
    //for small priority encoders.
    //The benefits of this scheme are that it does an arbitration of which DRID should be used and it does it quickly.
    //The obvious downsides it the gate count is large. However, we only need one of these.
    
    //This code was adapted from https://github.com/AmeerAbdelhadi/Indirectly-Indexed-2D-Binary-Content-Addressable-Memory-BCAM/blob/master/pe_bhv.v
    drid_valid_encoder = {`DR_REQIDBITS{1'b0}};
    //drid_valid_encoder = 1'b1; //temporary declaration
    drid_valid = 1'b0;
    while ((!drid_valid) && (drid_valid_encoder != MAX_DRID_VALUE)) begin
      drid_valid_encoder = drid_valid_encoder + 1 ;
      drid_valid = drid_valid_vector[drid_valid_encoder];
    end
  end
  
  logic id_ram_next_valid;
  logic id_ram_next_retry;
  logic id_ram_we;
  logic [`DR_REQIDBITS-1:0] id_ram_pos_next;
  
  logic id_ram_valid;
  logic id_ram_retry;
  logic [10:0] id_ram_data;
  
  ram_1port_fast 
   #(.Width(11), .Size(`DR_REQIDS), .Forward(1))
  id_ram ( 
    .clk         (clk)
   ,.reset       (reset)

   ,.req_valid   (id_ram_next_valid)
   ,.req_retry   (id_ram_next_retry)
   ,.req_we      (id_ram_we) 
   ,.req_pos     (id_ram_pos_next)
   ,.req_data    ({l2todr_req.nid,l2todr_req.l2id})

   ,.ack_valid   (id_ram_valid)
   ,.ack_retry   (id_ram_retry)
   ,.ack_data    (id_ram_data)
 );
  
  
  localparam ARBITER_READ_PREFERRED_STATE = 1'b0;
  localparam ARBITER_WRITE_PREFERRED_STATE = 1'b1;
  
  //not assigned: arb_drid_write_valid

  
  logic id_ram_state;
  logic id_ram_state_next;
  //I had to separate the write enable signal into a different always block or else a warning will occur claiming circular logic. This warning appears to be a glitch
  //and should not affect simulation, but I removed it anyway.
  always_comb begin
    id_ram_we = 1'b0;
    if(id_ram_state == ARBITER_READ_PREFERRED_STATE) begin    
      if(id_ram_write_next_valid && !id_ram_read_next_valid) begin
        id_ram_we = 1'b1;
      end
      
    end else begin //state == ARBITER_WRITE_PREFERRED_STATE
      if(id_ram_write_next_valid) begin
        id_ram_we = 1'b1;
      end 
      
    end
  end
  
  //This always blocks performs the next state logic for the DRID RAM READ/WRITE arbiter FSM. It also contains some output logic
  //for the FSM but not all of it. The write enable had to be moved outside the always blocks because it caused warnings to occur
  //when they were in the same always block.
  
  always_comb begin
    //default next state is the current state
    id_ram_state_next = id_ram_state;
    
    //default retry on read or writes is the retry coming from the SRAM, however this will fail in some cases. For example,
    //if retry from SRAM is high and both valids from retry are high then the operation that occurs after the retry falls LOW
    //depends on which state we are in. If the SRAM retry falls low, then the fflops think that their valid goes through, but
    //this will not occur since the state machine only allows one operations to happen. Basically, I solve this by extending
    //the retry during a state transition. Difficult to say if this work 100%, but my notes imply this will work.
    id_ram_read_next_retry = id_ram_next_retry;
    id_ram_write_next_retry = id_ram_next_retry;
    
    //default drid to index RAM is the value used for writing to the RAM
    id_ram_pos_next = drid_valid_encoder;
    
    id_ram_next_valid = 1'b0;
    
    if(id_ram_state == ARBITER_READ_PREFERRED_STATE) begin
      //next state logic
      if(id_ram_read_next_valid && !id_ram_next_retry) begin
        id_ram_state_next = ARBITER_WRITE_PREFERRED_STATE;
      end
      
      //output logic
      if(id_ram_read_next_valid) begin
        id_ram_next_valid = 1'b1;      
        id_ram_write_next_retry = 1'b1; 
        id_ram_pos_next = memtodr_ack.drid;
      end else if(id_ram_write_next_valid) begin
        id_ram_next_valid = 1'b1;
      end
      
    end else begin //state == ARBITER_WRITE_PREFERRED_STATE
    
      if(id_ram_write_next_valid && !id_ram_next_retry) begin
        id_ram_state_next = ARBITER_READ_PREFERRED_STATE;
      end
      
      if(id_ram_write_next_valid) begin
        id_ram_next_valid = 1'b1;
        id_ram_read_next_retry = 1'b1;
      end else if(id_ram_read_next_valid) begin
        id_ram_next_valid = 1'b1;
        id_ram_pos_next = memtodr_ack.drid;
      end
      
    end
  end
  
  flop #(.Bits(1)) sram_arbiter_state_flop (
    .clk      (clk)
   ,.reset    (reset)
   ,.d        (id_ram_state_next)
   ,.q        (id_ram_state)
  );



  //WB start
  I_drtomem_wb_type         drtomem_wb_next;
  logic                     drtomem_wb_next_valid;
  logic                     drtomem_wb_next_retry;
  //Unused signals: nid, l2id, drid, dcmd
  //drid is a special case in passthrough and we should always expect it to be 0 since we are not snooping.
  //Also, I am not sure what mask does.
  //nid and l2id need to be remembered in order to send an ack.
  
  //Always blocks to assign values to drtomem_wb_next. Uses parts of l2todr_disp that are required for write back.
  //Other parts are ignored (for passthrough) or are sent to the fflop that holds the ack back to the L2.
  always_comb begin
    drtomem_wb_next.line = l2todr_disp.line;
    drtomem_wb_next.mask = l2todr_disp.mask;
    drtomem_wb_next.paddr = l2todr_disp.paddr;
  end
  
  //Always block to determine the valid of the memtodr_wb fflop. Depends on: the command type, the disp input valid, and the internal
  //dack fflop retry signal.
  always_comb begin
    drtomem_wb_next_valid = l2todr_disp_valid && !drtol2_dack_next_retry && (l2todr_disp.dcmd != `SC_DCMD_I);  
  end
  
  
  
  //Always blocks for the l2todr_disp_retry signal. The retry is an OR of the dack retry signal as well as the wb retry signal, but the
  //wb retry is ignored if the command is a no displacement. (Nothing written back if there is no displacement.) I should probably include
  //I DRID check here as well.
  always_comb begin
    l2todr_disp_retry = (drtomem_wb_next_retry && (l2todr_disp.dcmd != `SC_DCMD_I)) || drtol2_dack_next_retry;
  end
  
  //fflop for memtodr_ack (memory ack request)
  //connections to drtomem_wb not complete. There is an assumption in this passthrough that the acks are returned in order.
  //The directory should also return an ack which is associated with this write back.
  //bit size of fflop is incorrect
  fflop #(.Size($bits(I_drtomem_wb_type))) memtodr_wb_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtomem_wb_next),
    .dinValid (drtomem_wb_next_valid),
    .dinRetry (drtomem_wb_next_retry),

    .q        (drtomem_wb),
    .qValid   (drtomem_wb_valid),
    .qRetry   (drtomem_wb_retry)
  );
  
  logic drtol2_dack_next_valid;
  logic drtol2_dack_next_retry;
  I_drtol2_dack_type drtol2_dack_next;
  
  //These should have actual values, but I have not implemented that yet.
  assign drtol2_dack_next.nid = l2todr_disp.nid;
  assign drtol2_dack_next.l2id = l2todr_disp.l2id;
  
  //Always blocks for the drtol2_dack_next_valid signal. The fflop for this valid takes in the nid and l2id of the l2todr displacement request.
  //This valid is similar to drtomem_wb_next_valid except it still accept the values if the command prompts no displacement.
  //The last part of this boolean statement says "Listen to the retry signal on the wb fflop or ignore it if the command is a no displacement."
  always_comb begin
    drtol2_dack_next_valid = l2todr_disp_valid && (!drtomem_wb_next_retry || (l2todr_disp.dcmd == `SC_DCMD_I));  
  end
  
  
  //fflop for drtol2_dack (displacement acknowledge)
  //Issues: As of now, the dack will occur even if the memory has not been written back to main memory (It is stuck in the wb fflop with a continuous retry).
  //At this point, acking back the displacement may cause requests to occur on that address even though the data has not been actually written back.
  //There are two ways to address this issue: (1) Check addresses on requests to see if they match the address on the writeback which will cause the request
  //to be blocked until the writeback has completed. (2) Make sure main memory has accepted the writeback before issuing a dack. 
  //Note: (1) needs to be implemented no matter what to enforce coherency between other caches requeseting the data (still does not solve cohereancy problem though)
  //but (1) is not an ideal solution to solve this issue when compared to (2). (2) Will be implemented, but (1) will be implemented first.
  fflop #(.Size($bits(I_drtol2_dack_type))) dack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtol2_dack_next),
    .dinValid (drtol2_dack_next_valid),
    .dinRetry (drtol2_dack_next_retry),

    .q        (drtol2_dack),
    .qValid   (drtol2_dack_valid),
    .qRetry   (drtol2_dack_retry)
  );
  
  
  logic drff_snoop_ack_valid;
  logic drff_snoop_ack_retry;
  I_drsnoop_ack_type drff_snoop_ack;
  


  //Therefore, I am not making this valid yet.
  assign drff_snoop_ack_retry= 1'b0;
  
  //fflop for l2todr_snoop_ack (snoop acknowledge)
  //Right now this is an output, but this is likely a type and it is actually a type.
  //Therefore, I am just going to output nothing relevant on this for now.
  fflop #(.Size($bits(I_drsnoop_ack_type))) snoop_ack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_snoop_ack),
    .dinValid (l2todr_snoop_ack_valid),
    .dinRetry (l2todr_snoop_ack_retry),

    .q        (drff_snoop_ack),
    .qValid   (drff_snoop_ack_valid),
    .qRetry   (drff_snoop_ack_retry)
  );
  
  //What needs to be done for passthrough:
  //1) Add connections related to displacement ack. (done)
  //2) Set a connections to snoop ack which does nothing because the system cannot snoop. (done)
  //3) Set the drid to a counter to at least change the value. (not done)
  //4) Finish the connections already established but not completed by the fluid flops. (done)
  //5) This should complete passthrough with assumption that transactions are completed in order. (bad assumption, have to remember requests)
  //6) Enable a system to remember l2id and nid based on drid.(not done, main priority)
  
  //Note: I am implementing the FFlops a little wrong. They really should be the final outputs with no logic or operations attached
  //to the output as it exits the module. Therefore, I should change my signals to have operations performed then fed into the FFlops
  //rather than the other way around which it is now.
  
  //The main Question: Will this run? I think yes but poorly since the passthrough does not remember node IDs or L2 request IDs and does 
  //not generate DR IDs
  

  
 
 //Explanation of when to remember identifications:
 //1) The main time we have to remember is during an L2 request. This will include an NID and an L2ID. We need to request a DRID and store
 //   the values in the fast SRAM. The DRID is then passed to main memory. Main memory will send an ack using the DRID. We want to ack back
 //   to the L2 using NID and L2ID, so we locate these values using the DRID. At this point, the DRID can be released to be used by another request.
 //2) The other case where we might want to store an NID and an L2ID is when an L2 performs a displacement. A DRID alocation is not needed here because
 //   main memory will not ack on a write back. In the passthrough case, we can immediately ack back to the L2 when main memory takes in the write back
 //   using the NID and L2ID is gave us for the request. Two ways to implement this is to assign a DRID and store the information. However, it probably
 //   only required a fflop because the writebacks will be in order.

`endif
endmodule
