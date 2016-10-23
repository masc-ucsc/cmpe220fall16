

`define RISCV_ASIDLEN  8

// IC fetch width 1,2,4,8 instructions (*4 for bytes, *32 for bits)
`define IC_BITWIDTH (8*32)

// DC max number of oustanding requests
`define L1_REQIDBITS  5
`define L1_REQIDS    (1<<`L1_REQIDBITS)

// CORE ID
`define CORE_REQIDBITS  6
`define CORE_REQIDS     (1<<`CORE_REQIDBITS)

// L2 ID
`define L2_REQIDBITS  6
`define L2_REQIDS     (1<<`L2_REQIDBITS)

// Node ID (needed for directory). Max num of L2s and TLBs in the system (even
// L2s, Odd TLB)
`define SC_NODEIDBITS 5
`define SC_NODEIDS  (1<<`SC_NODEIDBITS)

// IC ID
`define IC_REQIDBITS  3
`define IC_REQIDS     (1<<`IC_REQBITS)

// DR
`define DR_REQIDBITS  6
`define DR_REQIDS     (1<<`DR_REQBITS)

// max number of checkpoints
`define DC_CKPBITS     4
`define DC_CKPS        (1<<`DC_CKPS)

// ROBID
`define SC_ROBIDBITS   9

// Physical address bits (less than 64)
// paddr: Physical address
// laddr: Logical Address
// claddr: Logical cache aligned address (lower bits not used -> 0)

// TLB
`define TLB_HPADDRBITS 9 // hash PADDR used by DCTLB
`define TLB_REQIDBITS  2
`define TLB_REQIDS     (1<<`TLB_REQBITS)

`define SC_PADDRBITS   50
// SV39 from RISCV (bits 39 to 63 musts be equal to bit 38)
`define SC_LADDRBITS   39
`define SC_PPADDRBITS   3 // predicted lower paddr bits [n:12]
`define SC_IMMBITS     12

`define SC_PCSIGNBITS  13

// RISC CSR register for address base translation (also threadid). Hart in
// RISCV (
`define SC_ASID          0
`define SC_SBPTRBITS     38

`define SC_LINEBITS   512
`define SC_LINEBYTES (`SC_LINEBITS/8)

// Command request L1 -> L2
`define SC_CMDBITS     3

`define SC_PAGESIZEBITS    2
`define SC_PAGESIZE_4KB    2'b00
`define SC_PAGESIZE_2MB    2'b01
`define SC_PAGESIZE_4MB    2'b10
`define SC_PAGESIZE_4GB    2'b11

`define SC_DCTLB_INDEXBITS 5
`define SC_DCTLB_ENTRIES    (1<<(`SC_DCTLB_INDEXBITS))


`define SC_L2TLB_FASTINDEXBITS 4 // Any size, FLOPS just recently used pages

`define SC_L2TLB_4KINDEXBITS 10 // just 4KB page size (SP 2 clk tables, 4way assoc)
`define SC_L2TLB_2MINDEXBITS 6  // 2M/4M page size (SP 2 clk tables, 4Way Assoc)
`define SC_L2TLB_4GINDEXBITS 3  // 4G page size (Flops, FA)
`define SC_L2TLB_FASTENTRIES  (1<<(`SC_L2TLB_FASTINDEXBITS))
`define SC_L2TLB_4KENTRIES    (1<<(`SC_L2TLB_4KINDEXBITS))
`define SC_L2TLB_2MENTRIES    (1<<(`SC_L2TLB_2MINDEXBITS))
`define SC_L2TLB_4GENTRIES    (1<<(`SC_L2TLB_4GINDEXBITS))

`define PF_STATBITS        7
`define PF_DELTABITS       5
`define PF_WEIGTHBITS      4
`define PF_REQIDBITS       5

// VALID CONFIGURATION OPTIONS (2 or 4 pipes)
`define SC_4PIPE 1 // 1..4 pipes

//-------------------
// Prefetching Parameters

`define PF_PE_L1_MAXDEGREE  4
`define PF_PE_L2_MAXDEGREE 16

`define TB_PMA_IO0_START 49'h0_2000_0000_0000
`define TB_PMA_IO0_END   49'h0_3000_0000_0000
`define TB_PMA_IO1_START 49'h0_2000_0000_0000
`define TB_PMA_IO1_END   49'h0_3000_0000_0000

// cacheable regions
`define TB_PMA_C0_START  49'h0_0000_0000_0000
`define TB_PMA_C0_END    49'h0_1000_0000_0000
`define TB_PMA_C1_START  49'h0_4000_0000_0000
`define TB_PMA_C1_END    49'h0_5000_0000_0000
`define TB_PMA_C2_START  49'h0_ffff_ffff_ffff
`define TB_PMA_C2_END    49'h3_ffff_ffff_ffff

// uncacheable regions
`define TB_PMA_U0_START  49'h0_3000_0000_0000
`define TB_PMA_U0_END    49'h0_4000_0000_0000

