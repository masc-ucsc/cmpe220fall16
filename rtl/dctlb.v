
// This module is instantiated inside the dcache_pipe
//
// The DCTLB has to track at least 4 SPBTRs at once, but no need to have
// unlimited. This means that just 4 flops translating SBPTR to valid indexes
// are enough. If a new SBPTR checkpoint create arrives, the TLB can
// invalidate all the associated TLB entries (and notify the L1 accordingly)
//

module dctlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  ,input                           l1todctlb_req0_valid
  ,output                          l1todctlb_req0_retry
  ,input  I_l1todctlb_req_type     l1todctlb_req0

  ,input                           l1todctlb_req1_valid
  ,output                          l1todctlb_req1_retry
  ,input  I_l1todctlb_req_type     l1todctlb_req1

  ,output                          dctlbtol1_ack0_valid
  ,input                           dctlbtol1_ack0_retry
  ,output I_dctlbtol1_ack_type     dctlbtol1_ack0

  ,output                          dctlbtol1_ack0_valid
  ,input                           dctlbtol1_ack0_retry
  ,output I_dctlbtol1_ack_type     dctlbtol1_ack0

  // L1 interface for versions
 
  // Notify TLB when new checkpoints are created/recycled
  ,input                           l1todctlb_cmd_valid
  ,output                          l1todctlb_cmd_retry
  ,input  I_dctlbtol1_cmd_type     l1todctlb_cmd

  // Notify the L1 that the index of the TLB is gone
  ,output                          dctlbtol1_cmd_valid
  ,input                           dctlbtol1_cmd_retry
  ,output I_dctlbtol1_cmd_type     dctlbtol1_cmd

  // Interface with the L2 TLB
  // Just the SNOOPS that have a TLB
  ,input                           l1todctlb_snoop_valid
  ,output                          l1todctlb_snoop_retry
  ,input I_l1todctlb_snoop_type    l1todctlb_snoop

  ,output                          l1tol2_snoop_ack_valid
  ,input                           l1tol2_snoop_ack_retry
  ,output I_l2snoop_ack_type       l1tol2_snoop_ack

  /* verilator lint_on UNUSED */
);

endmodule

