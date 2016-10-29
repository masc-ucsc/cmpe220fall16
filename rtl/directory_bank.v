
`include "scmem.vh"

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
// The prefetches go to the mem, if they come back (no guarantee), the
// nodeid/address indicates to what core to forward the request. The Ack is
// passed as a ACK_P* to the L2 node
// 
// For replacement use HawkEye or RRIP

/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNOPT */
module directory_bank(
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
  ,input  I_drsnoop_ack_type       l2todr_snoop_ack

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
  
  
  
  //This is the new valid caused by the fork operation on l2todr_req
  logic l2todr_req_fork_valid;
  
  always_comb begin
    l2todr_req_fork_valid = !l2todr_req_retry && l2todr_req_valid;
  end
  
  //This OR is because of a Fork operation on the l2todr request. The Fork consists of a fflop that
  //holds the l2todr request temporarily and an fflop that determines a DRID to be assigned to this request.
  //Also included is drid_valid which is a boolean which indicates if there is an available drid or not
  always_comb begin
    l2todr_req_retry = l2_req_retry | drid_req_retry | ~drid_valid;
  end
  
  
  //The fflop below uses type I_l2todr_pfreq_type as its input and output. While I_drtomem_pfreq_type is basically the same struct,
  //I divided the fflop output and assignment so there would not be any conflicts.
  I_l2todr_pfreq_type        drff_pfreq;
  assign drtomem_pfreq.paddr = drff_pfreq.paddr;
  assign drtomem_pfreq.nid = drff_pfreq.nid;
  
  //fflop for pfreq (prefetch request)
  //currently, only the address of the prefetch is used and passed through to the memory (for pass through test)
  //I do not know what to us the rest of the signals for and am not sure why main memory only has an address input
  //for its prefetch request type. If you know the answer, feel free to comment in my Directory good doc about it.
  
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
  
  //This is a little backwards, I should be changing the input of the fluid flop rather than the output
  I_l2todr_req_type          drff_req;
  assign drtomem_req.paddr = drff_req.paddr;
  assign drtomem_req.cmd =   drff_req.cmd;
  assign drtomem_req.drid =  drid_ack;
  //connections left unused from l2todr_req: nid, l2id.
  //These values should be sent back on the ack, drtol2_snack, but they are currently not.
  //Also, drid should be a value rather than 0 to check the memack value to determine which L2 to return the ack to.
  
  //Signals that connect the DRID and l2request signals to drtomem signals
  logic inp_join_valid;
  logic inp_join_retry;
  
  logic l2todr_req_ff_valid; //v1
  logic l2todr_req_ff_retry; //r1
  
  logic drid_storage_req_valid;   //v3
  logic drid_storage_req_retry;   //r3
  
  logic drid_ack_valid; //v2
  logic drid_ack_retry; //r2
  
  //drtomem_req_valid v4
  //drtomem_req_retry r4
  assign inp_join_valid = drid_ack_valid && l2todr_req_ff_valid;
  assign inp_join_retry = drid_storage_req_retry || drtomem_req_retry;
  assign drtomem_req_valid = inp_join_valid && !(inp_join_retry);
  assign drid_storage_req_valid = drtomem_req_valid;
  assign l2todr_req_ff_retry = inp_join_retry || (!inp_join_valid && l2todr_req_ff_valid);
  assign drid_ack_retry = inp_join_retry || (!inp_join_valid && drid_ack_valid);
  
  //Creating another retry signal because this fflop is the result of a fork of l2todr_req_retry
  //Sorry about poor naming.
  logic l2_req_retry;
  //fflop for l2todr_req (l2 request)
  fflop #(.Size($bits(I_l2todr_req_type))) req_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_req),
    .dinValid (l2todr_req_fork_valid),
    .dinRetry (l2_req_retry),

    .q        (drff_req),
    .qValid   (l2todr_req_ff_valid),
    .qRetry   (l2todr_req_ff_retry)
  );
  
  I_memtodr_ack_type      drff_snack;

  assign drtol2_snack.nid = 5'b0; //These needs to be changed to match the request nid and l2id.
  assign drtol2_snack.l2id = 6'b0;
  
  assign drtol2_snack.drid = 6'b0; //This is not a mistake in this case because the drid is required to be 0 on acks, and we do not snoop in passthrough
  assign drtol2_snack.paddr = 50'b0; //The address is not used during an ack.
  assign drtol2_snack.snack = drff_snack.ack;
  assign drtol2_snack.line = drff_snack.line;
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
    .dinValid (memtodr_ack_valid),
    .dinRetry (memtodr_ack_retry),

    .q        (drff_snack),
    .qValid   (drtol2_snack_valid),
    .qRetry   (drtol2_snack_retry)
  );
  
  I_l2todr_disp_type        drff_wb;

  //Unused signals: nid, l2id, drid, mask, dcmd
  //drid is a special case in passthrough and we should always expect it to be 0 since we are not snooping.
  //Also, I am not sure what mask does.
  //nid and l2id need to be remembered in order to send an ack.
  assign drtomem_wb.line = drff_wb.line;
  assign drtomem_wb.paddr = drff_wb.paddr;
  
  //fflop for memtodr_ack (memory ack request)
  //connections to drtomem_wb not complete. There is an assumption in this passthrough that the acks are returned in order.
  //The directory should also return an ack which is associated with this write back.
  //bit size of fflop is incorrect
  fflop #(.Size($bits(I_l2todr_disp_type))) disp_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_disp),
    .dinValid (l2todr_disp_valid),
    .dinRetry (l2todr_disp_retry),

    .q        (drff_wb),
    .qValid   (drtomem_wb_valid),
    .qRetry   (drtomem_wb_retry)
  );
  
  logic drff_dack_valid;
  logic drff_dack_retry;
  I_drtol2_dack_type drff_dack;
  
  //These should have actual values, but I have not implemented that yet.
  assign drff_dack.nid = 5'b0;
  assign drff_dack.l2id = 6'b0;
  
  //Therefore, I am not making this valid yet.
  assign drff_dack_valid = 1'b0;
  
  //fflop for drtol2_dack (displacement acknowledge)
  fflop #(.Size($bits(I_drtol2_dack_type))) dack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drff_dack),
    .dinValid (drff_dack_valid),
    .dinRetry (drff_dack_retry),

    .q        (drtol2_dack),
    .qValid   (drtol2_dack_valid),
    .qRetry   (drtol2_dack_retry)
  );
  
  
  logic drff_snoop_ack_valid;
  logic drff_snoop_ack_retry;
  I_drsnoop_ack_type drff_snoop_ack;
  
  
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
  

  //Adding some temporary code here
  logic [`DR_REQIDS-1:0] drid_valid_vector;
  logic [`DR_REQIDS-1:0] drid_valid_vector_next;
  
  logic drid_release;
  assign drid_release = 1'b0; //unused for now
  
  logic [`DR_REQIDBITS-1:0] drid_ack_addr; //unused as well
  
  always_comb begin
    drid_valid_vector_next = drid_valid_vector;
    //To avoid a retry issue I would include a check against ~retry but note that the signal
    //drid_req_valid contains l2todr_req_fork_valid which contains a !retry, so adding it here
    //would be redundant. Could probably add for clarity and hope it gets taken out when optimized.
    
    if(drid_req_valid) begin
        drid_valid_vector_next[drid_valid_encoder] = 1'b0;
    end
    
    if(drid_release) begin
      drid_valid_vector_next[drid_ack_addr] = 1'b1;
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
  assign drid_req_valid = l2todr_req_fork_valid;
  
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

   ,.req_valid   (drid_storage_req_valid)
   ,.req_retry   (drid_storage_req_retry)
   ,.req_we      (drid_storage_req_valid) //basically, there are no read right now. temporary
   ,.req_pos     (drid_ack)
   ,.req_data    ({drff_req.nid,drff_req.l2id})

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
 
 //Explanation of when to remember identifications:
 //1) The main time we have to remember is during an L2 request. This will include an NID and an L2ID. We need to request a DRID and store
 //   the values in the fast SRAM. The DRID is then passed to main memory. Main memory will send an ack using the DRID. We want to ack back
 //   to the L2 using NID and L2ID, so we locate these values using the DRID. At this point, the DRID can be released to be used by another request.
 //2) The other case where we might want to store an NID and an L2ID is when an L2 performs a displacement. A DRID alocation is not needed here because
 //   main memory will not ack on a write back. In the passthrough case, we can immediately ack back to the L2 when main memory takes in the write back
 //   using the NID and L2ID is gave us for the request. Two ways to implement this is to assign a DRID and store the information. However, it probably
 //   only required a fflop because the writebacks will be in order.
  
endmodule

