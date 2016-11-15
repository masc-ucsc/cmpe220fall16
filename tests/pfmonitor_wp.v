
`include "logfunc.h"

module pfmonitor_wp (
    input clk
   ,input reset

   ,input  logic            coretopfm_dec_valid
   ,output logic            coretopfm_dec_retry
   ,input SC_pcsign_type    coretopfm_dec_pcsign
   ,input SC_robid_type     coretopfm_dec_rid
   ,input SC_decwidth_type  coretopfm_dec_decmask

   ,input  logic          coretopfm_retire_valid
   ,output logic          coretopfm_retire_retry
   ,input PF_entry_type   coretopfm_retire_pfentry
   ,input SC_robid_type   coretopfm_retire_d0_rid
   ,input PF_delta_type   coretopfm_retire_d0_val
   ,input SC_robid_type   coretopfm_retire_d1_rid
   ,input PF_delta_type   coretopfm_retire_d1_val
`ifdef SCMEM_PFRETIRE_4
   ,input SC_robid_type   coretopfm_retire_d2_rid
   ,input PF_delta_type   coretopfm_retire_d2_val
   ,input SC_robid_type   coretopfm_retire_d3_rid
   ,input PF_delta_type   coretopfm_retire_d3_val
`endif

   ,output  logic         pfmtocore_pred_valid
   ,input logic           pfmtocore_pred_retry
   ,output PF_entry_type  pfmtocore_pred_pfentry
   ,output SC_robid_type  pfmtocore_pred_d0_rid
   ,output PF_delta_type  pfmtocore_pred_d0_val
   ,output PF_weigth_type pfmtocore_pred_d0_w
   ,output SC_robid_type  pfmtocore_pred_d1_rid
   ,output PF_delta_type  pfmtocore_pred_d1_val
   ,output PF_weigth_type pfmtocore_pred_d1_w
   ,output SC_robid_type  pfmtocore_pred_d2_rid
   ,output PF_delta_type  pfmtocore_pred_d2_val
   ,output PF_weigth_type pfmtocore_pred_d2_w
   ,output SC_robid_type  pfmtocore_pred_d3_rid
   ,output PF_delta_type  pfmtocore_pred_d3_val
   ,output PF_weigth_type pfmtocore_pred_d3_w

);

pfmonitor pfm (
    .clk                    (clk)
   ,.reset                  (reset)

   ,.coretopfm_dec_valid    (coretopfm_dec_valid)
   ,.coretopfm_dec_retry    (coretopfm_dec_retry)
   ,.coretopfm_dec          ({coretopfm_dec_pcsign
                             ,coretopfm_dec_rid
                             ,coretopfm_dec_decmask})

   ,.coretopfm_retire_valid (coretopfm_retire_valid)
   ,.coretopfm_retire_retry (coretopfm_retire_retry)
   ,.coretopfm_retire       ({coretopfm_retire_pfentry
                             ,coretopfm_retire_d0_rid
                             ,coretopfm_retire_d0_val
                             ,coretopfm_retire_d1_rid
                             ,coretopfm_retire_d1_val
                             ,coretopfm_retire_d2_rid
                             ,coretopfm_retire_d2_val
                             ,coretopfm_retire_d3_rid
                             ,coretopfm_retire_d3_val})

    ,.pfmtocore_pred_valid   (pfmtocore_pred_valid)
    ,.pfmtocore_pred_retry   (pfmtocore_pred_retry)
    ,.pfmtocore_pred         ({pfmtocore_pred_pfentry
                              ,pfmtocore_pred_d0_rid
                              ,pfmtocore_pred_d0_val
                              ,pfmtocore_pred_d0_w
                              ,pfmtocore_pred_d1_rid
                              ,pfmtocore_pred_d1_val
                              ,pfmtocore_pred_d1_w
                              ,pfmtocore_pred_d2_rid
                              ,pfmtocore_pred_d2_val
                              ,pfmtocore_pred_d2_w
                              ,pfmtocore_pred_d3_rid
                              ,pfmtocore_pred_d3_val
                              ,pfmtocore_pred_d0_w})


); 

endmodule












