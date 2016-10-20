
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
// For replacement use HawkEye or RRIP
/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
module directory_bank(
   input                           clk
  ,input                           reset

  // L2s interface
  ,input                           l2todr_pfreq_valid
  ,output                          l2todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2todr_pfreq       // NOTE: pfreq does not have ack if dropped

  ,input                           l2todr_req_valid
  ,output                          l2todr_req_retry
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

  ,output                          l2todr_snoop_ack_valid
  ,input                           l2todr_snoop_ack_retry
  ,output I_drsnoop_ack_type       l2todr_snoop_ack

  // Memory interface
  // If nobody has the data, send request to memory

  ,output                          drtomem_req_valid
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

I_l2todr_req_type        drff_pfreq;
  //assign drtomem_pfreq.paddr = drff_pfreq.paddr;
  
  //fflop for pfreq (prefetch request)
  //currently, only the address of the prefetch is used and passed through to the memory (for pass through test)
  //I do not know what to us the rest of the signals for and am not sure why main memory only has an address input
  //for its prefetch request type. If you know the answer, feel free to comment in my Directory good doc about it.
  /* verilator lint_off WIDTH */
  fflop #(.Size(49)) ff0 (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_pfreq),
    .dinValid (l2todr_pfreq_valid),
    .dinRetry (l2todr_pfreq_retry),

    .q        (drtomem_pfreq),
    .qValid   (drtomem_pfreq_valid),
    .qRetry   (drtomem_pfreq_retry)
  );
  
  //This is a little backwards, I should be changing the input of the fluid flop rather than the output
  I_l2todr_req_type          drff_req;
  assign drtomem_req.paddr = drff_req.paddr;
  assign drtomem_req.cmd =   drff_req.cmd;
  assign drtomem_req.drid =  6'b0;
  //connections left unused from l2todr_req: nid, l2id.
  //These values should be sent back on the ack, drtol2_snack, but they are currently not.
  //Also, drid should be a value rather than 0 to check the memack value to determine which L2 to return the ack to.
  
  //fflop for l2todr_req (l2 request)
  fflop #(.Size(63)) ff1 (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_req),
    .dinValid (l2todr_req_valid),
    .dinRetry (l2todr_req_retry),

    .q        (drff_req),
    .qValid   (drtomem_req_valid),
    .qRetry   (drtomem_req_retry)
  );
  
  I_memtodr_ack_type      drff_snack;

  assign drtol2_snack.nid = 6'b0; //These needs to be changed to match the request nid and l2id.
  assign drtol2_snack.l2id = 6'b0;
  
  assign drtol2_snack.drid = 6'b0; //This is not a mistake in this case because the drid is required to be 0 on acks, and we do not snoop in passthrough
  assign drtol2_snack.paddr = 49'b0; //The address is not used during an ack.
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
  fflop #(.Size(523)) ff2 (
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
  fflop #(.Size(589)) ff3 (
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
  fflop #(.Size(11)) ff4(
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
  
  //This should have an actual value, but I have not implemented that yet.
  assign drff_snoop_ack.drid = 6'b0;

  //Therefore, I am not making this valid yet.
  assign drff_snoop_ack_valid = 1'b0;
  
  //fflop for l2todr_snoop_ack (snoop acknowledge)
  //Right now this is an output, but this is likely a type and it is actually a type.
  //Therefore, I am just going to output nothing relevant on this for now.
  fflop #(.Size(6)) ff5 (
    .clk      (clk),
    .reset    (reset),

    .din      (drff_snoop_ack),
    .dinValid (drff_snoop_ack_valid),
    .dinRetry (drff_snoop_ack_retry),

    .q        (l2todr_snoop_ack),
    .qValid   (l2todr_snoop_ack_valid),
    .qRetry   (l2todr_snoop_ack_retry)
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

endmodule

