`ifndef SCMEMI_H
`define SCMEMI_H

// {{{1 l1tol2_req
typedef struct packed {
  L1_reqid_type     dcid;

  SC_cmd_type       cmd;

  SC_pcsign_type    pcsign;
  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
} I_l1tol2_req_type;
// 1}}}

// {{{1 l2tol1_snack
typedef struct packed {
  L1_reqid_type     dcid;  // !=0 ACK, == 0 snoop
  L2_reqid_type     l2id;  // ==0 ACK, != 0 snoop

  SC_snack_type     snack; // Snoop or ACK
  SC_line_type      line;
  SC_paddr_type     paddr; // paddr translation for the laddr in the miss
  SC_dctlbe_type    dctlbe;
} I_l2tol1_snack_type;
// 1}}}

// {{{1 l1tol2_disp 
typedef struct packed {
  L1_reqid_type     l1id;
  L2_reqid_type     l2id; // !=0 means disp as a result of SNOOP (E.g: WB as a result of SCMD_WI)

  SC_disp_mask_type mask;
  SC_dcmd_type      dcmd;

  SC_line_type      line;
  SC_paddr_type     paddr;
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
  SC_nodeid_type    nid; 
  L2_reqid_type     l2id; // !=0 ACK
  DR_reqid_type     drid; // !=0 snoop

  SC_snack_type     snack;
  SC_line_type      line;
  SC_paddr_type     paddr; // Not used for ACKs
} I_drtol2_snack_type;
// 1}}}

// {{{1 l2todr_disp 
typedef struct packed {
  SC_nodeid_type    nid; 
  L2_reqid_type     l2id; // != means L2 initiated disp (drid==0)
  DR_reqid_type     drid; // !=0 snoop ack. (E.g: SMCD_WI resulting in a disp)

  SC_disp_mask_type mask;
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
} I_drsnoop_ack_type;
// 1}}}

// {{{1 coretodc_ld (just loads)
typedef struct packed {
  DC_ckpid_type     ckpid;

  CORE_reqid_type   coreid;
  CORE_lop_type     lop;
  logic             pnr; // core knows it is non-cacheable, perform anyway

  SC_pcsign_type    pcsign;
  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
} I_coretodc_ld_type;
// 1}}}

// {{{1 dctocore_ld
typedef struct packed {
  CORE_reqid_type   coreid;
  SC_abort_type     aborted; // load not performed due to XXX

  SC_line_type      data; // 1byte to 64bytes for vector
} I_dctocore_ld_type;
// 1}}}

// {{{1 I_ictocore_type
typedef struct packed {
  SC_abort_type     aborted; // load not performed due to XXX

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
  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
  SC_line_type      data; // 1byte to 64bytes for vector
} I_coretodc_std_type;
// 1}}}

// {{{1 dctocore_std_ack
typedef struct packed {
  SC_abort_type     aborted; // load not performed due to XXX

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

  PF_delta_type     d; // Delta from the DVTAGE or delta predictor
  PF_weigth_type    w; // delta confidence (higher better)

  SC_pcsign_type    pcsign;
  SC_laddr_type     laddr; // Base Address
  SC_sptbr_type     sptbr;
} I_pfgtopfe_op_type;
// 1}}}

// {{{1 pftocache_req
typedef struct packed {
  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
} I_pftocache_req_type;
// 1}}}

// {{{1 l1tol2_pfreq
typedef struct packed {
  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
} I_l1tol2_pfreq_type;
// 1}}}

// {{{1 l2todr_pfreq
typedef struct packed {
  SC_paddr_type     paddr;
} I_l2todr_pfreq_type;
// 1}}}


// {{{1 core_decode
typedef struct packed {
  SC_pcsign_type   pcsign;
  SC_robid_type    rid;
  SC_robid_type    rid_end;
} I_core_pfdecode_type;
// 1}}}

// {{{1 pftocore_pred
typedef struct packed {
  SC_pcsign_type   pcsign;
  SC_robid_type    d0_rid; // 4 LD/ST delta notified per cycle at most
  PF_delta_type    d0_val;
  SC_robid_type    d1_rid;
  PF_delta_type    d1_val;
  SC_robid_type    d2_rid;
  PF_delta_type    d2_val;
  SC_robid_type    d3_rid;
  PF_delta_type    d3_val;
} I_pftocore_pred_type;
// 1}}}

// {{{1 core_pfretire
typedef struct packed {
  SC_pcsign_type   pcsign;
  SC_robid_type    d0_rid; // 4 LD/ST delta notified per cycle at most
  PF_delta_type    d0_val;
  SC_robid_type    d1_rid;
  PF_delta_type    d1_val;
  SC_robid_type    d2_rid;
  PF_delta_type    d2_val;
  SC_robid_type    d3_rid;
  PF_delta_type    d3_val;
} I_core_pfretire_type;
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
  DR_reqid_type     drid;

  SC_snack_type     ack; // only ACK for mem
  SC_line_type      line;
} I_memtodr_ack_type;
// 1}}}

// {{{1 drtomem_wb 
typedef struct packed {
  // No ReqID, no disp needed, no command, just writeback

  SC_line_type      line;
  SC_paddr_type     paddr;
} I_drtomem_wb_type;
// 1}}}

// {{{1 drtomem_pfreq
typedef struct packed {
  SC_paddr_type     paddr;
} I_drtomem_pfreq_type;
// 1}}}
`endif 
