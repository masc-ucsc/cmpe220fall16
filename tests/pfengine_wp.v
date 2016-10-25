
`include "logfunc.h"

module pfengine_wp (
   input  clk
  ,input  reset

  ,input  logic                    pfgtopfe_op_valid
  ,output logic                    pfgtopfe_op_retry
  ,input PF_delta_type             pfgtopfe_op_d1
  ,input PF_weigth_type            pfgtopfe_op_w1
  ,input PF_delta_type             pfgtopfe_op_d2
  ,input PF_weigth_type            pfgtopfe_op_w2
  ,input SC_pcsign_type            pfgtopfe_op_pcsign
  ,input SC_laddr_type             pfgtopfe_op_laddr
  ,input SC_sptbr_type             pfgtopfe_op_sptbr
  ,logic                           pfgtopfe_op_user

  ,output logic                    pftodc_req0_valid
  ,input  logic                    pftodc_req0_retry
  ,output SC_laddr_type            pftodc_req0_laddr
  ,output SC_sptbr_type            pftodc_req0_sptbr
  ,logic                           pftodc_req0_l2
 
  ,output logic                    pftodc_req1_valid
  ,input  logic                    pftodc_req1_retry
  ,output SC_laddr_type            pftodc_req1_laddr
  ,output SC_sptbr_type            pftodc_req1_sptbr
  ,logic                           pftodc_req1_l2
    
`ifdef SC_4PIPE
  ,output logic                    pftodc_req2_valid
  ,input  logic                    pftodc_req2_retry
  ,output SC_laddr_type            pftodc_req2_laddr
  ,output SC_sptbr_type            pftodc_req2_sptbr
  ,logic                           pftodc_req2_l2

  ,output logic                    pftodc_req3_valid
  ,input  logic                    pftodc_req3_retry
  ,output SC_laddr_type            pftodc_req3_laddr
  ,output SC_sptbr_type            pftodc_req3_sptbr
  ,logic                           pftodc_req3_l2
`endif

//aggregated DC stats output from pfengine
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_nhitmissd
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_nhitmissp
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_nhithit
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_nmiss
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_ndrop
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_nreqs
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_nsnoops
  ,output logic [`PF_STATBITS-1:0]  pf_dcstats_ndisp

//aggregated L2 stats output from pfengine
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_nhitmissd
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_nhitmissp
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_nhithit
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_nmiss
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_ndrop
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_nreqs
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_nsnoops
  ,output logic [`PF_STATBITS-1:0]  pf_l2stats_ndisp  

//pf0_dcstats from DC to pfengine
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf0_dcstats_ndisp

//pf0_l2stats from L2 to pfengine
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf0_l2stats_ndisp 

//pf1_dcstats from DC to pfengine  
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf1_dcstats_ndisp

//pf1_l2stats from L2 to pfengine
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf1_l2stats_ndisp

`ifdef SC_4PIPE

//pf2_dcstats from DC to pfengine  
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf2_dcstats_ndisp 

//pf2_l2stats from L2 to pfengine
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf2_l2stats_ndisp

//pf3_dcstats from DC to pfengine  
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf3_dcstats_ndisp

//pf3_l2stats from L2 to pfengine
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_nhitmissd
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_nhitmissp
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_nhithit
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_nmiss
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_ndrop
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_nreqs
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_nsnoops
  ,input logic [`PF_STATBITS-1:0]  pf3_l2stats_ndisp

`endif

 );

//* verilator lint_off WIDTH */
 pfengine 
 pfe (
   .clk         (clk)
  ,.reset       (reset)

  ,.pfgtopfe_op_valid       (pfgtopfe_op_valid)
  ,.pfgtopfe_op_retry       (pfgtopfe_op_retry)
  ,.pfgtopfe_op             ({pfgtopfe_op_d1
                             ,pfgtopfe_op_w1
                             ,pfgtopfe_op_d2
                             ,pfgtopfe_op_w2
                             ,pfgtopfe_op_pcsign
                             ,pfgtopfe_op_laddr
                             ,pfgtopfe_op_sptbr
                             ,pfgtopfe_op_user})

  ,.pftodc_req0_valid       (pftodc_req0_valid)
  ,.pftodc_req0_retry       (pftodc_req0_retry)
  ,.pftodc_req0             ({pftodc_req0_laddr
                             ,pftodc_req0_sptbr
                             ,pftodc_req0_l2})

  ,.pftodc_req1_valid       (pftodc_req1_valid)
  ,.pftodc_req1_retry       (pftodc_req1_retry)
  ,.pftodc_req1             ({pftodc_req1_laddr
                            ,pftodc_req1_sptbr
                            ,pftodc_req1_l2})

`ifdef SC_4PIPE
  ,.pftodc_req2_valid       (pftodc_req2_valid)
  ,.pftodc_req2_retry       (pftodc_req2_retry)
  ,.pftodc_req2             ({pftodc_req2_laddr
                            ,pftodc_req2_sptbr
                            ,pftodc_req2_l2})

  ,.pftodc_req3_valid       (pftodc_req3_valid)
  ,.pftodc_req3_retry       (pftodc_req3_retry)
  ,.pftodc_req3             ({pftodc_req3_laddr
                            ,pftodc_req3_sptbr
                            ,pftodc_req3_l2})

`endif

  ,.pf_dcstats              ({pf_dcstats_nhitmissd
                            ,pf_dcstats_nhitmissp
                            ,pf_dcstats_nhithit
                            ,pf_dcstats_nmiss
                            ,pf_dcstats_ndrop
                            ,pf_dcstats_nreqs
                            ,pf_dcstats_nsnoops
                            ,pf_dcstats_ndisp})

  ,.pf_l2stats              ({pf_l2stats_nhitmissd
                            ,pf_l2stats_nhitmissp
                            ,pf_l2stats_nhithit
                            ,pf_l2stats_nmiss
                            ,pf_l2stats_ndrop
                            ,pf_l2stats_nreqs
                            ,pf_l2stats_nsnoops
                            ,pf_l2stats_ndisp})

  ,.pf0_dcstats             ({pf0_dcstats_nhitmissd
                            ,pf0_dcstats_nhitmissp
                            ,pf0_dcstats_nhithit
                            ,pf0_dcstats_nmiss
                            ,pf0_dcstats_ndrop
                            ,pf0_dcstats_nreqs
                            ,pf0_dcstats_nsnoops
                            ,pf0_dcstats_ndisp})

  ,.pf0_l2stats             ({pf0_l2stats_nhitmissd
                            ,pf0_l2stats_nhitmissp
                            ,pf0_l2stats_nhithit
                            ,pf0_l2stats_nmiss
                            ,pf0_l2stats_ndrop
                            ,pf0_l2stats_nreqs
                            ,pf0_l2stats_nsnoops
                            ,pf0_l2stats_ndisp})

  ,.pf1_dcstats             ({pf1_dcstats_nhitmissd
                            ,pf1_dcstats_nhitmissp
                            ,pf1_dcstats_nhithit
                            ,pf1_dcstats_nmiss
                            ,pf1_dcstats_ndrop
                            ,pf1_dcstats_nreqs
                            ,pf1_dcstats_nsnoops
                            ,pf1_dcstats_ndisp})

  ,.pf1_l2stats             ({pf1_l2stats_nhitmissd
                            ,pf1_l2stats_nhitmissp
                            ,pf1_l2stats_nhithit
                            ,pf1_l2stats_nmiss
                            ,pf1_l2stats_ndrop
                            ,pf1_l2stats_nreqs
                            ,pf1_l2stats_nsnoops
                            ,pf1_l2stats_ndisp})

`ifdef SC_4PIPE
  ,.pf2_dcstats             ({pf2_dcstats_nhitmissd
                            ,pf2_dcstats_nhitmissp
                            ,pf2_dcstats_nhithit
                            ,pf2_dcstats_nmiss
                            ,pf2_dcstats_ndrop
                            ,pf2_dcstats_nreqs
                            ,pf2_dcstats_nsnoops
                            ,pf2_dcstats_ndisp})

  ,.pf2_l2stats             ({pf2_l2stats_nhitmissd
                            ,pf2_l2stats_nhitmissp
                            ,pf2_l2stats_nhithit
                            ,pf2_l2stats_nmiss
                            ,pf2_l2stats_ndrop
                            ,pf2_l2stats_nreqs
                            ,pf2_l2stats_nsnoops
                            ,pf2_l2stats_ndisp})

  ,.pf3_dcstats             ({pf3_dcstats_nhitmissd
                            ,pf3_dcstats_nhitmissp
                            ,pf3_dcstats_nhithit
                            ,pf3_dcstats_nmiss
                            ,pf3_dcstats_ndrop
                            ,pf3_dcstats_nreqs
                            ,pf3_dcstats_nsnoops
                            ,pf3_dcstats_ndisp})

  ,.pf3_l2stats             ({pf3_l2stats_nhitmissd
                            ,pf3_l2stats_nhitmissp
                            ,pf3_l2stats_nhithit
                            ,pf3_l2stats_nmiss
                            ,pf3_l2stats_ndrop
                            ,pf3_l2stats_nreqs
                            ,pf3_l2stats_nsnoops
                            ,pf3_l2stats_ndisp})

`endif

  );

endmodule

