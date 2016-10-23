
// DCTLB runs parallel to the Dcache. It gets the same requests as the dcache,
// and sends the translation a bit after. It also has a command channel to
// notify for when checkpoints are finishd from the TLB point of view.
//
// The DCTLB has to track at least 4 SPBTRs at once, but no need to have
// unlimited. This means that just 4 flops translating SBPTR to valid indexes
// are enough. If a new SBPTR checkpoint create arrives, the TLB can
// invalidate all the associated TLB entries (and notify the L1 accordingly)
//
//
// The hpaddr is a way to identify a L2TLB entry. It is also a pseudo-hah of
// the paddr. When a L2TLB entry is displaced, the dctlb gets a snoop.
// This means that when a hpaddr gets removed, it has to dissapear from
// the L1 cache

module dctlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // ld core interface
  ,input                           coretodctlb_req0_valid
  ,output                          coretodctlb_req0_retry
  ,input  I_coretodctlb_req_type   coretodctlb_req0

  // st core interface
  ,input                           coretodctlb_req1_valid
  ,output                          coretodctlb_req1_retry
  ,input  I_coretodctlb_req_type   coretodctlb_req1

  // forward ld core interface
  ,output                          dctlbtol1_fwd0_valid
  ,input                           dctlbtol1_fwd0_retry
  ,output I_dctlbtol1_fwd_type     dctlbtol1_fwd0

  // forward st core interface
  ,output                          dctlbtol1_fwd1_valid
  ,input                           dctlbtol1_fwd1_retry
  ,output I_dctlbtol1_fwd_type     dctlbtol1_fwd1

  // Notify the L1 that the index of the TLB is gone
  ,output                          dctlbtol1_cmd_valid
  ,input                           dctlbtol1_cmd_retry
  ,output I_dctlbtol1_cmd_type     dctlbtol1_cmd

  // Interface with the L2 TLB
  ,input                           l2tlbtodctlb_snoop_valid
  ,output                          l2tlbtodctlb_snoop_retry
  ,input I_l2tlbtodctlb_snoop_type l2tlbtodctlb_snoop

  ,input                           l2tlbtodctlb_ack_valid
  ,output                          l2tlbtodctlb_ack_retry
  ,input I_l2tlbtodctlb_ack_type   l2tlbtodctlb_ack

  ,output                          dctlbtol2tlb_req_valid
  ,input                           dctlbtol2tlb_req_retry
  ,output I_dctlbtol2tlb_req_type  dctlbtol2tlb_req

  ,output                          dctlbtol2tlb_sack_valid
  ,input                           dctlbtol2tlb_sack_retry
  ,output I_dctlbtol2tlb_sack_type dctlbtol2tlb_sack

  /* verilator lint_on UNUSED */
);

endmodule

