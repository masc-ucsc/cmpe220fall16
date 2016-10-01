
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
//

module icache(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // l2cache_pipe interface
  ,output                          l1tol2_req_valid
  ,input                           l1tol2_req_retry
  ,output I_l1tol2_req_type        l1tol2_req

  ,input                           l2tol1_snack_valid
  ,output                          l2tol1_snack_retry
  ,input  I_l2tol1_snack_type      l2tol1_snack

  ,output                          l2tol1_snoop_ack_valid
  ,input                           l2tol1_snoop_ack_retry
  ,output I_l2snoop_ack_type       l2tol1_snoop_ack

  // core interface
  ,input                           coretoic_valid
  ,output                          coretoic_retry
  ,input  SC_laddr_type            coretoic_pc // Bit 0 is always zero

  ,output                          ictocore_valid
  ,input                           ictocore_retry
  ,output I_ictocore_type          ictocore
  /* verilator lint_on UNUSED */
);


endmodule

