
// Collects data from pfl1monitor and pfl2monitor and generated prefeches
// accordingly
//

`include "scmem.vh"
`include "logfunc.h"


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

  //write dec stats to circular buffer
  logic                                   circularbuffer_wr_req_we;
  logic                                   circularbuffer_wr_req_valid;
  logic                                   circularbuffer_wr_req_retry;
  logic [$bits(I_coretopfm_dec_type)-1:0] circularbuffer_wr_req_data;
  //req_data is coretopfm_dec_next
  logic [`log2(512)-1:0]                  circularbuffer_wr_req_head; //512 entries in cir buffer
 
  logic                                   circularbuffer_wr_ack_data;
  logic                                   circularbuffer_wr_ack_valid;
  logic                                   circularbuffer_wr_ack_retry;

  //circularbuffer_wr_req_we   = 1'b0;
  //circularbuffer_wr_req_head = 9'b0;      //cir buffer pointer initialized to location 0 
  ram_1port_fast #(.Width($bits(I_coretopfm_dec_type)), .Size(512), .Forward(0))
  circularbuffer_write_bank (
    .clk         (clk)
   ,.reset       (reset)

   ,.req_valid   (arb_drid_sram_valid)
   ,.req_retry   (arb_drid_sram_retry)
   ,.req_we      (arb_drid_sram_we)
   ,.req_pos     (drid_ram_pos_next)
   ,.req_data    ({dr_req_temp.nid,dr_req_temp.l2id})

   ,.ack_valid   (drid_storage_ack_valid)
   ,.ack_retry   (drid_storage_ack_retry)
   ,.ack_data    (drid_storage)
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

