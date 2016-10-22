
// Collects data from pfl1monitor and pfl2monitor and generated prefeches
// accordingly
//

`include "scmem.vh"

module pfmonitor(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  ,input  I_core_pfdecode_type     pfdecode
  ,input                           pfretire_valid
  ,output                          pfretire_retry

  ,output I_pftocore_pred_type     pfpred
  ,output                          pfpred_valid
  ,input                           pfpred_retry

  ,input  I_core_pfretire_type     pfretire
  ,input                           pfretire_valid
  ,output                          pfretire_retry
  /* verilator lint_on UNUSED */
);


endmodule

