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
  L2_reqid_type     l2id;
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
  SC_nodeid_type    nid;  // nodeid + checkpoint -> version
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
  L1_reqid_type     l2id;

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
  DR_reqid_type     drid;
} I_drsnoop_ack_type;
// 1}}}

// {{{1 mqtodc_ld (just loads)
typedef struct packed {
  DC_ckpid_type     ckpid;

  MQ_reqid_type     mqid;
  MQ_lop_type       lop;
  logic             pnr; // MQ knows it is non-cacheable, perform anyway

  SC_pcsign_type    pcsign;
  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
} I_mqtodc_ld_type;
// 1}}}

// {{{1 dctomq_ld
typedef struct packed {
  MQ_reqid_type     mqid;
  SC_abort_type     aborted; // load not performed due to XXX

  SC_line_type      data; // 1byte to 64bytes for vector
} I_dctomq_ld_type;
// 1}}}

// {{{1 I_ictocore_type
typedef struct packed {
  SC_abort_type     aborted; // load not performed due to XXX

  IC_fwidth_type    data; // 1byte to 64bytes for vector
} I_ictocore_type;
// 1}}}

// {{{1 mqtodc_std (stores, checkpoint, and atomic ops)
typedef struct packed {
  DC_ckpid_type     ckpid;

  MQ_reqid_type     mqid;
  MQ_mop_type       mop;
  logic             pnr; // MQ allows to be non-cacheable/device, perform anyway

  SC_pcsign_type    pcsign;
  SC_laddr_type     laddr;
  SC_sptbr_type     sptbr;
  SC_line_type      data; // 1byte to 64bytes for vector
} I_mqtodc_std_type;
// 1}}}

// {{{1 dctomq_std_ack
typedef struct packed {
  SC_abort_type     aborted; // load not performed due to XXX

  MQ_reqid_type     mqid;
} I_dctomq_std_ack_type;
// 1}}}

// {{{1 mqtopf_op
typedef struct packed {
  PF_delta_type     d1; // Delta from the DVTAGE or delta predictor
  PF_weigth_type    w1; // delta confidence (higher better)

  PF_delta_type     d2;
  PF_weigth_type    w2;

  SC_pcsign_type    pcsign;
  SC_laddr_type     laddr; // Base Address
  SC_sptbr_type     sptbr;
} I_mqtopf_op_type;
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




`endif 
