
`include "scmem.vh"
`define DR_PASSTHROUGH

//`define TEST_OLD
`define TEST_NEW

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
  
  //Creating this temporary area to test a new way to manage requests
`ifdef TEST_NEW

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
      //prefetch 
      drtol2_snack_next.nid = memtodr_ack_ff.nid; 
      drtol2_snack_next.l2id = {`L2_REQIDBITS{1'b0}};
	    drtol2_snack_next.hpaddr_base = compute_dr_hpaddr_base(memtodr_ack_ff.paddr);
	    drtol2_snack_next.hpaddr_hash = compute_dr_hpaddr_hash(memtodr_ack_ff.paddr);
      drtol2_snack_next.paddr = memtodr_ack_ff.paddr;
      
      drtol2_snack_next_valid = memtodr_ack_ff_valid; 
      memtodr_ack_ff_retry = drtol2_snack_next_retry;
      id_ram_retry = 1'b1;
    end else begin
      //If the DRID is valid then ignore the prefetch terms and nid, l2id are set by the RAM
      drtol2_snack_next.nid = id_ram_data[10:6]; //These needs to be changed to match the request nid and l2id.
      drtol2_snack_next.l2id = id_ram_data[5:0];
	    drtol2_snack_next.hpaddr_base = 'b0;
	    drtol2_snack_next.hpaddr_hash = 'b0;
      drtol2_snack_next.paddr = 'b0;
      
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
`endif

`ifdef TEST_OLD
  //This valid is a combination of the input l2todr request valid as well as dependcies in the DR which need to be met
  //in order for the operation to begin. For now, this includes the allocation of a DRID to the request. If there are no
  //available DRIDs then this valid is driven LOW and the retry is driven HIGH.
  logic l2todr_req_drid_valid;
  
  always_comb begin
    l2todr_req_drid_valid = !l2todr_req_retry && l2todr_req_valid;
  end
  
  //This OR forces the retry HIGH when a dependency of the l2todr request is not met. These include: a fflop which holds
  //the output to main memory(l2_req_retry), a fflop which holds the next available DRID(drid_req_retry), and a priority encoder which determines if there
  //are available DRIDs left(drid_valid). This solution may change because I might change the DRID fflop to a flop.
  always_comb begin
    l2todr_req_retry = l2_req_retry | drid_req_retry | ~drid_valid;
  end
  
  //Signals that connect the DRID and l2request signals to drtomem signals
  logic inp_join_valid;
  logic inp_join_retry;
  
  logic l2todr_req_ff_valid; //v1
  logic l2todr_req_ff_retry; //r1
  
  logic drid_storage_req_valid;   //v3
  logic drid_storage_req_retry;   //r3
  assign drid_storage_req_retry = arb_drid_write_retry;
  
  logic drid_ack_valid; //v2
  logic drid_ack_retry; //r2
  
  //drtomem_req_valid v4
  //drtomem_req_retry r4
  
  //This fat stack of assigns performs a join and fork operation.
  //The join operands are: the fflop that holds the next drid and the fflop that holds the l2todr request
  //The fork source is the output of the join. The output of the fork is the RAM that holds NIDs and L2IDs
  //and the drtomem request module output. 
  //Not sure if it is okay to perform these operations before an output rather than adding another fflop stage.
  //Note: I wrote this before I had modules for fork and join. I plan to replace this block with the module sometime...
  
  assign inp_join_valid = drid_ack_valid && l2todr_req_ff_valid;
  assign inp_join_retry = drid_storage_req_retry || drtomem_req_retry;
  assign drtomem_req_valid = inp_join_valid && !drid_storage_req_retry;
  assign drid_storage_req_valid = inp_join_valid && !drtomem_req_retry;
  assign l2todr_req_ff_retry = inp_join_retry || (!inp_join_valid && l2todr_req_ff_valid);
  assign drid_ack_retry = inp_join_retry || (!inp_join_valid && drid_ack_valid);
  
  //Creating another retry signal because this fflop is the result of a fork of l2todr_req_retry
  //Sorry about poor naming.
  logic l2_req_retry;
  
  //This takes the output of the l2todr request fflop and assigns some of its values to the drtomem request module output.
  //Note: the I_l2todr_req_type contains an NID and L2ID which need to be stored during the request duration for the ack.
  //This module contains a fast RAM module which does that and these values are fed into it.
  I_l2todr_req_type          dr_req_temp;
  assign drtomem_req.paddr = dr_req_temp.paddr;
  assign drtomem_req.cmd =   dr_req_temp.cmd;
  assign drtomem_req.drid =  drid_ack;
  
  //fflop for l2todr_req (l2 request)
  fflop #(.Size($bits(I_l2todr_req_type))) req_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_req),
    .dinValid (l2todr_req_drid_valid),
    .dinRetry (l2_req_retry),

    .q        (dr_req_temp),
    .qValid   (l2todr_req_ff_valid),
    .qRetry   (l2todr_req_ff_retry)
  );
  
  //To be Done: A join operation on the RAM output that holds NIDs and L2IDs and the fflop that holds the memtodr acknowledge.
  //The destination of this join is the drtol2 snack output. The output also gets sent to the DRID valid bit vector to release
  //the DRID, but that is not a fflop and can be done without a fflop.
  //Inputs: drff_snack_valid, drid_storage_ack_valid, drtol2_snack_retry
  //Outputs: drff_snack_retry, drid_storage_ack_retry, drtol2_snack_valid
  
  always_comb begin
    drtol2_snack_valid = drff_snack_valid && drid_storage_ack_valid;
  end
  
  always_comb begin
    drff_snack_retry        = drtol2_snack_retry || (!drtol2_snack_valid && drff_snack_valid);
    drid_storage_ack_retry  = drtol2_snack_retry || (!drtol2_snack_valid && drid_storage_ack_valid);
  end
  
  
  I_memtodr_ack_type      drff_snack;
  logic                   drff_snack_valid;
  logic                   drff_snack_retry;

  assign drtol2_snack.nid = drid_storage[10:6]; //These needs to be changed to match the request nid and l2id.
  assign drtol2_snack.l2id = drid_storage[5:0];
  
  assign drtol2_snack.drid =  {`DR_REQIDBITS{1'b0}}; //This is not a mistake in this case because the drid is required to be 0 on acks, and we do not snoop in passthrough
  assign drtol2_snack.paddr = {`SC_PADDRBITS{1'b0}}; //The address is not used during an ack.
  assign drtol2_snack.snack = drff_snack.ack;
  assign drtol2_snack.line =  drff_snack.line;
  //The memtodr_ack also contains a drid, but this should not be sent to the L2. This value should be used to search from a request table
  //that holds the appropriate nid and l2id and then discarded. The drid sent to the L2 on drtol2_snack only has a value on snoops and is 0 otherwise.
  
  //We are only ACKing in pass through and the paddr is not used as mentioned in the interface file.
  //However, I do not fully understand why it is not used.
  
  //fflop for memtodr_ack (memory to Directory acknowledge)
  //connections to drtol2_snack not complete. There is an assumption in this passthrough that
  //the acks are returned in order.
  //bit size of fflop is incorrect
  
  
  fflop #(.Size($bits(I_memtodr_ack_type))) ack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (memtodr_ack),
    .dinValid (dest_memtodr_avalid),
    .dinRetry (dest_memtodr_aretry),

    .q        (drff_snack),
    .qValid   (drff_snack_valid),
    .qRetry   (drff_snack_retry)
  );
  
  logic dest_memtodr_avalid;
  logic dest_memtodr_aretry;
  
  logic dest_memtodr_bvalid;

  always_comb begin
    memtodr_ack_retry = dest_memtodr_aretry || arb_drid_read_retry;
  end

  always_comb begin
    dest_memtodr_avalid = memtodr_ack_valid && !arb_drid_read_retry;
  end
  
  //I had to move this to a separate always block or I get a "Circular Logic warning".
  //The warning is not accurate, but I just want to get rid of it.
  always_comb begin
    dest_memtodr_bvalid = memtodr_ack_valid && !dest_memtodr_aretry;
  end
  
  
  
  //state and next state signals
  logic arb_drid_sram;
  logic arb_drid_sram_next;
  //outputs from arbiter
  logic arb_drid_read_retry;
  logic arb_drid_write_retry;
  logic arb_drid_sram_valid;
  logic arb_drid_sram_we;
  logic [`DR_REQIDBITS-1:0] drid_ram_pos_next;
  
  //required inputs, where ever they maybe
  logic arb_drid_read_valid;
  logic arb_drid_write_valid;
  logic arb_drid_sram_retry;
  
  assign arb_drid_read_valid = dest_memtodr_bvalid;
  assign arb_drid_write_valid = drid_storage_req_valid;
  //The below code is an arbiter that decides who will be writing or reading from the DRID sram (which actually stores l2id and nid)
  //This was not done with typical state machine code because I would create a separate module for that but am not sure if we are
  //allowed to clutter the rtl folder with misc modules. So it will sit here for now.
  //This arbiter has two states: read preferred and write preferred, so being in that state will prefer that action and transition 
  //to the other state after the action is performed. However, a read or a write can happen in either state. 
  
  localparam ARBITER_READ_PREFERRED_STATE = 1'b0;
  localparam ARBITER_WRITE_PREFERRED_STATE = 1'b1;
  
  //I had to separate the write enable signal into a different always block or else a warning will occur claiming circular logic. This warning appears to be a glitch
  //and should not affect simulation, but I removed it anyway.
  always_comb begin
    arb_drid_sram_we = 1'b0;
    if(arb_drid_sram == ARBITER_READ_PREFERRED_STATE) begin    
      if(arb_drid_write_valid && !arb_drid_read_valid) begin
        arb_drid_sram_we = 1'b1;
      end
      
    end else begin //state == ARBITER_WRITE_PREFERRED_STATE
      if(arb_drid_write_valid) begin
        arb_drid_sram_we = 1'b1;
      end 
      
    end
  end
  
  //This always blocks performs the next state logic for the DRID RAM READ/WRITE arbiter FSM. It also contains some output logic
  //for the FSM but not all of it. The write enable had to be moved outside the always blocks because it caused warnings to occur
  //when they were in the same always block.
  
  always_comb begin
    //default next state is the current state
    arb_drid_sram_next = arb_drid_sram;
    
    //default retry on read or writes is the retry coming from the SRAM, however this will fail in some cases. For example,
    //if retry from SRAM is high and both valids from retry are high then the operation that occurs after the retry falls LOW
    //depends on which state we are in. If the SRAM retry falls low, then the fflops think that their valid goes through, but
    //this will not occur since the state machine only allows one operations to happen. Basically, I solve this by extending
    //the retry during a state transition. Difficult to say if this work 100%, but my notes imply this will work.
    arb_drid_read_retry = arb_drid_sram_retry;
    arb_drid_write_retry = arb_drid_sram_retry;
    
    //default drid to index RAM is the value used for writing to the RAM
    drid_ram_pos_next = drid_ack;
    
    arb_drid_sram_valid = 1'b0;
    
    if(arb_drid_sram == ARBITER_READ_PREFERRED_STATE) begin
      //next state logic
      if(arb_drid_read_valid && !arb_drid_sram_retry) begin
        arb_drid_sram_next = ARBITER_WRITE_PREFERRED_STATE;
      end
      
      //output logic
      if(arb_drid_read_valid) begin
        arb_drid_sram_valid = 1'b1;      
        arb_drid_write_retry = 1'b1; 
        drid_ram_pos_next = memtodr_ack.drid;
      end else if(arb_drid_write_valid) begin
        arb_drid_sram_valid = 1'b1;
      end
      
    end else begin //state == ARBITER_WRITE_PREFERRED_STATE
    
      if(arb_drid_write_valid && !arb_drid_sram_retry) begin
        arb_drid_sram_next = ARBITER_READ_PREFERRED_STATE;
      end
      
      if(arb_drid_write_valid) begin
        arb_drid_sram_valid = 1'b1;
        arb_drid_read_retry = 1'b1;
      end else if(arb_drid_read_valid) begin
        arb_drid_sram_valid = 1'b1;
        drid_ram_pos_next = memtodr_ack.drid;
      end
      
    end
  end
  
  flop #(.Bits(1)) sram_arbiter_state_flop (
    .clk      (clk)
   ,.reset    (reset)
   ,.d      (arb_drid_sram_next)
   ,.q        (arb_drid_sram)
  );
  
  //Adding some temporary code here
  logic [`DR_REQIDS-1:0] drid_valid_vector;
  logic [`DR_REQIDS-1:0] drid_valid_vector_next;
  
  logic drid_release;
  assign drid_release = drtol2_snack_valid && !drtol2_snack_retry; //unused for now
  
  
  always_comb begin
    drid_valid_vector_next = drid_valid_vector;
    //To avoid a retry issue I would include a check against ~retry but note that the signal
    //drid_req_valid contains l2todr_req_drid_valid which contains a !retry, so adding it here
    //would be redundant. Could probably add for clarity and hope it gets taken out when optimized.
    
    if(drid_req_valid) begin
        drid_valid_vector_next[drid_valid_encoder] = 1'b0;
    end
    
    if(drid_release) begin
      drid_valid_vector_next[drff_snack.drid] = 1'b1;
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
  
  //The naming scheme is as follows: the req is a request for a DRID and the ack is an acknowledgement returning a drid
  logic [`DR_REQIDBITS-1:0] drid_ack;
  logic drid_req_valid;
  logic drid_req_retry;

  
  //Note this is not the final valid.
  assign drid_req_valid = l2todr_req_drid_valid;
  
  //this fflop holds the drid that will be sent to main memory on a drtomem request
  //The drid_req input refers to the next drid that will be assigned. This value from the Priority encoder
  //which selects a valid DRID based on a valid vector.
  //The valid signal comes from an AND of the Priority Encoder valid and the valid from the memory request.
  //Optimization: I could probably use a shared fluid flop for this and the l2todr request which would simplify
  //the handshake immensely.
  fflop #(.Size(`DR_REQIDBITS)) drid_fflop (
    .clk      (clk),
    .reset    (reset),

    .din      (drid_valid_encoder),
    .dinValid (drid_req_valid),
    .dinRetry (drid_req_retry),

    .q        (drid_ack),
    .qValid   (drid_ack_valid),
    .qRetry   (drid_ack_retry)
  );
  
  //Storage unused for now.
  logic [10:0] drid_storage;
  logic drid_storage_ack_valid;
  logic drid_storage_ack_retry;
  
  
  
  ram_1port_fast 
   #(.Width(11), .Size(`DR_REQIDS), .Forward(1))
  ram_drid_storage ( 
    .clk         (clk)
   ,.reset       (reset)

   ,.req_valid   (arb_drid_sram_valid)
   ,.req_retry   (arb_drid_sram_retry)
   ,.req_we      (arb_drid_sram_we) 
   ,.req_pos     (drid_ram_pos_next)
   ,.req_data    ({dr_req_temp.nid,dr_req_temp.l2id})

   ,.ack_valid   (drid_storage_ack_valid)
   ,.ack_retry   (drid_storage_ack_retry)
   ,.ack_data    (drid_storage)
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
`endif 
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
