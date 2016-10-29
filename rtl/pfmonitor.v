
// Collects data from pfl1monitor and pfl2monitor and generated prefeches
// accordingly
//

`include "scmem.vh"

module pfmonitor(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  ,input  I_coretopfm_dec_type     coretopfm_dec
  ,input                           coretopfm_dec_valid
  ,output                          coretopfm_dec_retry

  ,output I_pfmtocore_pred_type    pfmtocore_pred
  ,output                          pfmtocore_pred_valid
  ,input                           pfmtocore_pred_retry

  ,input  I_coretopfm_retire_type  coretopfm_retire
  ,input                           coretopfm_retire_valid
  ,output                          coretopfm_retire_retry
  /* verilator lint_on UNUSED */
);


endmodule

