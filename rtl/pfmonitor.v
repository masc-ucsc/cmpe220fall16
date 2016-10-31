
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

  logic                 coretopfm_dec_next_valid;
  logic                 coretopfm_dec_next_retry;
  I_coretopfm_dec_type  coretopfm_dec_next;

  //fflop between coretopfm_decode stage stats and pfmonitor
  fflop #(.Size($bits(I_coretopfm_dec_type))) ff_coretopfm_dec (
    .clk      (clk),
    .reset    (reset),

    .din      (coretopfm_dec),
    .dinValid (coretopfm_dec_valid),
    .dinRetry (coretopfm_dec_retry),

    .q        (coretopfm_dec_next),
    .qValid   (coretopfm_dec_next_valid),
    .qRetry   (coretopfm_dec_next_retry)
  );

  logic                   coretopfm_retire_next_valid;
  logic                   coretopfm_retire_next_retry;
  I_coretopfm_retire_type coretopfm_retire_next;

//fflop between coretopfm_retire stage stats and pfmonitor
  fflop #(.Size($bits(I_coretopfm_retire_type))) ff_coretopfm_retire (
    .clk      (clk),
    .reset    (reset),

    .din      (coretopfm_retire),
    .dinValid (coretopfm_retire_valid),
    .dinRetry (coretopfm_retire_retry),

    .q        (coretopfm_retire_next),
    .qValid   (coretopfm_retire_next_valid),
    .qRetry   (coretopfm_retire_next_retry)
  );

  logic                 pfmtocore_pred_prev_retry;
  logic                 pfmtocore_pred_prev_valid;
  I_pfmtocore_pred_type pfmtocore_pred_prev;

//fflop between pfmonitor(pfm predictions) and core
  fflop #(.Size($bits(I_pfmtocore_pred_type))) ff_pfmtocore_pred (
    .clk      (clk),
    .reset    (reset),

    .din      (pfmtocore_pred_prev),
    .dinValid (pfmtocore_pred_prev_valid),
    .dinRetry (pfmtocore_pred_prev_retry),

    .q        (pfmtocore_pred),
    .qValid   (pfmtocore_pred_valid),
    .qRetry   (pfmtocore_pred_retry)
  );





endmodule

