
`include "scmem.vh"

//check
// Gets a pfgtopfe and triggers the prefetches over the caches

module pfengine(
  /* verilator lint_off UNUSED */
 /* verilator lint_off UNDRIVEN */
   input                           clk
  ,input                           reset

  ,input  logic                    pfgtopfe_op_valid
  ,output logic                    pfgtopfe_op_retry
  ,input  I_pfgtopfe_op_type       pfgtopfe_op

  ,output logic                    pftodc_req0_valid
  ,input  logic                    pftodc_req0_retry
  ,output I_pfetol1tlb_req_type    pftodc_req0

  ,output logic                    pftodc_req1_valid
  ,input  logic                    pftodc_req1_retry
  ,output I_pfetol1tlb_req_type    pftodc_req1

`ifdef SC_4PIPE
  ,output logic                    pftodc_req2_valid
  ,input  logic                    pftodc_req2_retry
  ,output I_pfetol1tlb_req_type    pftodc_req2

  ,output logic                    pftodc_req3_valid
  ,input  logic                    pftodc_req3_retry
  ,output I_pfetol1tlb_req_type    pftodc_req3
`endif

  ,output PF_cache_stats_type      pf_dcstats  // No fluid, just flop state
  ,output PF_cache_stats_type      pf_l2stats  // No fluid, just flop state

  ,input  PF_cache_stats_type      pf0_dcstats  // No fluid, just flop state
  ,input  PF_cache_stats_type      pf0_l2stats  // No fluid, just flop state

  ,input  PF_cache_stats_type      pf1_dcstats  // No fluid, just flop state
  ,input  PF_cache_stats_type      pf1_l2stats  // No fluid, just flop state
`ifdef SC_4PIPE
  ,input  PF_cache_stats_type      pf2_dcstats  // No fluid, just flop state
  ,input  PF_cache_stats_type      pf2_l2stats  // No fluid, just flop state

  ,input  PF_cache_stats_type      pf3_dcstats  // No fluid, just flop state
  ,input  PF_cache_stats_type      pf3_l2stats  // No fluid, just flop state
`endif
);

  logic                 pfgtopfe_op_next_valid;
  logic                 pfgtopfe_op_next_retry;
  I_pfgtopfe_op_type    pfgtopfe_op_next;


//fflop between pfgtopfe_op to pfengine logic
/* verilator lint_off WIDTH */
  fflop #(.Size($bits(I_pfgtopfe_op_type))) ff_pfgtopfe_pfe (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pfgtopfe_op_next),
    .qValid   (pfgtopfe_op_next_valid),
    .qRetry   (pfgtopfe_op_next_retry)
  );
 
  `ifdef CHANGE_INTERFACE

  logic                 pftodc_req0_prev_retry;
  logic                 pftodc_req0_prev_valid;
  I_pftocache_req_type  pftodc_req0_prev;

//fflop between pfengine logic to pftodc_req0
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftodc_req0_dc (
    .clk      (clk),
    .reset    (reset),

    .din      (pftodc_req0_prev),
    .dinValid (pftodc_req0_prev_valid),
    .dinRetry (pftodc_req0_prev_retry),

    .q        (pftodc_req0),
    .qValid   (pftodc_req0_valid),
    .qRetry   (pftodc_req0_retry)
  );


  logic                 pftodc_req1_prev_retry;
  logic                 pftodc_req1_prev_valid;
  I_pftocache_req_type  pftodc_req1_prev;

//fflop between pfengine logic to pftodc_req1
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftodc_req1_dc (
    .clk      (clk),
    .reset    (reset),

    .din      (pftodc_req1_prev),
    .dinValid (pftodc_req1_prev_valid),
    .dinRetry (pftodc_req1_prev_retry),

    .q        (pftodc_req1),
    .qValid   (pftodc_req1_valid),
    .qRetry   (pftodc_req1_retry)
  );

  logic                 pftodc_req2_prev_retry;
  logic                 pftodc_req2_prev_valid;
  I_pftocache_req_type  pftodc_req2_prev;

//fflop between pfengine logic to pftodc_req2
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftodc_req2_dc (
    .clk      (clk),
    .reset    (reset),

    .din      (pftodc_req2_prev),
    .dinValid (pftodc_req2_prev_valid),
    .dinRetry (pftodc_req2_prev_retry),

    .q        (pftodc_req2),
    .qValid   (pftodc_req2_valid),
    .qRetry   (pftodc_req2_retry)
  );

  
  logic                 pftodc_req3_prev_retry;
  logic                 pftodc_req3_prev_valid;
  I_pftocache_req_type  pftodc_req3_prev;

//fflop between pfengine logic to pftodc_req3
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftodc_req3_dc (
    .clk      (clk),
    .reset    (reset),

    .din      (pftodc_req3_prev),
    .dinValid (pftodc_req3_prev_valid),
    .dinRetry (pftodc_req3_prev_retry),

    .q        (pftodc_req3),
    .qValid   (pftodc_req3_valid),
    .qRetry   (pftodc_req3_retry)
  );

  logic                 pftol2_req0_prev_retry;
  logic                 pftol2_req0_prev_valid;
  I_pftocache_req_type  pftol2_req0_prev;

//fflop between pfengine logic to pftol2_req0
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftol2_req0_l2 (
    .clk      (clk),
    .reset    (reset),

    .din      (pftol2_req0_prev),
    .dinValid (pftol2_req0_prev_valid),
    .dinRetry (pftol2_req0_prev_retry),

    .q        (pftol2_req0),
    .qValid   (pftol2_req0_valid),
    .qRetry   (pftol2_req0_retry)
  );

  logic                 pftol2_req1_prev_retry;
  logic                 pftol2_req1_prev_valid;
  I_pftocache_req_type  pftol2_req1_prev;

//fflop between pfengine logic to pftol2_req1
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftol2_req1_l2 (
    .clk      (clk),
    .reset    (reset),

    .din      (pftol2_req1_prev),
    .dinValid (pftol2_req1_prev_valid),
    .dinRetry (pftol2_req1_prev_retry),

    .q        (pftol2_req1),
    .qValid   (pftol2_req1_valid),
    .qRetry   (pftol2_req1_retry)
  );

  logic                 pftol2_req2_prev_retry;
  logic                 pftol2_req2_prev_valid;
  I_pftocache_req_type  pftol2_req2_prev;

//fflop between pfengine logic to pftol2_req2
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftol2_req2_l2 (
    .clk      (clk),
    .reset    (reset),

    .din      (pftol2_req2_prev),
    .dinValid (pftol2_req2_prev_valid),
    .dinRetry (pftol2_req2_prev_retry),

    .q        (pftol2_req2),
    .qValid   (pftol2_req2_valid),
    .qRetry   (pftol2_req2_retry)
  );

  logic                 pftol2_req3_prev_retry;
  logic                 pftol2_req3_prev_valid;
  I_pftocache_req_type  pftol2_req3_prev;

//fflop between pfengine logic to pftol2_req3
  fflop #(.Size($bits(I_pftocache_req_type))) ff_pftol2_req3_l2 (
    .clk      (clk),
    .reset    (reset),

    .din      (pftol2_req3_prev),
    .dinValid (pftol2_req3_prev_valid),
    .dinRetry (pftol2_req3_prev_retry),

    .q        (pftol2_req3),
    .qValid   (pftol2_req3_valid),
    .qRetry   (pftol2_req3_retry)
  );


  PF_cache_stats_type   pf0_dcstats_next;     

//flop between pf0_dcstats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf0_dcstats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf0_dcstats),
    .q        (pf0_dcstats_next)
  );


  PF_cache_stats_type   pf0_l2stats_next;

//flop between pf0_l2stats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf0_l2stats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf0_l2stats),
    .q        (pf0_l2stats_next)
  );

  PF_cache_stats_type   pf1_dcstats_next;     

//flop between pf1_dcstats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf1_dcstats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf1_dcstats),
    .q        (pf1_dcstats_next)
  );


  PF_cache_stats_type   pf1_l2stats_next;

//flop between pf1_l2stats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf1_l2stats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf1_l2stats),
    .q        (pf1_l2stats_next)
  );


  PF_cache_stats_type   pf2_dcstats_next;     

//flop between pf2_dcstats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf2_dcstats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf2_dcstats),
    .q        (pf2_dcstats_next)
  );


  PF_cache_stats_type   pf2_l2stats_next;

//flop between pf2_l2stats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf2_l2stats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf2_l2stats),
    .q        (pf2_l2stats_next)
  );


  PF_cache_stats_type   pf3_dcstats_next;     

//flop between pf3_dcstats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf3_dcstats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf3_dcstats),
    .q        (pf3_dcstats_next)
  );


  PF_cache_stats_type   pf3_l2stats_next;

//flop between pf3_l2stats and pfengine logic
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf3_l2stats_pfe(
    .clk      (clk),
    .reset    (reset),

    .d        (pf3_l2stats),
    .q        (pf3_l2stats_next)
  );


  PF_cache_stats_type   pf_dcstats_prev;

//flop between aggregated pf_dcstats and top level dir 
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf_dcstats_top(
    .clk      (clk),
    .reset    (reset),
   
    .d        (pf_dcstats_prev),
    .q        (pf_dcstats)
  );


  PF_cache_stats_type   pf_l2stats_prev;

//flop between aggregated pf_l2stats and top level dir
  flop #(.Bits($bits(PF_cache_stats_type))) flop_pf_l2stats_top(
    .clk      (clk),
    .reset    (reset),

    .d        (pf_l2stats_prev),
    .q        (pf_l2stats)
  );

`endif

/* donotdothis lint_off WIDTH */

endmodule

