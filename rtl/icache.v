
`include "scmem.vh"

// 
// Icache (IC for short)
//
// 16 or 32KB cache
// DM or 4 way assoc cache
// Cache coherent with the L2 cache
//
// Banked IL1 cache In a 4inst IC, each bank has 16bytes width with 2 banks.
// In a 16 instruction fetch, we just need one bank (64bytes wide).
//
// 4 or 16 instruction fetch (4 or 8 way core)


module icache(
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
   input                           clk
  ,input                           reset

  //---------------------------
  // core interface
  ,input                           coretoic_pc_valid
  ,output                          coretoic_pc_retry
  ,input  I_coretoic_pc_type       coretoic_pc // Bit 0 is always zero

  ,output                          ictocore_valid
  ,input                           ictocore_retry
  ,output I_ictocore_type          ictocore

  //---------------------------
  // TLB interface
  ,input                           l1tlbtol1_fwd_valid
  ,output                          l1tlbtol1_fwd_retry
  ,input  I_l1tlbtol1_fwd_type     l1tlbtol1_fwd

  // Notify the L1 that the index of the TLB is gone
  ,input                           l1tlbtol1_cmd_valid
  ,output                          l1tlbtol1_cmd_retry
  ,input  I_l1tlbtol1_cmd_type     l1tlbtol1_cmd

  //---------------------------
  // core Prefetch interface
  ,output PF_cache_stats_type      cachetopf_stats

  //---------------------------
  // L2 interface (same as DC, but no disp/dack)
  ,output                          l1tol2tlb_req_valid
  ,input                           l1tol2tlb_req_retry
  ,output I_l1tol2tlb_req_type     l1tol2tlb_req

  ,output                          l1tol2_req_valid
  ,input                           l1tol2_req_retry
  ,output I_l1tol2_req_type        l1tol2_req

  ,input                           l2tol1_snack_valid
  ,output                          l2tol1_snack_retry
  ,input  I_l2tol1_snack_type      l2tol1_snack

  ,output                          l1tol2_snoop_ack_valid
  ,input                           l1tol2_snoop_ack_retry
  ,output I_l2snoop_ack_type       l1tol2_snoop_ack

  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
);


endmodule

