
`include "scmem.vh"

// This is a small TLB that supports some subset of pages from the L2. It is
// not coherent like the l2tlb. Instead it relies in TLBI messages triggered
// from the l2tlb

// dctlb supports 4KB pages. Pages larger are translated to multiple 4KB page
// entries. The TLB2M/TLB4M/TLB1G invalidates can invalidate many entries
//
// The dctlb is a direct mapped TLB translation that uses bits starting 12
// (4KB page) but using a hash over all the virtual bits to decrease conflicts
//
// ENTRY: ~14bytes (SRAM indexed by VPN) (64 enties ~1KB of 2 way table)
//   SPTRBR
//   VPN
//   PPN
//   perm
module dctlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset
  /* verilator lint_on UNUSED */
);

endmodule

