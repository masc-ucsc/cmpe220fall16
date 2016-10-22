
// This module is instantiated inside the l2cache
//
// The DCTLB has to track at least 4 SPBTRs at once, but no need to have
// unlimited. This means that just 4 flops translating SBPTR to valid indexes
// are enough. If a new SBPTR checkpoint create arrives, the TLB can
// invalidate all the associated TLB entries (and notify the L1 accordingly)
//

module l2tlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // L2TLB listens the same L1 request (but no ack). Response sent to L2
  ,input                           l1tol2_req_valid
  ,output                          l1tol2_req_retry
  ,input  I_l1tol2_req_type        l1tol2_req

  ,output                          l2tlbtol2_fwd_valid
  ,input                           l2tlbtol2_fwd_retry
  ,output I_l2tlbtol2_fwd_type     l2tlbtol2_fwd

  // DCTLB and L2TLB interface
  ,output                          l2tlbtodctlb_snoop_valid
  ,input                           l2tlbtodctlb_snoop_retry
  ,output I_l2tlbtodctlb_snoop_type l2tlbtodctlb_snoop

  ,output                          l2tlbtodctlb_ack_valid
  ,input                           l2tlbtodctlb_ack_retry
  ,output I_l2tlbtodctlb_ack_type  l2tlbtodctlb_ack

  ,input                           dctlbtol2tlb_req_valid
  ,output                          dctlbtol2tlb_req_retry
  ,input  I_dctlbtol2tlb_req_type  dctlbtol2tlb_req

  ,input                           dctlbtol2tlb_sack_valid
  ,output                          dctlbtol2tlb_sack_retry
  ,input  I_dctlbtol2tlb_sack_type dctlbtol2tlb_sack
  
  //---------------------------
  // Directory interface (l2 has to arbitrate between L2 and L2TLB
  // messages based on nodeid. Even nodeid is L2, odd is L2TLB)
  ,output                          l2todr_req_valid
  ,input                           l2todr_req_retry
  ,output I_l2todr_req_type        l2todr_req

  ,input                           drtol2_snack_valid
  ,output                          drtol2_snack_retry
  ,input  I_drtol2_snack_type      drtol2_snack

  ,output                          l2todr_snoop_ack_valid
  ,input                           l2todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       l2todr_snoop_ack

  ,output                          l2todr_disp_valid
  ,input                           l2todr_disp_retry
  ,output I_l2todr_disp_type       l2todr_disp

  ,input                           drtol2_dack_valid
  ,output                          drtol2_dack_retry
  ,input  I_drtol2_dack_type       drtol2_dack
  /* verilator lint_on UNUSED */
);

endmodule

