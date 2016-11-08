
`include "scmem.vh"
`define L1IT_PASSTHROUGH

module ictlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // core interface
  ,input                           coretoictlb_pc_valid
  ,output                          coretoictlb_pc_retry
  ,input  I_coretoictlb_pc_type    coretoictlb_pc

  // prefetch request (uses the fwd port opportunistically)
  ,input                           pfetol1tlb_req_valid
  ,output                          pfetol1tlb_req_retry
  ,input  I_pfetol1tlb_req_type    pfetol1tlb_req

  // forward st core interface
  ,output                          l1tlbtol1_fwd_valid
  ,input                           l1tlbtol1_fwd_retry
  ,output I_l1tlbtol1_fwd_type     l1tlbtol1_fwd

  // Notify the L1 that the index of the TLB is gone
  /* verilator lint_off UNDRIVEN */
  ,output                          l1tlbtol1_cmd_valid
  ,input                           l1tlbtol1_cmd_retry
  ,output I_l1tlbtol1_cmd_type     l1tlbtol1_cmd

  // Interface with the L2 TLB
  ,input                           l2tlbtol1tlb_snoop_valid
  ,output                          l2tlbtol1tlb_snoop_retry
  ,input I_l2tlbtol1tlb_snoop_type l2tlbtol1tlb_snoop

  ,input                           l2tlbtol1tlb_ack_valid
  ,output                          l2tlbtol1tlb_ack_retry
  ,input I_l2tlbtol1tlb_ack_type   l2tlbtol1tlb_ack

  ,output                          l1tlbtol2tlb_req_valid
  ,input                           l1tlbtol2tlb_req_retry
  ,output I_l1tlbtol2tlb_req_type  l1tlbtol2tlb_req

  ,output                          l1tlbtol2tlb_sack_valid
  ,input                           l1tlbtol2tlb_sack_retry
  ,output I_l1tlbtol2tlb_sack_type l1tlbtol2tlb_sack
  /* verilator lint_on UNDRIVEN */
  /* verilator lint_on UNUSED */
);

`ifdef L1IT_PASSTHROUGH

  assign l1tlbtol1_cmd_valid     = 1'b0;
  assign l1tlbtol2tlb_req_valid  = 1'b0;
  assign l1tlbtol2tlb_sack_valid = 1'b0;


  // LOAD REQUESTS to FWD PORT

  I_l1tlbtol1_fwd_type l1tlbtol1_fwd_next;
  logic l1tlbtol1_fwd_retry_next, l1tlbtol1_fwd_valid_next;

  always_comb begin
    if(coretoictlb_pc_valid) begin
      l1tlbtol1_fwd_next.coreid = coretoictlb_pc.coreid;
      l1tlbtol1_fwd_next.prefetch = 1'b0;
      l1tlbtol1_fwd_next.l2_prefetch = 1'b0;
      l1tlbtol1_fwd_next.fault = 3'b000; 
      l1tlbtol1_fwd_next.hpaddr = coretoictlb_pc.laddr[22:12];
      l1tlbtol1_fwd_next.ppaddr = coretoictlb_pc.laddr[14:12];

      l1tlbtol1_fwd_valid_next = coretoictlb_pc_valid;
      coretoictlb_pc_retry = l1tlbtol1_fwd_retry_next;
      pfetol1tlb_req_retry = 1'b0;

    end else if(~pfetol1tlb_req.l2) begin
      l1tlbtol1_fwd_next.coreid = 'b0;
      l1tlbtol1_fwd_next.prefetch = 1'b1;
      l1tlbtol1_fwd_next.l2_prefetch = 1'b1;
      l1tlbtol1_fwd_next.fault = 3'b000;
      l1tlbtol1_fwd_next.hpaddr = pfetol1tlb_req.laddr[22:12];
      l1tlbtol1_fwd_next.ppaddr = pfetol1tlb_req.laddr[14:12];

      l1tlbtol1_fwd_valid_next = pfetol1tlb_req_valid;
      pfetol1tlb_req_retry = l1tlbtol1_fwd_retry_next & pfetol1tlb_req_valid;
      coretoictlb_pc_retry = 1'b0;
    end else begin
      l1tlbtol1_fwd_valid_next = 1'b0;
    end
  end


  fflop #(.Size($bits(I_l1tlbtol1_fwd_type))) ld_req_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l1tlbtol1_fwd_valid_next)
   ,.dinRetry(l1tlbtol1_fwd_retry_next)
   ,.din(l1tlbtol1_fwd_next)
   
   ,.qValid(l1tlbtol1_fwd_valid)
   ,.qRetry(l1tlbtol1_fwd_retry)
   ,.q(l1tlbtol1_fwd)
   );

`endif
endmodule
