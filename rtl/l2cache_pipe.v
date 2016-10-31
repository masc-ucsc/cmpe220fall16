
// L2 Cache Pipeline
//
// There is ONE to ONE L2_cache pipe to dcache_pipe.
//
// Each L2_cache pipe has different addresses from other L2 cache pipes in the
// same level. 
//
// L2 main parameters
//
// 128KB or 512KB L2 cache
// 16 way associative
//
// Normal MESI coherence protocol (Not U like the dcache or transactions)
//
// 3 Outstading requests queues:
//
// -Req  : Cache requests to E or NC (addr no data)
// -Disp : Displacements, hold the whole cache line
// -Pref : Prefetch (addr no data)
// -snoop: Snoop reuqests 2 reqs.
//
// Configurable # outstanding requests  (req_queue): 16, 32, 64 (configurable)
//
// Configurable # outstanding disps  (disp_queue): 4,8, 16 (configurable)
//
// Configurable # oustanding prefetches (pref_queue): 32, 64 (configurable)
//
// The oldest prefetch gets dropped if the prefetch buffer gets full
//
// The priority between queues is: 1st req, 2nd snoops, 3rd Disp, 4th Pref
//
// If the snoop queue is full or it has been with an entry over 4 cycles, all
// the other inputs are set to retry, and the snoops are drained with the
// highest priority.
//
// The L2 cache replacement:
//
// Lines pushed from the directory have low reuse priority (LRU)
// Prefetche lines have LRU too 
//
// Displacements move to LRU too
//
// Demand hits promote to MRU
//
// Options for cache replacement: 3-bit RRIP with Hawkeye
//
// Haweye focuses on reqs. Disp and pref request
// are know to have low reuse, they automatically set the low priority RRIP.
// (It should be configurable, but prefetch should have 7 for RRIP, disp 6 or
// 7, and push lines 7). A prefetched line hitted with a demand load reads the
// hawkeye predictor and sets the RRIP accordingly.
//
// For the hawkeye use the paper predictor sizes (12KB total)
//
// For PC use in hawkeye use pcsign.
//
// Hawkeye:https://www.cs.utexas.edu/users/lin/papers/isca16.pdf 
//
// if the L2 gets a snoop from directory. It has to respond with a snoop_ack
// or a disp. The disp is done when there was data in the L2.
//
// A snoop share request (SCMD_WS or SCMD_TS) is received to the L2, and the
// cache is not in the L1. The L2 should invalidate the entry with a disp
// message of DCMD_WI or DMCD_I.
`include "scmem.vh"
`define L2_PASSTHROUGH

module l2cache_pipe(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  //---------------------------
  // L1 (icache or dcache)<->l2cache_pipe interface
  ,input                           l1tol2_req_valid
  ,output                          l1tol2_req_retry
  ,input  I_l1tol2_req_type        l1tol2_req

  ,output                          l2tol1_snack_valid
  ,input                           l2tol1_snack_retry
  ,output I_l2tol1_snack_type      l2tol1_snack

  ,input                           l1tol2_snoop_ack_valid
  ,output                          l1tol2_snoop_ack_retry
  ,input  I_l2snoop_ack_type       l1tol2_snoop_ack

  ,input                           l1tol2_disp_valid
  ,output                          l1tol2_disp_retry
  ,input  I_l1tol2_disp_type       l1tol2_disp

  ,output                          l2tol1_dack_valid
  ,input                           l2tol1_dack_retry
  ,output I_l2tol1_dack_type       l2tol1_dack

  //---------------------------
  // L2TLB interface
  ,input                           l2tlbtol2_fwd_valid
  ,output                          l2tlbtol2_fwd_retry
  ,input  I_l2tlbtol2_fwd_type     l2tlbtol2_fwd

  ,output PF_cache_stats_type      cachetopf_stats

  //---------------------------
  // Directory interface
  ,output                          l2todr_req_valid
  ,input                           l2todr_req_retry
  ,output I_l2todr_req_type        l2todr_req

  ,input                           drtol2_snack_valid
  ,output                          drtol2_snack_retry
  ,input  I_drtol2_snack_type      drtol2_snack

  ,output                          l2todr_snoop_ack_valid
  ,input                           l2todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       l2todr_snoop_ack

  ,output                          l2todr_disp_valid
  ,input                           l2todr_disp_retry
  ,output I_l2todr_disp_type       l2todr_disp

  ,input                           drtol2_dack_valid
  ,output                          drtol2_dack_retry
  ,input  I_drtol2_dack_type       drtol2_dack

  ,output logic                    l2todr_pfreq_valid
  ,input  logic                    l2todr_pfreq_retry
  ,output I_l2todr_pfreq_type      l2todr_pfreq

  /* verilator lint_on UNUSED */
);
    /*
    logic l2tol1_snack_next_valid;
    logic l2tol1_snack_next_retry;
    I_l2tol1_snack_type   l2tol1_snack_next;
fflop #(.Size($bits(I_l2tol1_snack_type))) fsnack (
    .clk      (clk),
    .reset    (reset),

    .din      (l2tol1_snack_next),
    .dinValid (l2tol1_snack_next_valid),
    .dinRetry (),
    //.dinRetry (l2tol1_snack_next_retry),

    .q        (l2tol1_snack),
    .qValid   (l2tol1_snack_valid),
    .qRetry   (l2tol1_snack_retry)
  );
*/
    logic   l2todr_req_next_valid;
    logic   l2todr_req_next_retry;
    I_l2todr_req_type   l2todr_req_next;

`ifdef L2_PASSTHROUGH
    assign l2todr_req_next_valid = l1tol2_req_valid;
    assign  l1tol2_req_retry = l2todr_req_next_retry;

    // Temp drive Begin
    assign l1tol2_snoop_ack_retry = 0;
    assign l1tol2_disp_retry = 0;
    assign l2tol1_dack_valid = 1;
    assign l2tol1_dack = 0;
    //assign l1tol2_pfreq_retry = 0;
    //assign pftol2_pfreq_retry = 0;
    assign cachetopf_stats = 0;
    assign drtol2_snack_retry = 0;
    assign l2todr_snoop_ack_valid = 1;
    assign l2todr_snoop_ack = 0;
    assign l2todr_disp_valid = 1;
    assign l2todr_disp = 0;
    assign drtol2_dack_retry = 0;
    assign l2todr_pfreq_valid = 1;
    assign l2todr_pfreq = 0;
    //assign l2tol1_snack_next_valid = 1;
    //assign l2tol1_snack_next = 0;
    assign l2tol1_snack_valid = 1;
    assign l2tol1_snack = 0;
    assign l2tlbtol2_fwd_retry = 0;
    
    
    // Temp drive End
    always_comb begin
        if (l1tol2_req_valid) begin
            l2todr_req_next.nid = 5'b00000; // Could be wrong
            l2todr_req_next.l2id = 6'b00_0000;
            l2todr_req_next.cmd = l1tol2_req.cmd;
            l2todr_req_next.paddr = {{35{1'b0}},
                l1tol2_req.ppaddr,
                {12{1'b0}}}; //35 + 3bit + 12bit
        end
    end

    fflop #(.Size($bits(I_l2todr_req_type))) fl2todr_req (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_req_next),
    .dinValid (l2todr_req_next_valid),
    .dinRetry (l2todr_req_next_retry),

    .q        (l2todr_req),
    .qValid   (l2todr_req_valid),
    .qRetry   (l2todr_req_retry)
    );
`endif

// -> drtol2_snack
// l2tol1_snack ->
`ifdef L2_PASSTHROUGH
    logic l2tol1_snack_next_valid;
    logic l2tol1_snack_next_retry;
    I_l2tol1_snack_type l2tol1_snack_next;
    assign l2tol1_snack_next_valid = drtol2_snack_valid;
    assign drtol2_snack_retry = l2tol1_snack_next_retry;
    always_comb begin
        if (drtol2_snack_valid) begin
            l2tol1_snack_next.l1id = {5{1'b0}};
            l2tol1_snack_next.l2id = drtol2_snack.l2id;
            l2tol1_snack_next.snack = drtol2_snack.snack;
            l2tol1_snack_next.line = drtol2_snack.line;
            l2tol1_snack_next.poffset = {12{1'b0}};
            l2tol1_snack_next.hpaddr = {11{1'b0}};
        end
    end

    fflop #(.Size($bits(I_l2tol1_snack_type))) fl2tol1_snack (
    .clk      (clk),
    .reset    (reset),

    .din      (l2tol1_snack_next),
    .dinValid (l2tol1_snack_next_valid),
    .dinRetry (l2tol1_snack_next_retry),

    .q        (l2tol1_snack),
    .qValid   (l2tol1_snack_valid),
    .qRetry   (l2tol1_snack_retry)
    );
// end
`endif
endmodule

