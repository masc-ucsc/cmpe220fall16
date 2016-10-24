
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
  ,input                           coretodctlb_ld_valid
  ,output                          coretodctlb_ld_retry
  ,input  I_coretodctlb_ld_type    coretodctlb_ld

  // st core interface
  ,input                           coretodctlb_st_valid
  ,output                          coretodctlb_st_retry
  ,input  I_coretodctlb_st_type    coretodctlb_st

  // prefetch request (uses the st/ld fwd port opportunistically)
  ,input                           pfetol1tlb_req_valid
  ,output                          pfetol1tlb_req_retry
  ,input  I_pfetol1tlb_req_type    pfetol1tlb_req

  // forward ld core interface
  ,output                          l1tlbtol1_fwd0_valid
  ,input                           l1tlbtol1_fwd0_retry
  ,output I_l1tlbtol1_fwd_type     l1tlbtol1_fwd0

  // forward st core interface
  ,output                          l1tlbtol1_fwd1_valid
  ,input                           l1tlbtol1_fwd1_retry
  ,output I_l1tlbtol1_fwd_type     l1tlbtol1_fwd1

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

