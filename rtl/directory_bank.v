
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
  ,input  I_l2todr_req_type        l2todr_pfreq       // NOTE: pfreq does not have ack if dropped

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
  assign drtomem_pfreq.paddr = drff_pfreq.paddr;
  
  //fflop for pfreq (prefetch request)
  //currently, only the address of the prefetch is used and passed through to the memory (for pass through test)
  //I do not know what to us the rest of the signals for and am not sure why main memory only has an address input
  //for its prefetch request type. If you know the answer, feel free to comment in my Directory good doc about it.
  /* verilator lint_off WIDTH */
  fflop #(.Size(63)) ff0 (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_pfreq),
    .dinValid (l2todr_pfreq_valid),
    .dinRetry (l2todr_pfreq_retry),

    .q        (drff_pfreq),
    .qValid   (drtomem_pfreq_valid),
    .qRetry   (drtomem_pfreq_retry)
  );
  
  I_l2todr_req_type        drff_req;
  assign drtomem_req.paddr = drff_req.paddr;
  assign drtomem_req.cmd = drff_req.cmd;
  assign drtomem_req.drid = 6'b0;
   
  
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

endmodule

