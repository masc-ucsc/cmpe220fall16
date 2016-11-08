`ifndef SCMEMI_H
`define SCMEMI_H

`include "scmemp.vh"
`include "scmemc.vh"
`include "scmemt.vh"

// {{{1 l1tol2_req
typedef struct packed {
  L1_reqid_type     l1id;
  SC_cmd_type       cmd;

  SC_pcsign_type    pcsign;
  SC_poffset_type   poffset;  // L1 does only 4KB pages, This is the page offset needed to compute the paddr using the hpaddr
  // The paddr comes from the *l2tlb_fwd
  SC_ppaddr_type    ppaddr; // predicted PADDR
} I_l1tol2_req_type;
// 1}}}

// {{{1 l1tol2tlb_req (req|disp use this)
typedef struct packed {
  L1_reqid_type     l1id;

  logic             prefetch; // prefetch, ignore l1id

  TLB_hpaddr_type   hpaddr; // hash paddr (only one hash cached at L1)
} I_l1tol2tlb_req_type;
// 1}}}

// {{{1 l2tol1_snack
typedef struct packed {
  L1_reqid_type     l1id;  // !=0 ACK, == 0 snoop
  L2_reqid_type     l2id;  // ==0 ACK, != 0 snoop

  SC_snack_type     snack; // Snoop or ACK
  SC_line_type      line;

  SC_poffset_type   poffset;
  TLB_hpaddr_type   hpaddr;
} I_l2tol1_snack_type;
// 1}}}

// {{{1 l2tlbtol1tlb_snoop
typedef struct packed {
  TLB_reqid_type    rid;
  TLB_hpaddr_type   hpaddr;
} I_l2tlbtol1tlb_snoop_type;
// 1}}}

// {{{1 l2tlbtol1tlb_ack
typedef struct packed {
  TLB_reqid_type    rid;
  TLB_hpaddr_type   hpaddr; // hash paddr
  SC_ppaddr_type    ppaddr; // predicted PADDR

  SC_dctlbe_type    dctlbe; // ack
} I_l2tlbtol1tlb_ack_type;
// 1}}}

// {{{1 l1tlbtol2tlb_req
typedef struct packed {
  TLB_reqid_type    rid;

  logic             disp_req; // True of disp from dcTLB (A/D bits)
  logic             disp_A;
  logic             disp_D;
  TLB_hpaddr_type   disp_hpaddr; // hash paddr

  SC_laddr_type     laddr; // Not during disp, just req
  SC_sptbr_type     sptbr; // Not during disp, just req

} I_l1tlbtol2tlb_req_type;
// 1}}}

// {{{1 l1tlbtol2tlb_sack
typedef struct packed {
  TLB_reqid_type    rid;
} I_l1tlbtol2tlb_sack_type;
// 1}}}

// {{{1 coretodcl1tb_ld
typedef struct packed {
  DC_ckpid_type     ckpid;

  CORE_reqid_type   coreid;

  CORE_lop_type     lop;
  logic             pnr; // core knows it is non-cacheable, perform anyway

  SC_laddr_type     laddr;
  SC_imm_type       imm;   // address is laddr+imm
  SC_sptbr_type     sptbr;
  logic             user; // user mode or supervisor mode
} I_coretodctlb_ld_type;
// 1}}}

// {{{1 coretoic_pc
typedef struct packed {
  CORE_reqid_type   coreid;

  SC_poffset_type   poffset;
} I_coretoic_pc_type;
// 1}}}

// {{{1 coretoictlb_pc
typedef struct packed {
  CORE_reqid_type   coreid;

  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
} I_coretoictlb_pc_type;
// 1}}}

// {{{1 coretodcl1tb_st
typedef struct packed {
  DC_ckpid_type     ckpid;

  CORE_reqid_type   coreid;

  CORE_mop_type     mop;
  logic             pnr; // core knows it is non-cacheable, perform anyway

  SC_laddr_type     laddr;
  SC_imm_type       imm;   // address is laddr+imm
  SC_sptbr_type     sptbr;
  logic             user; // user mode or supervisor mode
} I_coretodctlb_st_type;
// 1}}}

// {{{1 l1tlbtol1_fwd
typedef struct packed {
  CORE_reqid_type   coreid;
  logic             prefetch; // prefetch, ignore coreid
	logic             l2_prefetch; 

  SC_fault_type     fault;
  TLB_hpaddr_type   hpaddr; // hash paddr (only one hash cached at L1)

  SC_ppaddr_type    ppaddr; // predicted PADDR
} I_l1tlbtol1_fwd_type;
// 1}}}

// {{{1 l1tlbtol1_cmd
typedef struct packed {
  logic             flush;
  TLB_hpaddr_type   hpaddr;
} I_l1tlbtol1_cmd_type;
// 1}}}

// {{{1 l2tlbtol2_fwd
typedef struct packed {
  L1_reqid_type     l1id; 
  logic             prefetch; // prefetch, ignore l1id

  SC_fault_type     fault;
  TLB_hpaddr_type   hpaddr; // hash paddr (only one hash cached at L1)

  SC_paddr_type     paddr; // paddr translation for the laddr in the miss
} I_l2tlbtol2_fwd_type;
// 1}}}

// {{{1 l1tol2_disp 
typedef struct packed {
  L1_reqid_type     l1id;
  L2_reqid_type     l2id; // !=0 means disp as a result of SNOOP (E.g: WB as a result of SCMD_WI)

  SC_disp_mask_type mask;
  SC_dcmd_type      dcmd;

  SC_line_type      line;

  SC_ppaddr_type    ppaddr; // predicted PADDR
} I_l1tol2_disp_type;
// 1}}}

// {{{1 l2tol1_dack (displace ack)
typedef struct packed {
  L1_reqid_type     l1id;
} I_l2tol1_dack_type;
// 1}}}

// {{{1 l2snoop_ack
typedef struct packed {
  L2_reqid_type     l2id; // If data was present, a disp is triggered
	DR_ndirs_type     directory_id; 
} I_l2snoop_ack_type;
// 1}}}

// {{{1 l2todr_req
typedef struct packed {
  SC_nodeid_type    nid; 
  L2_reqid_type     l2id;

  SC_cmd_type       cmd;
  SC_paddr_type     paddr;
} I_l2todr_req_type;
// 1}}}

// {{{1 drtol2_snack
typedef struct packed {
  SC_nodeid_type     nid; 
  L2_reqid_type      l2id; // !=0 ACK
  DR_reqid_type      drid; // !=0 snoop
	DR_ndirs_type      directory_id;

  SC_snack_type      snack;
  SC_line_type       line;

`ifdef USE_HPADDR_DR
  // hash paddr to check in L2 and DR tag. Many lines may hit in a snoop. 
  DR_hpaddr_base_type hpaddr_base; 
  DR_hpaddr_hash_type hpaddr_hash; 
`else
	SC_paddr_type      paddr;
`endif
} I_drtol2_snack_type;
// 1}}}

// {{{1 l2todr_disp
typedef struct packed {
  SC_nodeid_type    nid;
  L2_reqid_type     l2id; // !=0 means L2 initiated disp (drid==0)
  DR_reqid_type     drid; // !=0 snoop ack. (E.g: SMCD_WI resulting in a disp)

  SC_disp_mask_type mask; // For NC disps
  SC_dcmd_type      dcmd;

  SC_line_type      line;
  SC_paddr_type     paddr;
} I_l2todr_disp_type;
// 1}}}

// {{{1 drtol2_dack (displace ack)
typedef struct packed {
  SC_nodeid_type    nid; 
  L2_reqid_type     l2id;
} I_drtol2_dack_type;
// 1}}}

// {{{1 drsnoop_ack
typedef struct packed {
  DR_reqid_type     drid; // If data was present, a disp is triggered
	DR_ndirs_type     directory_id; 
} I_drsnoop_ack_type;
// 1}}}

// {{{1 coretodc_ld (just loads)
typedef struct packed {
  DC_ckpid_type     ckpid;

  CORE_reqid_type   coreid;
  CORE_lop_type     lop;
  logic             pnr; // core knows it is non-cacheable, perform anyway

  SC_pcsign_type    pcsign;

  SC_poffset_type   poffset;
  SC_imm_type       imm;   // address is laddr+imm
} I_coretodc_ld_type;
// 1}}}

// {{{1 dctocore_ld
typedef struct packed {
  CORE_reqid_type   coreid;
  SC_fault_type     fault; // load not performed due to XXX

  SC_line_type      data; // 1byte to 64bytes for vector
} I_dctocore_ld_type;
// 1}}}

// {{{1 I_ictocore_type
typedef struct packed {
  CORE_reqid_type   coreid;

  SC_fault_type     fault; // load not performed due to XXX

  IC_fwidth_type    data; // 1byte to 64bytes for vector
} I_ictocore_type;
// 1}}}

// {{{1 coretodc_std (stores, checkpoint, and atomic ops)
typedef struct packed {
  DC_ckpid_type     ckpid;

  CORE_reqid_type   coreid;
  CORE_mop_type     mop;
  logic             pnr; // core allows to be non-cacheable/device, perform anyway

  SC_pcsign_type    pcsign;

  SC_poffset_type   poffset;
  SC_imm_type       imm;   // address is laddr+imm

  SC_line_type      data; // 1byte to 64bytes for vector
} I_coretodc_std_type;
// 1}}}

// {{{1 dctocore_std_ack
typedef struct packed {
  SC_fault_type     fault; // load not performed due to XXX

  CORE_reqid_type   coreid;
} I_dctocore_std_ack_type;
// 1}}}

// {{{1 pfgtopfe_op
typedef struct packed {
  // MEGA: 1K subpage prefetch
  // d1:64
  // w1:16
  // d2:0
  // w2:0
  // laddr: 1kpage
  // prefetches: 1kpage,1kpage+64,1kpage+128...
  //
  // Single address prefetch
  // d1:0
  // W1:1
  // d2:0
  // w2:0
  // ladder: addr
  // prefeches: addr
  //
  // Single stride:
  // d1:123 # or whatever stride
  // w1:3   # num prefs
  // d2:0
  // w2:0
  // laddr: addr
  // prefetches: addr+123,addr+2*123,addr+3*123

  PF_delta_type     delta; // Delta from the DVTAGE or delta predictor
  PF_weigth_type    w1; // L1: delta confidence (higher better)
  PF_weigth_type    w2; // L2: delta confidence (higher better)

  SC_pcsign_type    pcsign;
  SC_laddr_type     laddr; // Base Address
  SC_sptbr_type     sptbr;
} I_pfgtopfe_op_type;
// 1}}}

// {{{1 pfetol1tlb_req
typedef struct packed {
  logic             l2;   // true if prefetch is to forward l2 only

  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
} I_pfetol1tlb_req_type;
// 1}}}

// {{{1 l2todr_pfreq
typedef struct packed {
  SC_nodeid_type    nid; 
  SC_paddr_type     paddr;
} I_l2todr_pfreq_type;
// 1}}}

// {{{1 coretopfm_dec
typedef struct packed {
  SC_pcsign_type   pcsign;
  SC_robid_type    rid;
  SC_decwidth_type decmask;
} I_coretopfm_dec_type;
// 1}}}

// {{{1 PFmTocore_pred
typedef struct packed {
  PF_entry_type    pfentry;

  SC_robid_type    d0_rid; // 4 LD/ST delta notified per cycle at most
  PF_delta_type    d0_val;
  PF_weigth_type   d0_w;

  SC_robid_type    d1_rid;
  PF_delta_type    d1_val;
  PF_weigth_type   d1_w;

  SC_robid_type    d2_rid;
  PF_delta_type    d2_val;
  PF_weigth_type   d2_w;

  SC_robid_type    d3_rid;
  PF_delta_type    d3_val;
  PF_weigth_type   d3_w;

} I_pfmtocore_pred_type;
// 1}}}

// {{{1 core_pfretire
typedef struct packed {
  PF_entry_type    pfentry;

  SC_robid_type    d0_rid;
  PF_delta_type    d0_val;

  SC_robid_type    d1_rid;
  PF_delta_type    d1_val;
`ifdef SCMEM_PFRETIRE_4
  SC_robid_type    d2_rid;
  PF_delta_type    d2_val;

  SC_robid_type    d3_rid;
  PF_delta_type    d3_val;
`endif
} I_coretopfm_retire_type;
// 1}}}

// {{{1 drtomem_req
typedef struct packed {
  DR_reqid_type     drid;

  SC_cmd_type       cmd;
  SC_paddr_type     paddr;
} I_drtomem_req_type;
// 1}}}

// {{{1 memtodr_ack
typedef struct packed {
  DR_reqid_type     drid; // invalid entry for prefetch

  SC_nodeid_type    nid; 
  SC_paddr_type     paddr;

  SC_snack_type     ack; // only ACK for mem
  SC_line_type      line;
} I_memtodr_ack_type;
// 1}}}

// {{{1 drtomem_wb 
typedef struct packed {
  // No ReqID, no disp needed, no command, just writeback

  SC_line_type      line;
  SC_disp_mask_type mask; // For NC disps
  SC_paddr_type     paddr;
} I_drtomem_wb_type;
// 1}}}

// {{{1 drtomem_pfreq
typedef struct packed {
  SC_nodeid_type    nid; 
  SC_paddr_type     paddr;
} I_drtomem_pfreq_type;
// 1}}}
`endif 
