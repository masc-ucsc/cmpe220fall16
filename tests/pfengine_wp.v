
`include "logfunc.h"

module pfengine_wp (
   input  clk
  ,input  reset

  ,input  logic                    pfgtopfe_op_valid
  ,output logic                    pfgtopfe_op_retry
  ,input  I_pfgtopfe_op_type       pfgtopfe_op 

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

  ,output PF_cache_stats_type      pf_dcstats  
  ,output PF_cache_stats_type      pf_l2stats  

  ,input  PF_cache_stats_type      pf0_dcstats 
  ,input  PF_cache_stats_type      pf0_l2stats 

  ,input  PF_cache_stats_type      pf1_dcstats 
  ,input  PF_cache_stats_type      pf1_l2stats 

`ifdef SC_4PIPE
  ,input  PF_cache_stats_type      pf2_dcstats  // No fluid, just flop state
  ,input  PF_cache_stats_type      pf2_l2stats  // No fluid, just flop state

  ,input  PF_cache_stats_type      pf3_dcstats  // No fluid, just flop state
  ,input  PF_cache_stats_type      pf3_l2stats  // No fluid, just flop state
`endif

 );

 pfengine 
 pfe (
   .clk         (clk)
  ,.reset       (reset)

  ,.pfgtopfe_op_valid   (pfgtopfe_op_valid)
  ,.pfgtopfe_op_retry   (pfgtopfe_op_retry)
  ,.pfgtopfe_op         (pfgtopfe_op)

  ,.pftodc_req0_valid   (pftodc_req0_valid)
  ,.pftodc_req0_retry   (pftodc_req0_retry)
  ,.pftodc_req0         (pftodc_req0)

  ,.pftol2_req0_valid   (pftol2_req0_valid)
  ,.pftol2_req0_retry   (pftol2_req0_retry)
  ,.pftol2_req0         (pftol2_req0)

  ,.pftodc_req1_valid   (pftodc_req1_valid)
  ,.pftodc_req1_retry   (pftodc_req1_retry)
  ,.pftodc_req1         (pftodc_req1)

  ,.pftol2_req1_valid   (pftol2_req1_valid)
  ,.pftol2_req1_retry   (pftol2_req1_retry)
  ,.pftol2_req1         (pftol2_req1)

`ifdef SC_4PIPE
  ,.pftodc_req2_valid   (pftodc_req2_valid)
  ,.pftodc_req2_retry   (pftodc_req2_retry)
  ,.pftodc_req2         (pftodc_req2)

  ,.pftol2_req2_valid   (pftol2_req2_valid)
  ,.pftol2_req2_retry   (pftol2_req2_retry)
  ,.pftol2_req2         (pftol2_req2)

  ,.pftodc_req3_valid   (pftodc_req3_valid)
  ,.pftodc_req3_retry   (pftodc_req3_retry)
  ,.pftodc_req3         (pftodc_req3)

  ,.pftol2_req3_valid   (pftol2_req3_valid)
  ,.pftol2_req3_retry   (pftol2_req3_retry)
  ,.pftol2_req3         (pftol2_req3)
`endif

  ,.pf_dcstats          (pf_dcstats)
  ,.pf_l2stats          (pf_l2stats)

  ,.pf0_dcstats          (pf0_dcstats)
  ,.pf0_l2stats          (pf0_l2stats)

  ,.pf1_dcstats          (pf1_dcstats)
  ,.pf1_l2stats          (pf1_l2stats)

`ifdef SC_4PIPE
  ,.pf2_dcstats          (pf2_dcstats)
  ,.pf2_l2stats          (pf2_l2stats)

  ,.pf3_dcstats          (pf3_dcstats)
  ,.pf3_l2stats          (pf3_l2stats)
`endif

  );

endmodule

