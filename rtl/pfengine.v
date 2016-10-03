
`include "scmem.vh"

//check
// Gets a mptopf and triggers the prefetches over the caches

module pfengine(
  /* verilator lint_off UNUSED */
   input  clk
  ,input  reset

  ,input  logic                    mptopf_op_valid
  ,output logic                    mptopf_op_retry
  ,input  I_mqtopf_op_type         mptopf_op

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


endmodule

