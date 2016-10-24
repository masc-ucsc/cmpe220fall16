
`include "scmem.vh"

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
  /* verilator lint_on UNUSED */
);

endmodule
