`ifndef SCMEMT_H
`define SCMEMT_H

// SCMEM basic types

typedef logic [`SC_LINEBITS-1:0]     SC_line_type;

typedef logic [`SC_CMDBITS-1:0]      SC_cmd_type;   // request command (L1 -> L2, or L2 -> L3 or IC -> L2)
typedef logic [`SC_SCMDBITS-1:0]     SC_snack_type;  // SNOOP and ack (snack) commands
typedef logic [`SC_DCMDBITS-1:0]     SC_dcmd_type;  // displace DC to L2 or L2 to L3

typedef logic [`SC_PADDRBITS-1:0]    SC_paddr_type;
typedef logic [`SC_LADDRBITS-1:0]    SC_laddr_type;
typedef logic [`SC_SBPTRBITS-1:0]    SC_sptbr_type; // Thread ID for TLB or uTLB
typedef logic [`SC_PAGESIZEBITS-1:0] SC_pagesize_type;
typedef logic [`SC_PCSIGNBITS-1:0]   SC_pcsign_type;

typedef logic [`SC_ABORTBITS-1:0]    SC_abort_type;

typedef logic [`DR_REQIDBITS-1:0]    DR_reqid_type;

typedef logic [`SC_ROBIDBITS-1:0]    SC_robid_type;

typedef logic [`SC_DCTLB_INDEXBITS-1:0] SC_dctlb_idx_type;

// RISCV sv39 supported (not sv48 for the moment)

typedef struct packed {
  logic   global;    // RISCV page shared accross tid
  logic   a; // access
  logic   d; // dirty
  logic   sw; // Supervisor Write
  logic   sr;
  logic   sx;
  logic   uw; // User write permission
  logic   ur;
  logic   ux;
  logic   cacheable;
  logic   dev; // IO/dev must be non-cacheable and strongly ordered
  SC_pagesize_type pagesize;
} SC_l2tlbe_type;

typedef struct packed {
  logic   global;    // RISCV page shared accross tid
  logic   a; // access
  logic   d; // dirty
  logic   sw;  // Supervisor Write
  logic   sr;
  logic   sx;
  logic   uw; // User write permission
  logic   ur;
  logic   ux;
  logic   cacheable;
  logic   dev; // IO/dev must be non-cacheable and strongly ordered
  SC_pagesize_type pagesize;
} SC_dctlbe_type;

typedef logic [`SC_LINEBYTES-1:0]    SC_disp_mask_type;

typedef logic [`IC_BITWIDTH-1:0]     IC_fwidth_type;

typedef logic [`L1_REQIDBITS-1:0]    L1_reqid_type;
typedef logic [`DC_CKPBITS-1:0]      DC_ckpid_type;

typedef logic [`CORE_REQIDBITS-1:0]  CORE_reqid_type;
typedef logic [`CORE_MOPBITS-1:0]    CORE_mop_type;
typedef logic [`CORE_LOPBITS-1:0]    CORE_lop_type;

typedef logic [`PF_DELTABITS-1:0]    PF_delta_type;
typedef logic [`PF_WEIGTHBITS-1:0]   PF_weigth_type;
typedef logic [`PF_REQIDBITS-1:0]    PF_reqid_type;
typedef logic                        PF_mega_type;

typedef logic [`PF_ACKBITS-1:0]      PF_ack_type;
typedef struct packed {
  // Normalized stats. If all the values are over 1. Decrease al the
  // entries by 1. Do not let the values overflow (saturated add).
  logic [`PF_STATBITS-1:0]  nhitmissd;
  logic [`PF_STATBITS-1:0]  nhitmissp;
  logic [`PF_STATBITS-1:0]  nhithit;
  logic [`PF_STATBITS-1:0]  nmiss;
  logic [`PF_STATBITS-1:0]  ndrop;
  logic [`PF_STATBITS-1:0]  nreqs; // LD for L1
  logic [`PF_STATBITS-1:0]  nsnoops;
  logic [`PF_STATBITS-1:0]  ndisp; // ST for L1
} PF_cache_stats_type;

typedef logic [`L2_REQIDBITS-1:0]    L2_reqid_type;

// L2 or L2TLB id (L2TLB is odd, L2 is even. E.g: L2=0,2,4... L2TLB=1,3,5...)
// when talking between L2 and DR
typedef logic [`SC_NODEIDBITS-1:0]   SC_nodeid_type; 

`endif
