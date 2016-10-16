
`include "scmem.vh"

//check
// Gets a pfgtopfe and triggers the prefetches over the caches

module pfengine(
  /* verilator lint_off UNUSED */
   input  clk
  ,input  reset

  ,input  logic                    pfgtopfe_op_valid
  ,output logic                    pfgtopfe_op_retry
  ,input I_pfgtopfe_op_type        pfgtopfe_op

  ,output logic                    pftodc_req0_valid
  ,input  logic                    pftodc_req0_retry
  ,output I_pftocache_req_type     pftodc_req0

  ,output logic                    pftol2_req0_valid
  ,input  logic                    pftol2_req0_retry
  ,output I_pftocache_req_type     pftol2_req0


  ,output logic                    pftodc_req1_valid
  ,input  logic                    pftodc_req1_retry
  ,output I_pftocache_req_type     pftodc_req1

  ,output logic                    pftol2_req1_valid
  ,input  logic                    pftol2_req1_retry
  ,output I_pftocache_req_type     pftol2_req1

`ifdef SC_4PIPE
  ,output logic                    pftodc_req2_valid
  ,input  logic                    pftodc_req2_retry
  ,output I_pftocache_req_type     pftodc_req2

  ,output logic                    pftodc_req3_valid
  ,input  logic                    pftodc_req3_retry
  ,output I_pftocache_req_type     pftodc_req3

  ,output logic                    pftol2_req2_valid
  ,input  logic                    pftol2_req2_retry
  ,output I_pftocache_req_type     pftol2_req2

  ,output logic                    pftol2_req3_valid
  ,input  logic                    pftol2_req3_retry
  ,output I_pftocache_req_type     pftol2_req3
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
  /* verilator lint_on UNUSED */
);


//fflop between pfgtopfe_op to pftodc_req0
/* verilator lint_off WIDTH */
  fflop #(.Size(128)) ff0 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftodc_req0),
    .qValid   (pftodc_req0_valid),
    .qRetry   (pftodc_req0_retry)
  );
 
//fflop between pfgtopfe_op to pftodc_req1
  fflop #(.Size(128)) ff1 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftodc_req1),
    .qValid   (pftodc_req1_valid),
    .qRetry   (pftodc_req1_retry)
  );


//fflop between pfgtopfe_op to pftodc_req2
  fflop #(.Size(128)) ff2 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftodc_req2),
    .qValid   (pftodc_req2_valid),
    .qRetry   (pftodc_req2_retry)
  );


//fflop between pfgtopfe_op to pftodc_req3
  fflop #(.Size(128)) ff3 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftodc_req3),
    .qValid   (pftodc_req3_valid),
    .qRetry   (pftodc_req3_retry)
  );

//fflop between pfgtopfe_op to pftol2_req0
  fflop #(.Size(128)) ff4 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftol2_req0),
    .qValid   (pftol2_req0_valid),
    .qRetry   (pftol2_req0_retry)
  );


//fflop between pfgtopfe_op to pftol2_req1
  fflop #(.Size(128)) ff5 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftol2_req1),
    .qValid   (pftol2_req1_valid),
    .qRetry   (pftol2_req1_retry)
  );

//fflop between pfgtopfe_op to pftol2_req2
  fflop #(.Size(128)) ff6 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftol2_req2),
    .qValid   (pftol2_req2_valid),
    .qRetry   (pftol2_req2_retry)
  );

//fflop between pfgtopfe_op to pftol2_req3
  fflop #(.Size(128)) ff7 (
    .clk      (clk),
    .reset    (reset),

    .din      (pfgtopfe_op),
    .dinValid (pfgtopfe_op_valid),
    .dinRetry (pfgtopfe_op_retry),

    .q        (pftol2_req3),
    .qValid   (pftol2_req3_valid),
    .qRetry   (pftol2_req3_retry)
  );

  //check flop connections
  flop #(.Bits(56)) f0(
    .clk      (clk),
    .reset    (reset),

    .d        (pf0_dcstats),
    .q        (pf_dcstats)
  );


  flop #(.Bits(56)) f1(
    .clk      (clk),
    .reset    (reset),

    .d        (pf0_l2stats),
    .q        (pf_l2stats)
  );

/* verilator lint_off WIDTH */


endmodule

