`include "scmem.vh"

module dcache_pipe_wp(
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
   input  logic                   clk
  ,input  logic                   reset

  //---------------------------
  // core interface LD
  ,input  logic                   coretodc_ld_valid
  ,output logic                   coretodc_ld_retry
  //  ,input  I_coretodc_ld_type       coretodc_ld
  ,input  DC_ckpid_type           coretodc_ld_ckpid   //4
  ,input  CORE_reqid_type         coretodc_ld_coreid  //6
  ,input  CORE_lop_type           coretodc_ld_lop     //5
  ,input  logic                   coretodc_ld_pnr     //1
  ,input  SC_pcsign_type          coretodc_ld_pcsign  //13
  ,input  SC_poffset_type         coretodc_ld_poffset //12
  ,input  SC_imm_type             coretodc_ld_imm     //12

  ,output logic                   dctocore_ld_valid
  ,input  logic                   dctocore_ld_retry
  //  ,output I_dctocore_ld_type       dctocore_ld
  ,output CORE_reqid_type         dctocore_ld_coreid
  ,output SC_fault_type           dctocore_ld_fault
  //,output SC_line_type            dctocore_ld_data
  ,output logic [63:0]            dctocore_ld_data_7
  ,output logic [63:0]            dctocore_ld_data_6
  ,output logic [63:0]            dctocore_ld_data_5
  ,output logic [63:0]            dctocore_ld_data_4
  ,output logic [63:0]            dctocore_ld_data_3
  ,output logic [63:0]            dctocore_ld_data_2
  ,output logic [63:0]            dctocore_ld_data_1
  ,output logic [63:0]            dctocore_ld_data_0


  //---------------------------
  // core interface STD
  ,input  logic                   coretodc_std_valid
  ,output logic                   coretodc_std_retry
  //  ,input  I_coretodc_std_type      coretodc_std
  ,input  DC_ckpid_type           coretodc_std_ckpid
  ,input  CORE_reqid_type         coretodc_std_coreid
  ,input  CORE_mop_type           coretodc_std_mop
  ,input  logic                   coretodc_std_pnr
  ,input  SC_pcsign_type          coretodc_std_pcsign
  ,input  SC_poffset_type         coretodc_std_poffset
  ,input  SC_imm_type             coretodc_std_imm
  //,input  SC_line_type            coretodc_std_data
  ,input  logic [63:0]            coretodc_std_data_7
  ,input  logic [63:0]            coretodc_std_data_6
  ,input  logic [63:0]            coretodc_std_data_5
  ,input  logic [63:0]            coretodc_std_data_4
  ,input  logic [63:0]            coretodc_std_data_3
  ,input  logic [63:0]            coretodc_std_data_2
  ,input  logic [63:0]            coretodc_std_data_1
  ,input  logic [63:0]            coretodc_std_data_0

  ,output logic                   dctocore_std_ack_valid
  ,input  logic                   dctocore_std_ack_retry
  //  ,output I_dctocore_std_ack_type  dctocore_std_ack
  ,output SC_fault_type           dctocore_std_ack_fault
  ,output CORE_reqid_type         dctocore_std_ack_coreid

  //---------------------------
  // core Prefetch interface
  ,output PF_cache_stats_type     cachetopf_stats

  //---------------------------
  // TLB interface
 
  // TLB interface LD
  ,input  logic                   l1tlbtol1_fwd0_valid
  ,output logic                   l1tlbtol1_fwd0_retry
  //  ,input  I_l1tlbtol1_fwd_type     l1tlbtol1_fwd0
  ,input  CORE_reqid_type         l1tlbtol1_fwd0_coreid       //6
  ,input  logic                   l1tlbtol1_fwd0_prefetch     //1
  ,input  logic                   l1tlbtol1_fwd0_l2_prefetch  //1
  ,input  SC_fault_type           l1tlbtol1_fwd0_fault        //3
  ,input  TLB_hpaddr_type         l1tlbtol1_fwd0_hpaddr       //11
  ,input  SC_ppaddr_type          l1tlbtol1_fwd0_ppaddr       //3
  // TLB interface STD
  ,input  logic                   l1tlbtol1_fwd1_valid
  ,output logic                   l1tlbtol1_fwd1_retry
  //  ,input  I_l1tlbtol1_fwd_type     l1tlbtol1_fwd1
  ,input  CORE_reqid_type         l1tlbtol1_fwd1_coreid
  ,input  logic                   l1tlbtol1_fwd1_prefetch
  ,input  logic                   l1tlbtol1_fwd1_l2_prefetch
  ,input  SC_fault_type           l1tlbtol1_fwd1_fault
  ,input  TLB_hpaddr_type         l1tlbtol1_fwd1_hpaddr
  ,input  SC_ppaddr_type          l1tlbtol1_fwd1_ppaddr

  // Notify the L1 that the index of the TLB is gone
  ,input  logic                   l1tlbtol1_cmd_valid
  ,output logic                   l1tlbtol1_cmd_retry
  //  ,input  I_l1tlbtol1_cmd_type     l1tlbtol1_cmd
  ,input  logic                   l1tlbtol1_cmd_flush
  ,input  TLB_hpaddr_type         l1tlbtol1_cmd_hpaddr

  //---------------------------
  // L2 interface (same for IC and DC)
  ,output logic                   l1tol2tlb_req_valid
  ,input  logic                   l1tol2tlb_req_retry
  //  ,output I_l1tol2tlb_req_type     l1tol2tlb_req
  ,output L1_reqid_type           l1tol2tlb_req_l1id
  ,output logic                   l1tol2tlb_req_prefetch
  ,output TLB_hpaddr_type         l1tol2tlb_req_hpaddr

  ,output logic                   l1tol2_req_valid
  ,input  logic                   l1tol2_req_retry
  //  ,output I_l1tol2_req_type        l1tol2_req
  ,output L1_reqid_type           l1tol2_req_l1id
  ,output SC_cmd_type             l1tol2_req_cmd
  ,output SC_pcsign_type          l1tol2_req_pcsign
  ,output SC_poffset_type         l1tol2_req_poffset
  ,output SC_ppaddr_type          l1tol2_req_ppaddr

  ,input  logic                   l2tol1_snack_valid
  ,output logic                   l2tol1_snack_retry
  //  ,input  I_l2tol1_snack_type      l2tol1_snack
  ,input  L1_reqid_type           l2tol1_snack_l1id
  ,input  L2_reqid_type           l2tol1_snack_l2id
  ,input  SC_snack_type           l2tol1_snack_snack
  //,input  SC_line_type            l2tol1_snack_line
  ,input  logic [63:0]            l2tol1_snack_line_7
  ,input  logic [63:0]            l2tol1_snack_line_6
  ,input  logic [63:0]            l2tol1_snack_line_5
  ,input  logic [63:0]            l2tol1_snack_line_4
  ,input  logic [63:0]            l2tol1_snack_line_3
  ,input  logic [63:0]            l2tol1_snack_line_2
  ,input  logic [63:0]            l2tol1_snack_line_1
  ,input  logic [63:0]            l2tol1_snack_line_0

  ,input  SC_poffset_type         l2tol1_snack_poffset
  ,input  TLB_hpaddr_type         l2tol1_snack_hpaddr

  ,output logic                   l1tol2_snoop_ack_valid
  ,input  logic                   l1tol2_snoop_ack_retry
  //  ,output I_l2snoop_ack_type       l1tol2_snoop_ack
  ,output L2_reqid_type           l1tol2_snoop_ack_l2id
  ,output DR_ndirs_type           l1tol2_snoop_ack_directory_id

  ,output logic                   l1tol2_disp_valid
  ,input  logic                   l1tol2_disp_retry
  //  ,output I_l1tol2_disp_type       l1tol2_disp
  ,output L1_reqid_type           l1tol2_disp_l1id
  ,output L2_reqid_type           l1tol2_disp_l2id
  ,output SC_disp_mask_type       l1tol2_disp_mask
  ,output SC_dcmd_type            l1tol2_disp_dcmd
  //,output SC_line_type            l1tol2_disp_line
  ,output logic [63:0]            l1tol2_disp_line_7
  ,output logic [63:0]            l1tol2_disp_line_6
  ,output logic [63:0]            l1tol2_disp_line_5
  ,output logic [63:0]            l1tol2_disp_line_4
  ,output logic [63:0]            l1tol2_disp_line_3
  ,output logic [63:0]            l1tol2_disp_line_2
  ,output logic [63:0]            l1tol2_disp_line_1
  ,output logic [63:0]            l1tol2_disp_line_0

  ,output SC_ppaddr_type          l1tol2_disp_ppaddr

  ,input  logic                   l2tol1_dack_valid
  ,output logic                   l2tol1_dack_retry
  //  ,input  I_l2tol1_dack_type       l2tol1_dack
  ,input  L1_reqid_type           l2tol1_dack_l1id

  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
);




  I_coretodc_ld_type coretodc_ld;
  assign coretodc_ld.ckpid = coretodc_ld_ckpid;
  assign coretodc_ld.coreid = coretodc_ld_coreid;
  assign coretodc_ld.lop = coretodc_ld_lop;
  assign coretodc_ld.pnr = coretodc_ld_pnr;
  assign coretodc_ld.pcsign = coretodc_ld_pcsign;
  assign coretodc_ld.poffset = coretodc_ld_poffset;
  assign coretodc_ld.imm = coretodc_ld_imm;

  I_dctocore_ld_type dctocore_ld;
  assign dctocore_ld_coreid = dctocore_ld.coreid;
  assign dctocore_ld_fault = dctocore_ld.fault;
  assign {dctocore_ld_data_7, 
          dctocore_ld_data_6, 
          dctocore_ld_data_5, 
          dctocore_ld_data_4, 
          dctocore_ld_data_3, 
          dctocore_ld_data_2, 
          dctocore_ld_data_1, 
          dctocore_ld_data_0} = dctocore_ld.data;

  I_coretodc_std_type coretodc_std;
  assign coretodc_std.ckpid = coretodc_std_ckpid;
  assign coretodc_std.coreid = coretodc_std_coreid;
  assign coretodc_std.mop = coretodc_std_mop;
  assign coretodc_std.pnr = coretodc_std_pnr;
  assign coretodc_std.pcsign = coretodc_std_pcsign;
  assign coretodc_std.poffset = coretodc_std_poffset;
  assign coretodc_std.imm = coretodc_std_imm;
  assign coretodc_std.data = {coretodc_std_data_7,
                              coretodc_std_data_6,
                              coretodc_std_data_5,
                              coretodc_std_data_4,
                              coretodc_std_data_3,
                              coretodc_std_data_2,
                              coretodc_std_data_1,
                              coretodc_std_data_0};

  I_dctocore_std_ack_type dctocore_std_ack;
  assign dctocore_std_ack_fault = dctocore_std_ack.fault;
  assign dctocore_std_ack_coreid = dctocore_std_ack.coreid;

  I_l1tlbtol1_fwd_type l1tlbtol1_fwd0;
  assign l1tlbtol1_fwd0.coreid = l1tlbtol1_fwd0_coreid;
  assign l1tlbtol1_fwd0.prefetch = l1tlbtol1_fwd0_prefetch;
  assign l1tlbtol1_fwd0.l2_prefetch = l1tlbtol1_fwd0_l2_prefetch;
  assign l1tlbtol1_fwd0.fault = l1tlbtol1_fwd0_fault;
  assign l1tlbtol1_fwd0.hpaddr = l1tlbtol1_fwd0_hpaddr;
  assign l1tlbtol1_fwd0.ppaddr = l1tlbtol1_fwd0_ppaddr;

  I_l1tlbtol1_fwd_type l1tlbtol1_fwd1;
  assign l1tlbtol1_fwd1.coreid = l1tlbtol1_fwd1_coreid;
  assign l1tlbtol1_fwd1.prefetch = l1tlbtol1_fwd1_prefetch;
  assign l1tlbtol1_fwd1.l2_prefetch = l1tlbtol1_fwd1_l2_prefetch;
  assign l1tlbtol1_fwd1.fault = l1tlbtol1_fwd1_fault;
  assign l1tlbtol1_fwd1.hpaddr = l1tlbtol1_fwd1_hpaddr;
  assign l1tlbtol1_fwd1.ppaddr = l1tlbtol1_fwd1_ppaddr;

  I_l1tlbtol1_cmd_type l1tlbtol1_cmd;
  assign l1tlbtol1_cmd.flush = l1tlbtol1_cmd_flush;
  assign l1tlbtol1_cmd.hpaddr = l1tlbtol1_cmd_hpaddr;

  I_l1tol2tlb_req_type l1tol2tlb_req;
  assign l1tol2tlb_req_l1id = l1tol2tlb_req.l1id;
  assign l1tol2tlb_req_prefetch = l1tol2tlb_req.prefetch;
  assign l1tol2tlb_req_hpaddr = l1tol2tlb_req.hpaddr;

  I_l1tol2_req_type l1tol2_req;
  assign l1tol2_req_l1id = l1tol2_req.l1id;
  assign l1tol2_req_cmd = l1tol2_req.cmd;
  assign l1tol2_req_pcsign = l1tol2_req.pcsign;
  assign l1tol2_req_poffset = l1tol2_req.poffset;
  assign l1tol2_req_ppaddr = l1tol2_req.ppaddr;

  I_l2tol1_snack_type l2tol1_snack;
  assign l2tol1_snack.l1id = l2tol1_snack_l1id;
  assign l2tol1_snack.l2id = l2tol1_snack_l2id;
  assign l2tol1_snack.snack = l2tol1_snack_snack;
  assign l2tol1_snack.line = {l2tol1_snack_line_7,
                              l2tol1_snack_line_6,
                              l2tol1_snack_line_5,
                              l2tol1_snack_line_4,
                              l2tol1_snack_line_3,
                              l2tol1_snack_line_2,
                              l2tol1_snack_line_1,
                              l2tol1_snack_line_0};

  assign l2tol1_snack.poffset = l2tol1_snack_poffset;
  assign l2tol1_snack.hpaddr = l2tol1_snack_hpaddr;

  I_l2snoop_ack_type l1tol2_snoop_ack;
  assign l1tol2_snoop_ack_l2id = l1tol2_snoop_ack.l2id;
  assign l1tol2_snoop_ack_directory_id = l1tol2_snoop_ack.directory_id;

  I_l1tol2_disp_type l1tol2_disp;
  assign l1tol2_disp_l1id = l1tol2_disp.l1id;
  assign l1tol2_disp_l2id = l1tol2_disp.l2id;
  assign l1tol2_disp_mask = l1tol2_disp.mask;
  assign l1tol2_disp_dcmd = l1tol2_disp.dcmd;
  assign {l1tol2_disp_line_7,
          l1tol2_disp_line_6,
          l1tol2_disp_line_5,
          l1tol2_disp_line_4,
          l1tol2_disp_line_3,
          l1tol2_disp_line_2,
          l1tol2_disp_line_1,
          l1tol2_disp_line_0} = l1tol2_disp.line;

  assign l1tol2_disp_ppaddr = l1tol2_disp.ppaddr;

  I_l2tol1_dack_type l2tol1_dack;
  assign l2tol1_dack.l1id = l2tol1_dack_l1id;


dcache_pipe dcache_pipe_dut(.dctocore_ld (dctocore_ld), .*);
endmodule

