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
`include "logfunc.h"
`define L2_PASSTHROUGH
//`define L2_COMPLETE

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
        logic   l2todr_req_next_valid;
        logic   l2todr_req_next_retry;
        I_l2todr_req_type   l2todr_req_next;
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
  `ifdef L2_PASSTHROUGH
        `ifndef L2_COMPLETE
    //retry sources
    logic l2tlbtol2_fwd_retry_source2;
    logic l2tlbtol2_fwd_retry_source1;
    assign  l2tlbtol2_fwd_retry = l2tlbtol2_fwd_retry_source1 || l2tlbtol2_fwd_retry_source2;
    logic drtol2_snack_retry_source1;
    logic   drtol2_snack_retry_source2;
    assign  drtol2_snack_retry = drtol2_snack_retry_source1 || drtol2_snack_retry_source2;
        `endif
    `endif

    `ifdef L2_PASSTHROUGH
        `ifndef L2_COMPLETE
        assign l2todr_req_next_valid = l1tol2_req_valid;
        assign  l1tol2_req_retry = l2todr_req_next_retry;

        // Temp drive Begin
        //assign l1tol2_pfreq_retry = 0;
        //assign pftol2_pfreq_retry = 0;
        // Temp drive End
        
        // (1) l1tol2_req
        // (2) l2todr_req
        // (3) drtol2_snack
        // (4) l2tol1_snack
    always_comb begin
        // -> l1tol2_req
        // l2todr_req ->
        if (l2todr_req_next_valid) begin
            l2todr_req_next.nid = 5'b00000; // Could be wrong
            l2todr_req_next.l2id = 6'b00_0000;
            l2todr_req_next.cmd = l1tol2_req.cmd;
            l2todr_req_next.paddr = {{35{1'b0}},
                l1tol2_req.ppaddr,
                {12{1'b0}}}; //35 + 3bit + 12bit
        end
    end

    
    `endif
`endif

// -> drtol2_snack
// l2tol1_snack ->
`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
    logic l2tol1_snack_next_valid;
    logic l2tol1_snack_next_retry;
    I_l2tol1_snack_type l2tol1_snack_next;
    assign l2tol1_snack_next_valid = drtol2_snack_valid;
    assign drtol2_snack_retry_source2 = l2tol1_snack_next_retry;
    always_comb begin
        if (l2tol1_snack_next_valid) begin
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
`endif

`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
// -> l1tol2_snoop_ack
// l2todr_snoop_ack ->
    logic l2todr_snoop_ack_next_valid;
    assign l2todr_snoop_ack_next_valid = l1tol2_snoop_ack_valid;
    logic l2todr_snoop_ack_next_retry;
    assign l1tol2_snoop_ack_retry = l2todr_snoop_ack_next_retry;
    I_l2snoop_ack_type l2todr_snoop_ack_next;
    always_comb begin
        if (l2todr_snoop_ack_next_valid) begin
            l2todr_snoop_ack_next.l2id = l1tol2_snoop_ack.l2id;
            l2todr_snoop_ack_next.directory_id = l1tol2_snoop_ack.directory_id;
        end
    end

    fflop #(.Size($bits(I_l2snoop_ack_type))) fl2todr_snoop_ack (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_snoop_ack_next),
    .dinValid (l2todr_snoop_ack_next_valid),
    .dinRetry (l2todr_snoop_ack_next_retry),

    .q        (l2todr_snoop_ack),
    .qValid   (l2todr_snoop_ack_valid),
    .qRetry   (l2todr_snoop_ack_retry)
    );
    `endif
`endif

`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
// -> l2tlbtol2_fwd
// l2todr_pfreq ->
    logic l2todr_pfreq_next_valid;
    assign l2todr_pfreq_next_valid = l2tlbtol2_fwd_valid && l2tlbtol2_fwd.prefetch;
    logic l2todr_pfreq_next_retry;
    assign l2tlbtol2_fwd_retry_source2 = l2todr_pfreq_next_retry;
    I_l2todr_pfreq_type l2todr_pfreq_next;
    always_comb begin
        if (l2todr_pfreq_next_valid) begin
            l2todr_pfreq_next.nid = {5{1'b0}};
            l2todr_pfreq_next.paddr = l2tlbtol2_fwd.paddr;
        end
    end

    fflop #(.Size($bits(I_l2todr_pfreq_type))) fl2todr_pfreq (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_pfreq_next),
    .dinValid (l2todr_pfreq_next_valid),
    .dinRetry (l2todr_pfreq_next_retry),

    .q        (l2todr_pfreq),
    .qValid   (l2todr_pfreq_valid),
    .qRetry   (l2todr_pfreq_retry)
    );
    `endif
`endif

`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
// (1) -> l1tol2_disp
// (2) l2todr_disp ->
// (2) l2tol1_dack ->
    logic l2tol1_dack_next_valid;
    //assign l2tol1_dack_next_valid = l1tol2_disp_valid;
    logic l2tol1_dack_next_retry;
    I_l2tol1_dack_type l2tol1_dack_next;
    //always_comb begin
    //    if (l2tol1_dack_next_valid) begin
    //        l2tol1_dack_next.l1id =  l1tol2_disp.l1id;
    //    end
    //end

    fflop #(.Size($bits(I_l2tol1_dack_type))) fl2tol1_dack (
    .clk      (clk),
    .reset    (reset),

    .din      (l2tol1_dack_next),
    .dinValid (l2tol1_dack_next_valid),
    .dinRetry (l2tol1_dack_next_retry),

    .q        (l2tol1_dack),
    .qValid   (l2tol1_dack_valid),
    .qRetry   (l2tol1_dack_retry)
    );
`endif
`endif

`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
// If l1tol2_disp enabled all mask bits:
//  (1) -> l1tol2_disp
//      Keep sending Retry to l1tol2_disp_retry
//  (2) -> l2tlbtol2_fwd
//  (3) l2todr_disp ->
//  (3) l2tol1_dack ->
// Else:
//  (1) -> l1tol2_disp
//      Keep sending Retry to l1tol2_disp_retry
//  (2) -> l2tlbtol2_fwd (Still Keep sending Retry to l1tol2_disp_retry)
//      Keep sending Retry to l2tlbtol2_fwd_retry
//  (3) l2todr_req ->
//  (4) -> drtol2_snack
//      If hash(drtol2_snack.paddr[49:6]) == (l2tlbtol2_fwd.paddr[49:6]),
//          Release l1tol2_disp_retry and l2tlbtol2_fwd_retry
//  (5) Merge line
//  (6) Send l2tol1_dack and l2todr_disp at the same time
    logic l2todr_disp_next_valid;
    //assign l2todr_disp_next_valid = l1tol2_disp_valid;
    logic l2todr_disp_next_retry;
    logic l2tlb_match_l1disp;
    logic drtol2_ack_valid;
    assign  drtol2_ack_valid = drtol2_snack_valid && (drtol2_snack.l2id!=0);
    assign  l2tlb_match_l1disp = l1tol2_disp_valid && l2tlbtol2_fwd_valid && (l2tlbtol2_fwd.l1id==l1tol2_disp.l1id);
    assign l1tol2_disp_retry = l2todr_disp_next_retry | l2tol1_dack_next_retry; // Note this is BUGGYYYYY!
    I_l2todr_disp_type l2todr_disp_next;
    always_comb begin
        l2todr_disp_next_valid = 0;
        l1tol2_disp_retry = 0;
        l2tlbtol2_fwd_retry_source1 = 0;
        drtol2_snack_retry_source1 = 0;
        if (l1tol2_disp_valid) begin
            // If l1tol2_disp enabled all mask bits:
            if (l1tol2_disp.mask=={64{1'b1}})begin
                if (l2tlbtol2_fwd_valid && (l2tlbtol2_fwd.l1id==l1tol2_disp.l1id)) begin
                    l2todr_disp_next_valid= 1;
                    l2todr_disp_next.nid =  {5{1'b0}};
                    l2todr_disp_next.l2id = {1'b0, l1tol2_disp.l1id};
                    l2todr_disp_next.drid =  {6{1'b0}};
                    l2todr_disp_next.mask = l1tol2_disp.mask;
                    l2todr_disp_next.dcmd = l1tol2_disp.dcmd;
                    l2todr_disp_next.line = l1tol2_disp.line;
                    l2todr_disp_next.paddr = l2tlbtol2_fwd.paddr;

                    l2tol1_dack_next_valid = 1;
                    l2tol1_dack_next.l1id =  l1tol2_disp.l1id;
                end
                else begin
                    l1tol2_disp_retry = 1;
                end
            end
            else begin// If the mask bits of l1tol2_disp are not all enabled
                case ({drtol2_ack_valid, l2tlb_match_l1disp})
                    2'b00: l1tol2_disp_retry = 1;
                    2'b01: begin
                        l1tol2_disp_retry = 1;
                        l2tlbtol2_fwd_retry_source1 = 1;
                    end
                    2'b10: begin
                        l1tol2_disp_retry = 1;
                        drtol2_snack_retry_source1 = 1;
                    end
                    2'b11: begin
                        if (drtol2_snack.paddr[49:6] == l2tlbtol2_fwd.paddr[49:6]) begin
                            // Merge line
                            //0 to 63
                            if (l1tol2_disp.mask[(0+8*0)]) begin
                                l2todr_disp_next.line[((0+8*0)*8+7):(0+8*0)*8] = l1tol2_disp.line[((0+8*0)*8+7):(0+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*0)*8+7):(0+8*0)*8] = drtol2_snack.line[((0+8*0)*8+7):(0+8*0)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*0)]) begin
                                l2todr_disp_next.line[((1+8*0)*8+7):(1+8*0)*8] = l1tol2_disp.line[((1+8*0)*8+7):(1+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*0)*8+7):(1+8*0)*8] = drtol2_snack.line[((1+8*0)*8+7):(1+8*0)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*0)]) begin
                                l2todr_disp_next.line[((2+8*0)*8+7):(2+8*0)*8] = l1tol2_disp.line[((2+8*0)*8+7):(2+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*0)*8+7):(2+8*0)*8] = drtol2_snack.line[((2+8*0)*8+7):(2+8*0)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*0)]) begin
                                l2todr_disp_next.line[((3+8*0)*8+7):(3+8*0)*8] = l1tol2_disp.line[((3+8*0)*8+7):(3+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*0)*8+7):(3+8*0)*8] = drtol2_snack.line[((3+8*0)*8+7):(3+8*0)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*0)]) begin
                                l2todr_disp_next.line[((4+8*0)*8+7):(4+8*0)*8] = l1tol2_disp.line[((4+8*0)*8+7):(4+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*0)*8+7):(4+8*0)*8] = drtol2_snack.line[((4+8*0)*8+7):(4+8*0)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*0)]) begin
                                l2todr_disp_next.line[((5+8*0)*8+7):(5+8*0)*8] = l1tol2_disp.line[((5+8*0)*8+7):(5+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*0)*8+7):(5+8*0)*8] = drtol2_snack.line[((5+8*0)*8+7):(5+8*0)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*0)]) begin
                                l2todr_disp_next.line[((6+8*0)*8+7):(6+8*0)*8] = l1tol2_disp.line[((6+8*0)*8+7):(6+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*0)*8+7):(6+8*0)*8] = drtol2_snack.line[((6+8*0)*8+7):(6+8*0)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*0)]) begin
                                l2todr_disp_next.line[((7+8*0)*8+7):(7+8*0)*8] = l1tol2_disp.line[((7+8*0)*8+7):(7+8*0)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*0)*8+7):(7+8*0)*8] = drtol2_snack.line[((7+8*0)*8+7):(7+8*0)*8];
                            end


                            // 64 to 127

                            if (l1tol2_disp.mask[(0+8*1)]) begin
                                l2todr_disp_next.line[((0+8*1)*8+7):(0+8*1)*8] = l1tol2_disp.line[((0+8*1)*8+7):(0+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*1)*8+7):(0+8*1)*8] = drtol2_snack.line[((0+8*1)*8+7):(0+8*1)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*1)]) begin
                                l2todr_disp_next.line[((1+8*1)*8+7):(1+8*1)*8] = l1tol2_disp.line[((1+8*1)*8+7):(1+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*1)*8+7):(1+8*1)*8] = drtol2_snack.line[((1+8*1)*8+7):(1+8*1)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*1)]) begin
                                l2todr_disp_next.line[((2+8*1)*8+7):(2+8*1)*8] = l1tol2_disp.line[((2+8*1)*8+7):(2+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*1)*8+7):(2+8*1)*8] = drtol2_snack.line[((2+8*1)*8+7):(2+8*1)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*1)]) begin
                                l2todr_disp_next.line[((3+8*1)*8+7):(3+8*1)*8] = l1tol2_disp.line[((3+8*1)*8+7):(3+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*1)*8+7):(3+8*1)*8] = drtol2_snack.line[((3+8*1)*8+7):(3+8*1)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*1)]) begin
                                l2todr_disp_next.line[((4+8*1)*8+7):(4+8*1)*8] = l1tol2_disp.line[((4+8*1)*8+7):(4+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*1)*8+7):(4+8*1)*8] = drtol2_snack.line[((4+8*1)*8+7):(4+8*1)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*1)]) begin
                                l2todr_disp_next.line[((5+8*1)*8+7):(5+8*1)*8] = l1tol2_disp.line[((5+8*1)*8+7):(5+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*1)*8+7):(5+8*1)*8] = drtol2_snack.line[((5+8*1)*8+7):(5+8*1)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*1)]) begin
                                l2todr_disp_next.line[((6+8*1)*8+7):(6+8*1)*8] = l1tol2_disp.line[((6+8*1)*8+7):(6+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*1)*8+7):(6+8*1)*8] = drtol2_snack.line[((6+8*1)*8+7):(6+8*1)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*1)]) begin
                                l2todr_disp_next.line[((7+8*1)*8+7):(7+8*1)*8] = l1tol2_disp.line[((7+8*1)*8+7):(7+8*1)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*1)*8+7):(7+8*1)*8] = drtol2_snack.line[((7+8*1)*8+7):(7+8*1)*8];
                            end

                            // 128 to 191

                            if (l1tol2_disp.mask[(0+8*2)]) begin
                                l2todr_disp_next.line[((0+8*2)*8+7):(0+8*2)*8] = l1tol2_disp.line[((0+8*2)*8+7):(0+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*2)*8+7):(0+8*2)*8] = drtol2_snack.line[((0+8*2)*8+7):(0+8*2)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*2)]) begin
                                l2todr_disp_next.line[((1+8*2)*8+7):(1+8*2)*8] = l1tol2_disp.line[((1+8*2)*8+7):(1+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*2)*8+7):(1+8*2)*8] = drtol2_snack.line[((1+8*2)*8+7):(1+8*2)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*2)]) begin
                                l2todr_disp_next.line[((2+8*2)*8+7):(2+8*2)*8] = l1tol2_disp.line[((2+8*2)*8+7):(2+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*2)*8+7):(2+8*2)*8] = drtol2_snack.line[((2+8*2)*8+7):(2+8*2)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*2)]) begin
                                l2todr_disp_next.line[((3+8*2)*8+7):(3+8*2)*8] = l1tol2_disp.line[((3+8*2)*8+7):(3+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*2)*8+7):(3+8*2)*8] = drtol2_snack.line[((3+8*2)*8+7):(3+8*2)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*2)]) begin
                                l2todr_disp_next.line[((4+8*2)*8+7):(4+8*2)*8] = l1tol2_disp.line[((4+8*2)*8+7):(4+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*2)*8+7):(4+8*2)*8] = drtol2_snack.line[((4+8*2)*8+7):(4+8*2)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*2)]) begin
                                l2todr_disp_next.line[((5+8*2)*8+7):(5+8*2)*8] = l1tol2_disp.line[((5+8*2)*8+7):(5+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*2)*8+7):(5+8*2)*8] = drtol2_snack.line[((5+8*2)*8+7):(5+8*2)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*2)]) begin
                                l2todr_disp_next.line[((6+8*2)*8+7):(6+8*2)*8] = l1tol2_disp.line[((6+8*2)*8+7):(6+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*2)*8+7):(6+8*2)*8] = drtol2_snack.line[((6+8*2)*8+7):(6+8*2)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*2)]) begin
                                l2todr_disp_next.line[((7+8*2)*8+7):(7+8*2)*8] = l1tol2_disp.line[((7+8*2)*8+7):(7+8*2)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*2)*8+7):(7+8*2)*8] = drtol2_snack.line[((7+8*2)*8+7):(7+8*2)*8];
                            end

                            // 192 to 255

                            if (l1tol2_disp.mask[(0+8*3)]) begin
                                l2todr_disp_next.line[((0+8*3)*8+7):(0+8*3)*8] = l1tol2_disp.line[((0+8*3)*8+7):(0+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*3)*8+7):(0+8*3)*8] = drtol2_snack.line[((0+8*3)*8+7):(0+8*3)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*3)]) begin
                                l2todr_disp_next.line[((1+8*3)*8+7):(1+8*3)*8] = l1tol2_disp.line[((1+8*3)*8+7):(1+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*3)*8+7):(1+8*3)*8] = drtol2_snack.line[((1+8*3)*8+7):(1+8*3)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*3)]) begin
                                l2todr_disp_next.line[((2+8*3)*8+7):(2+8*3)*8] = l1tol2_disp.line[((2+8*3)*8+7):(2+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*3)*8+7):(2+8*3)*8] = drtol2_snack.line[((2+8*3)*8+7):(2+8*3)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*3)]) begin
                                l2todr_disp_next.line[((3+8*3)*8+7):(3+8*3)*8] = l1tol2_disp.line[((3+8*3)*8+7):(3+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*3)*8+7):(3+8*3)*8] = drtol2_snack.line[((3+8*3)*8+7):(3+8*3)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*3)]) begin
                                l2todr_disp_next.line[((4+8*3)*8+7):(4+8*3)*8] = l1tol2_disp.line[((4+8*3)*8+7):(4+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*3)*8+7):(4+8*3)*8] = drtol2_snack.line[((4+8*3)*8+7):(4+8*3)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*3)]) begin
                                l2todr_disp_next.line[((5+8*3)*8+7):(5+8*3)*8] = l1tol2_disp.line[((5+8*3)*8+7):(5+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*3)*8+7):(5+8*3)*8] = drtol2_snack.line[((5+8*3)*8+7):(5+8*3)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*3)]) begin
                                l2todr_disp_next.line[((6+8*3)*8+7):(6+8*3)*8] = l1tol2_disp.line[((6+8*3)*8+7):(6+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*3)*8+7):(6+8*3)*8] = drtol2_snack.line[((6+8*3)*8+7):(6+8*3)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*3)]) begin
                                l2todr_disp_next.line[((7+8*3)*8+7):(7+8*3)*8] = l1tol2_disp.line[((7+8*3)*8+7):(7+8*3)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*3)*8+7):(7+8*3)*8] = drtol2_snack.line[((7+8*3)*8+7):(7+8*3)*8];
                            end

                            //256 to 319
                            if (l1tol2_disp.mask[(0+8*4)]) begin
                                l2todr_disp_next.line[((0+8*4)*8+7):(0+8*4)*8] = l1tol2_disp.line[((0+8*4)*8+7):(0+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*4)*8+7):(0+8*4)*8] = drtol2_snack.line[((0+8*4)*8+7):(0+8*4)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*4)]) begin
                                l2todr_disp_next.line[((1+8*4)*8+7):(1+8*4)*8] = l1tol2_disp.line[((1+8*4)*8+7):(1+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*4)*8+7):(1+8*4)*8] = drtol2_snack.line[((1+8*4)*8+7):(1+8*4)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*4)]) begin
                                l2todr_disp_next.line[((2+8*4)*8+7):(2+8*4)*8] = l1tol2_disp.line[((2+8*4)*8+7):(2+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*4)*8+7):(2+8*4)*8] = drtol2_snack.line[((2+8*4)*8+7):(2+8*4)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*4)]) begin
                                l2todr_disp_next.line[((3+8*4)*8+7):(3+8*4)*8] = l1tol2_disp.line[((3+8*4)*8+7):(3+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*4)*8+7):(3+8*4)*8] = drtol2_snack.line[((3+8*4)*8+7):(3+8*4)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*4)]) begin
                                l2todr_disp_next.line[((4+8*4)*8+7):(4+8*4)*8] = l1tol2_disp.line[((4+8*4)*8+7):(4+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*4)*8+7):(4+8*4)*8] = drtol2_snack.line[((4+8*4)*8+7):(4+8*4)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*4)]) begin
                                l2todr_disp_next.line[((5+8*4)*8+7):(5+8*4)*8] = l1tol2_disp.line[((5+8*4)*8+7):(5+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*4)*8+7):(5+8*4)*8] = drtol2_snack.line[((5+8*4)*8+7):(5+8*4)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*4)]) begin
                                l2todr_disp_next.line[((6+8*4)*8+7):(6+8*4)*8] = l1tol2_disp.line[((6+8*4)*8+7):(6+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*4)*8+7):(6+8*4)*8] = drtol2_snack.line[((6+8*4)*8+7):(6+8*4)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*4)]) begin
                                l2todr_disp_next.line[((7+8*4)*8+7):(7+8*4)*8] = l1tol2_disp.line[((7+8*4)*8+7):(7+8*4)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*4)*8+7):(7+8*4)*8] = drtol2_snack.line[((7+8*4)*8+7):(7+8*4)*8];
                            end

                            // 320 to 383
                            if (l1tol2_disp.mask[(0+8*5)]) begin
                                l2todr_disp_next.line[((0+8*5)*8+7):(0+8*5)*8] = l1tol2_disp.line[((0+8*5)*8+7):(0+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*5)*8+7):(0+8*5)*8] = drtol2_snack.line[((0+8*5)*8+7):(0+8*5)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*5)]) begin
                                l2todr_disp_next.line[((1+8*5)*8+7):(1+8*5)*8] = l1tol2_disp.line[((1+8*5)*8+7):(1+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*5)*8+7):(1+8*5)*8] = drtol2_snack.line[((1+8*5)*8+7):(1+8*5)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*5)]) begin
                                l2todr_disp_next.line[((2+8*5)*8+7):(2+8*5)*8] = l1tol2_disp.line[((2+8*5)*8+7):(2+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*5)*8+7):(2+8*5)*8] = drtol2_snack.line[((2+8*5)*8+7):(2+8*5)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*5)]) begin
                                l2todr_disp_next.line[((3+8*5)*8+7):(3+8*5)*8] = l1tol2_disp.line[((3+8*5)*8+7):(3+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*5)*8+7):(3+8*5)*8] = drtol2_snack.line[((3+8*5)*8+7):(3+8*5)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*5)]) begin
                                l2todr_disp_next.line[((4+8*5)*8+7):(4+8*5)*8] = l1tol2_disp.line[((4+8*5)*8+7):(4+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*5)*8+7):(4+8*5)*8] = drtol2_snack.line[((4+8*5)*8+7):(4+8*5)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*5)]) begin
                                l2todr_disp_next.line[((5+8*5)*8+7):(5+8*5)*8] = l1tol2_disp.line[((5+8*5)*8+7):(5+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*5)*8+7):(5+8*5)*8] = drtol2_snack.line[((5+8*5)*8+7):(5+8*5)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*5)]) begin
                                l2todr_disp_next.line[((6+8*5)*8+7):(6+8*5)*8] = l1tol2_disp.line[((6+8*5)*8+7):(6+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*5)*8+7):(6+8*5)*8] = drtol2_snack.line[((6+8*5)*8+7):(6+8*5)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*5)]) begin
                                l2todr_disp_next.line[((7+8*5)*8+7):(7+8*5)*8] = l1tol2_disp.line[((7+8*5)*8+7):(7+8*5)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*5)*8+7):(7+8*5)*8] = drtol2_snack.line[((7+8*5)*8+7):(7+8*5)*8];
                            end

                            // 384 to 447
                            if (l1tol2_disp.mask[(0+8*6)]) begin
                                l2todr_disp_next.line[((0+8*6)*8+7):(0+8*6)*8] = l1tol2_disp.line[((0+8*6)*8+7):(0+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*6)*8+7):(0+8*6)*8] = drtol2_snack.line[((0+8*6)*8+7):(0+8*6)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*6)]) begin
                                l2todr_disp_next.line[((1+8*6)*8+7):(1+8*6)*8] = l1tol2_disp.line[((1+8*6)*8+7):(1+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*6)*8+7):(1+8*6)*8] = drtol2_snack.line[((1+8*6)*8+7):(1+8*6)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*6)]) begin
                                l2todr_disp_next.line[((2+8*6)*8+7):(2+8*6)*8] = l1tol2_disp.line[((2+8*6)*8+7):(2+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*6)*8+7):(2+8*6)*8] = drtol2_snack.line[((2+8*6)*8+7):(2+8*6)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*6)]) begin
                                l2todr_disp_next.line[((3+8*6)*8+7):(3+8*6)*8] = l1tol2_disp.line[((3+8*6)*8+7):(3+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*6)*8+7):(3+8*6)*8] = drtol2_snack.line[((3+8*6)*8+7):(3+8*6)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*6)]) begin
                                l2todr_disp_next.line[((4+8*6)*8+7):(4+8*6)*8] = l1tol2_disp.line[((4+8*6)*8+7):(4+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*6)*8+7):(4+8*6)*8] = drtol2_snack.line[((4+8*6)*8+7):(4+8*6)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*6)]) begin
                                l2todr_disp_next.line[((5+8*6)*8+7):(5+8*6)*8] = l1tol2_disp.line[((5+8*6)*8+7):(5+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*6)*8+7):(5+8*6)*8] = drtol2_snack.line[((5+8*6)*8+7):(5+8*6)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*6)]) begin
                                l2todr_disp_next.line[((6+8*6)*8+7):(6+8*6)*8] = l1tol2_disp.line[((6+8*6)*8+7):(6+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*6)*8+7):(6+8*6)*8] = drtol2_snack.line[((6+8*6)*8+7):(6+8*6)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*6)]) begin
                                l2todr_disp_next.line[((7+8*6)*8+7):(7+8*6)*8] = l1tol2_disp.line[((7+8*6)*8+7):(7+8*6)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*6)*8+7):(7+8*6)*8] = drtol2_snack.line[((7+8*6)*8+7):(7+8*6)*8];
                            end

                            // 448 to 511
                            if (l1tol2_disp.mask[(0+8*7)]) begin
                                l2todr_disp_next.line[((0+8*7)*8+7):(0+8*7)*8] = l1tol2_disp.line[((0+8*7)*8+7):(0+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((0+8*7)*8+7):(0+8*7)*8] = drtol2_snack.line[((0+8*7)*8+7):(0+8*7)*8];
                            end

                            if (l1tol2_disp.mask[(1+8*7)]) begin
                                l2todr_disp_next.line[((1+8*7)*8+7):(1+8*7)*8] = l1tol2_disp.line[((1+8*7)*8+7):(1+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((1+8*7)*8+7):(1+8*7)*8] = drtol2_snack.line[((1+8*7)*8+7):(1+8*7)*8];
                            end

                            if (l1tol2_disp.mask[(2+8*7)]) begin
                                l2todr_disp_next.line[((2+8*7)*8+7):(2+8*7)*8] = l1tol2_disp.line[((2+8*7)*8+7):(2+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((2+8*7)*8+7):(2+8*7)*8] = drtol2_snack.line[((2+8*7)*8+7):(2+8*7)*8];
                            end

                            if (l1tol2_disp.mask[(3+8*7)]) begin
                                l2todr_disp_next.line[((3+8*7)*8+7):(3+8*7)*8] = l1tol2_disp.line[((3+8*7)*8+7):(3+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((3+8*7)*8+7):(3+8*7)*8] = drtol2_snack.line[((3+8*7)*8+7):(3+8*7)*8];
                            end

                            if (l1tol2_disp.mask[(4+8*7)]) begin
                                l2todr_disp_next.line[((4+8*7)*8+7):(4+8*7)*8] = l1tol2_disp.line[((4+8*7)*8+7):(4+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((4+8*7)*8+7):(4+8*7)*8] = drtol2_snack.line[((4+8*7)*8+7):(4+8*7)*8];
                            end

                            if (l1tol2_disp.mask[(5+8*7)]) begin
                                l2todr_disp_next.line[((5+8*7)*8+7):(5+8*7)*8] = l1tol2_disp.line[((5+8*7)*8+7):(5+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((5+8*7)*8+7):(5+8*7)*8] = drtol2_snack.line[((5+8*7)*8+7):(5+8*7)*8];
                            end

                            if (l1tol2_disp.mask[(6+8*7)]) begin
                                l2todr_disp_next.line[((6+8*7)*8+7):(6+8*7)*8] = l1tol2_disp.line[((6+8*7)*8+7):(6+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((6+8*7)*8+7):(6+8*7)*8] = drtol2_snack.line[((6+8*7)*8+7):(6+8*7)*8];
                            end

                            if (l1tol2_disp.mask[(7+8*7)]) begin
                                l2todr_disp_next.line[((7+8*7)*8+7):(7+8*7)*8] = l1tol2_disp.line[((7+8*7)*8+7):(7+8*7)*8];
                            end
                            else begin
                                l2todr_disp_next.line[((7+8*7)*8+7):(7+8*7)*8] = drtol2_snack.line[((7+8*7)*8+7):(7+8*7)*8];
                            end
                            
                            l2todr_disp_next_valid= 1;
                            l2todr_disp_next.nid =  {5{1'b0}};
                            l2todr_disp_next.l2id = {1'b0, l1tol2_disp.l1id};
                            l2todr_disp_next.drid =  {6{1'b0}};
                            l2todr_disp_next.mask = l1tol2_disp.mask;
                            l2todr_disp_next.dcmd = l1tol2_disp.dcmd;
                            l2todr_disp_next.paddr = l2tlbtol2_fwd.paddr;

                            l2tol1_dack_next_valid = 1;
                            l2tol1_dack_next.l1id =  l1tol2_disp.l1id;
                        end // of if (drtol2_snack.paddr[49:6] == l2tlbtol2_fwd.paddr[49:6]) begin
                        else begin
                            // The dr ack is not the wanted one,
                            // so still need to hold l2tlbtol2_fwd and looking for drtol2_snack
                            l2tlbtol2_fwd_retry_source1 = 1;
                        end
                    end
                endcase
            end
        end
    end

    fflop #(.Size($bits(I_l2todr_disp_type))) fl2todr_disp (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_disp_next),
    .dinValid (l2todr_disp_next_valid),
    .dinRetry (l2todr_disp_next_retry),

    .q        (l2todr_disp),
    .qValid   (l2todr_disp_valid),
    .qRetry   (l2todr_disp_retry)
    );
    `endif
`endif



`ifdef L2_COMPLETE
    // l1 and l2tlb
    typedef struct packed {
        I_l1tol2_req_type   l1tol2_req;
        logic               ppaddr_corrected;
        logic               next;
    } I_q_l1tol2_req_type;

    // qzhang33
    typedef struct packed {
        SC_paddr_type              paddr;
        //TLB_hpaddr_type            hpaddr;
        I_l1tol2_req_type          l1tol2_req;
        logic                      next;
    } I_q_l1tol2_req_hpaddr_miss_type;

    typedef struct packed {
        logic    [3:0]           head;
        logic    [3:0]           tail;
    } I_q_l1tol2_req_linked_list_type;
    // qzhang33

    /*
    ram_2port_fast #(.Width(), .Size(), .Forward(0))   (
        .clk            (clk),
        .reset          (reset),
        
        .req_wr_valid   (_valid),
        .req_wr_retry   (_retry),
        .req_wr_addr    (_addr),
        .req_wr_data    (_data),

        .req_rd_valid   (_valid),
        .req_rd_retry   (_retry),
        .req_rd_addr    (_addr),

        .ack_rd_valid   (_valid),
        .ack_rd_retry   (_retry),
        .ack_rd_data    (_data)
    );
*/

// Signals for tag
    // Each tag "line" contains all 16 ways 
    typedef struct packed {
        logic   [15:0]  valid;
        TLB_hpaddr_type     hpaddr_way0, hpaddr_way1, hpaddr_way2, hpaddr_way3,
                            hpaddr_way4, hpaddr_way5, hpaddr_way6, hpaddr_way7,
                            hpaddr_way8, hpaddr_way9, hpaddr_way10, hpaddr_way11,
                            hpaddr_way12, hpaddr_way13, hpaddr_way14, hpaddr_way15;
    } tag_t;
    localparam  TAG_WIDTH = $bits(tag_t);
    localparam  TAG_SIZE = 128;
    logic   [1:0]   tag_bank_id;
    logic   [6:0]  predicted_index;
    // bank0
    // way0 to way15
    logic tag_req_valid_bank[4];
    logic tag_req_retry_bank[4];
    logic tag_req_we_bank[4];
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank[4];
    tag_t   tag_req_data_bank[4];
    logic   tag_ack_valid_bank[4];
    logic   tag_ack_retry_bank[4];
    tag_t   tag_ack_data_bank[4];

    // Signals for Data Bank
    logic   final_tag_hit;

    // Control regs
    // S1 components
    // ->S1: Save new l1tol2_req
    // S1->: choose a request for accessing tag
    // S1 fflop
    typedef struct packed {
        I_l1tol2_req_type   l1tol2_req;
        logic   [5:0]  llht_addr;
    } s1_t;
    s1_t    s1_next_d, s1_q;
    fflop #(.Size($bits(s1_t))) ff_s1 (
    .clk      (clk),
    .reset    (reset),

    .din      (s1_next_d),
    .dinValid (s1_next_dvalid),
    .dinRetry (s1_next_dretry),

    .q        (s1_q),
    .qValid   (s1_qvalid),
    .qRetry   (s1_qretry)
    );

    //A Linked List
    //A.1 Head Tail RAM
    typedef struct packed {
        logic   [4:0]   head; // head position in the request queue
        logic   [4:0]   tail;
        logic           valid;
    } llht_ram_t; 
    localparam  LLHT_RAM_WIDTH =  $bits(llht_ram_t);
    localparam  LLHT_RAM_SIZE  = 64;
    logic   req_wr_llht_next_valid;
    logic   req_wr_llht_next_retry;
    logic   [`log2(LLHT_RAM_SIZE)-1 : 0]  req_wr_llht_next_addr;
    llht_ram_t   req_wr_llht_next_data;
    logic   req_rd_llht_next_valid;
    logic   req_rd_llht_next_retry;
    logic   [`log2(LLHT_RAM_SIZE)-1 : 0]  req_rd_llht_next_addr;
    logic   ack_rd_llht_valid;
    logic   ack_rd_llht_retry;
    llht_ram_t   ack_rd_llht_data;
    ram_2port_fast #(.Width(LLHT_RAM_WIDTH), .Size(64), .Forward(0)) llht_ram  (
        .clk            (clk),
        .reset          (reset),
        
        .req_wr_valid   (req_wr_llht_next_valid),
        .req_wr_retry   (req_wr_llht_next_retry),
        .req_wr_addr    (req_wr_llht_next_addr),
        .req_wr_data    (req_wr_llht_next_data),

        .req_rd_valid   (req_rd_llht_next_valid),
        .req_rd_retry   (req_rd_llht_next_retry),
        .req_rd_addr    (req_rd_llht_next_addr),

        .ack_rd_valid   (ack_rd_llht_valid),
        .ack_rd_retry   (ack_rd_llht_retry),
        .ack_rd_data    (ack_rd_llht_data)
    );
    //A.2 request queue

    typedef struct packed {
        logic           valid;
        logic           ready;
        logic           ishead;
        logic           launched;
        logic   [3:0]   req_type; //1 = l1tol2_req
        I_l1tol2_req_type   l1tol2_req;
        logic   [3:0]   next;
        TLB_hpaddr_type              hpaddr;
        SC_paddr_type   paddr;
    } q_req_t;
    
    logic   qreq_next_dvalid[16];
    logic   qreq_next_dretry[16];
    q_req_t qreq_next_d[16];
    logic   qreq_qvalid[16];
    logic   qreq_qretry[16];
    q_req_t qreq_q[16];

    generate
        genvar i;
        for (i=0; i<=15; i=i+1) begin
            fflop #(.Size($bits(q_req_t))) ff_qreq (
                .clk      (clk),
                .reset    (reset),

                .din      (qreq_next_d[i]),
                .dinValid (qreq_next_dvalid[i]),
                .dinRetry (qreq_next_dretry[i]),

                .q        (qreq_q[i]),
                .qValid   (qreq_qvalid[i]),
                .qRetry   (qreq_qretry[i])
            );
        end
    endgenerate

    //A.3 counter for request queue
    logic   qreq_counter_next_dvalid;
    logic   qreq_counter_next_dretry;
    logic   [4:0]   qreq_counter_next_d;
    logic   qreq_counter_qvalid;
    logic   qreq_counter_qretry;
    logic   [4:0]   qreq_counter_q;

    fflop #(.Size(5)) ff_qreq_counter (
    .clk      (clk),
    .reset    (reset),

    .din      (qreq_counter_next_d),
    .dinValid (qreq_counter_next_dvalid),
    .dinRetry (qreq_counter_next_dretry),

    .q        (qreq_counter_q),
    .qValid   (qreq_counter_qvalid),
    .qRetry   (qreq_counter_qretry)
    );

    /*
    //A.4 write pointer for request queue
    logic   qreq_wrpointer_next_dvalid;
    logic   qreq_wrpointer_next_dretry;
    logic   [4:0]   qreq_wrpointer_next_d;
    logic   qreq_wrpointer_qvalid;
    logic   qreq_wrpointer_qretry;
    logic   [4:0]   qreq_wrpointer_q;

    fflop #(.Size(5)) ff_qreq_wrpointer (
    .clk      (clk),
    .reset    (reset),

    .din      (qreq_wrpointer_next_d),
    .dinValid (qreq_wrpointer_next_dvalid),
    .dinRetry (qreq_wrpointer_next_dretry),

    .q        (qreq_wrpointer_q),
    .qValid   (qreq_wrpointer_qvalid),
    .qRetry   (qreq_wrpointer_qretry)
    );
    */

    // S2->:
    // S2 fflop
    // TODO
    typedef struct packed {
        logic   [4:0]   winner_for_tag;
        I_l1tol2_req_type   l1tol2_req;
        TLB_hpaddr_type hpaddr;
        SC_paddr_type paddr;
        logic [1:0] which_bank;
        I_drtol2_snack_type drtol2_snack;
    } s2_t;
    s2_t    s2_next_d, s2_q;
    fflop #(.Size($bits(s2_t))) ff_s2 (
    .clk      (clk),
    .reset    (reset),

    .din      (s2_next_d),
    .dinValid (s2_next_dvalid),
    .dinRetry (s2_next_dretry),

    .q        (s2_q),
    .qValid   (s2_qvalid),
    .qRetry   (s2_qretry)
    );

    // S3->:
    typedef struct packed {
        logic   [4:0]   winner_for_tag;
        I_l1tol2_req_type   l1tol2_req;
        logic   l1_match_l2tlb_l1id;
        logic   l1_match_l2tlb_ppaddr;
        TLB_hpaddr_type hpaddr;
        SC_paddr_type   paddr;
        logic [1:0] which_bank;
        I_drtol2_snack_type drtol2_snack;        
    } s3_t;
    s3_t    s3_next_d, s3_q;
    fflop #(.Size($bits(s3_t))) ff_s3 (
    .clk      (clk),
    .reset    (reset),

    .din      (s3_next_d),
    .dinValid (s3_next_dvalid),
    .dinRetry (s3_next_dretry),

    .q        (s3_q),
    .qValid   (s3_qvalid),
    .qRetry   (s3_qretry)
    );

    // S4->:
    typedef struct packed {
        logic   [4:0]   winner_for_tag;
        I_l1tol2_req_type   l1tol2_req;
        logic [3:0]    hit_way;
        logic   tag_hit;
        logic   tag_miss;
        TLB_hpaddr_type hpaddr;
        SC_paddr_type   paddr;
        logic [1:0] which_bank;
    } s4_t;
    s4_t    s4_next_d, s4_q;
    fflop #(.Size($bits(s4_t))) ff_s4 (
    .clk      (clk),
    .reset    (reset),

    .din      (s4_next_d),
    .dinValid (s4_next_dvalid),
    .dinRetry (s4_next_dretry),

    .q        (s4_q),
    .qValid   (s4_qvalid),
    .qRetry   (s4_qretry)
    );

    // S5->:
    typedef struct packed {
        logic   [4:0]   winner_for_tag;
        I_l1tol2_req_type   l1tol2_req;
        logic [3:0]    hit_way;
        TLB_hpaddr_type hpaddr;
        SC_paddr_type   paddr;
        logic [1:0] which_bank;
    } s5_t;
    s5_t    s5_next_d, s5_q;
    fflop #(.Size($bits(s5_t))) ff_s5 (
    .clk      (clk),
    .reset    (reset),

    .din      (s5_next_d),
    .dinValid (s5_next_dvalid),
    .dinRetry (s5_next_dretry),

    .q        (s5_q),
    .qValid   (s5_qvalid),
    .qRetry   (s5_qretry)
    );

    // S6->:
    typedef struct packed {
        logic   [4:0]   winner_for_tag;
        I_l1tol2_req_type   l1tol2_req;
        logic [3:0]    hit_way;
        TLB_hpaddr_type hpaddr;
        SC_paddr_type   paddr;
        
        logic [1:0] which_bank;
    } s6_t;
    s6_t    s6_next_d, s6_q;
    fflop #(.Size($bits(s6_t))) ff_s6 (
    .clk      (clk),
    .reset    (reset),

    .din      (s6_next_d),
    .dinValid (s6_next_dvalid),
    .dinRetry (s6_next_dretry),

    .q        (s6_q),
    .qValid   (s6_qvalid),
    .qRetry   (s6_qretry)
    );


    // S7->:
    typedef struct packed {
        I_l1tol2_req_type   l1tol2_req;
    } s7_t;
    s7_t    s7_next_d, s7_q;
    fflop #(.Size($bits(s7_t))) ff_s7 (
    .clk      (clk),
    .reset    (reset),

    .din      (s7_next_d),
    .dinValid (s7_next_dvalid),
    .dinRetry (s7_next_dretry),

    .q        (s7_q),
    .qValid   (s7_qvalid),
    .qRetry   (s7_qretry)
    );

    // t2->:
    typedef struct packed {
        logic   [4:0]   winner_for_tag;
        I_drtol2_snack_type      drtol2_snack;
        tag_t   old_tag_content;
    } t2_t;
    t2_t    t2_next_d, t2_q;
    fflop #(.Size($bits(t2_t))) ff_t2 (
    .clk      (clk),
    .reset    (reset),

    .din      (t2_next_d),
    .dinValid (t2_next_dvalid),
    .dinRetry (t2_next_dretry),

    .q        (t2_q),
    .qValid   (t2_qvalid),
    .qRetry   (t2_qretry)
    );

    // Combinational Logic
    // S0: Handle new requests
    // S0.A Read llht
    // VS S6.B+: Update llht
    // TODO: if S6 wins then S0 l1tol2_req should retry
    assign req_rd_llht_next_valid = l1tol2_req_valid || final_tag_hit;
    assign req_rd_llht_next_addr = final_tag_hit ? s6_q.l1tol2_req.poffset[11:6] : l1tol2_req.poffset[11:6]; // This range is part of the paddr
    // S0.B Save regs for S1
    assign s1_next_dvalid = l1tol2_req_valid;
    assign s1_next_d.l1tol2_req = l1tol2_req;
    assign s1_next_d.llht_addr = req_rd_llht_next_addr;

    // T1: drtol2 ack read tag
    assign  drtol2_ack = drtol2_snack_valid && (drtol2_snack.l2id != 0);

    // S1:
    // S1.A Enqueue prep
    logic   write_qreq;
    logic   read_qreq;
    assign ishead = (ack_rd_llht_data.valid==0);
    assign qreq_full = (qreq_counter_q >= 16);
    assign  write_qreq = (~qreq_full) && s1_qvalid;
    always_comb begin
        for (integer index=0; index<=15; index=index+1) begin
            qreq_next_dvalid[index] = 0;
            qreq_next_d[index] = qreq_q[index];
        end
    //S1.B Enqueue to q_req
    /*
        qreq_next_dvalid[qreq_wrpointer_q[3:0]] = write_qreq;
        qreq_next_d[qreq_wrpointer_q[3:0]].valid = 1;
        qreq_next_d[qreq_wrpointer_q[3:0]].req_type = 4'b1;
        qreq_next_d[qreq_wrpointer_q[3:0]].l1tol2_req = s1_q.l1tol2_req;
        if (ack_rd_llht_data.valid) begin
            qreq_next_d[ack_rd_llht_data.tail[3:0]].next = qreq_wrpointer_q[3:0];
        end
        else begin
            qreq_next_d[qreq_wrpointer_q[3:0]].next = qreq_wrpointer_q[3:0];
        end
    */
        qreq_next_dvalid[s1_q.l1tol2_req.l1id[3:0]] = write_qreq; //assume only the low 4 bits of l1id are used
        qreq_next_d[s1_q.l1tol2_req.l1id[3:0]].valid = 1;
        qreq_next_d[s1_q.l1tol2_req.l1id[3:0]].req_type = 4'b1;
        qreq_next_d[s1_q.l1tol2_req.l1id[3:0]].l1tol2_req = s1_q.l1tol2_req;
        if (ack_rd_llht_data.valid) begin
            qreq_next_d[ack_rd_llht_data.tail[3:0]].next = s1_q.l1tol2_req.l1id[3:0];
        end
        else begin
            qreq_next_d[s1_q.l1tol2_req.l1id[3:0]].next = s1_q.l1tol2_req.l1id[3:0];
        end
        // S1.G+ : update qreq when the winner is from qreq
        if (winner_for_tag == QREQ) begin
            qreq_next_dvalid[winner_in_qreq] = 1;
            qreq_next_d[winner_in_qreq].launched = 1; //TODO: may cause problem with retry chain
        end

        // VS S6.c+: update qreq, mark the req as not ready
        if (final_tag_miss) begin
            qreq_next_dvalid[s6_q.l1tol2_req.l1id[3:0]] = 1;
            qreq_next_d[s6_q.l1tol2_req.l1id[3:0]].ready = 0;
        end

        // VS S7: update qreq, mark the req as invalid
        if (s7_qvalid) begin
            qreq_next_dvalid[s7_q.l1tol2_req.l1id[3:0]] = 1;
            qreq_next_d[s7_q.l1tol2_req.l1id[3:0]].valid = 0;
        end

        // VS l2tlb updates; not a part of S1
        // Update ppaddr, hpaddr and paddr
        qreq_next_dvalid[l2tlbtol2_fwd.l1id[3:0]] = l2tlbtol2_fwd_valid && qreq_next_d[l2tlbtol2_fwd.l1id[3:0]].valid; //assume only the low 4 bits of l1id are used
        qreq_next_d[l2tlbtol2_fwd.l1id[3:0]].l1tol2_req.ppaddr = l2tlbtol2_fwd.paddr[12:10]; // correct ppaddr
        qreq_next_d[l2tlbtol2_fwd.l1id[3:0]].paddr = l2tlbtol2_fwd.paddr;
        qreq_next_d[l2tlbtol2_fwd.l1id[3:0]].hpaddr = l2tlbtol2_fwd.hpaddr;
    end

    //S1.C Update llht
    // VS S7 update llht
    // TODO: send retry to s1 before
    assign  s1_retry_1 = s1_qvalid && s7_qvalid;
    logic   [4:0] new_tail_llht;
    //assign new_tail_llht = qreq_wrpointer_q;
    assign new_tail_llht = s1_q.l1tol2_req.l1id;
    assign req_wr_llht_next_valid = s1_qvalid || s7_qvalid;
    assign req_wr_llht_next_addr = s7_qvalid ? s7_q.l1tol2_req.poffset[11:6] : s1_q.llht_addr;
    // If S7, update the head with the ".next"
    assign req_wr_llht_next_data.head = s7_qvalid ?  {1'b0,qreq_next_d[s7_q.l1tol2_req.l1id[3:0]].next} : (ishead ? new_tail_llht : ack_rd_llht_data.head);
    assign  req_wr_llht_next_data.tail  = s7_qvalid ? ack_rd_llht_data.tail : new_tail_llht;
    // If S7, check whether this is the tail, if so, mark invalid
    assign  req_wr_llht_next_data.valid = (s7_qvalid && (ack_rd_llht_data.tail == s7_q.l1tol2_req.l1id[4:0])) ? 0 : 1;

    /*
    //S1.D Update write pointer
    assign  qreq_wrpointer_next_dvalid = s1_qvalid;
    assign  qreq_wrpointer_next_d = write_qreq ? ( (qreq_wrpointer_q<15) ? 
        (qreq_wrpointer_q + 1) : 0 )
        : qreq_wrpointer_q;
    */

    //S1.E Update counter
    logic   [1:0]   read_vs_write_qreq;
    assign  read_vs_write_qreq = {read_qreq, write_qreq};
    assign  qreq_counter_next_dvalid = s1_qvalid;
    assign  qreq_counter_next_d = (read_vs_write_qreq==2'b01) ? ( qreq_counter_q + 1) :
        ((read_vs_write_qreq==2'b10) ? (qreq_counter_q - 1) : qreq_counter_q);
    assign error1 = qreq_counter_q > 16;

    //S1.F Check ready request in the q_req
    logic   [3:0]   winner_in_qreq;
    logic           has_winner_in_qreq;
    always_comb begin
        winner_in_qreq = 4'bx;
        has_winner_in_qreq = 0;
        for (int j=0; j<=15; j=j+1) begin
            if (qreq_q[j].valid && qreq_q[j].ready && qreq_q[j].ishead && (~qreq_q[j].launched)) begin
                winner_in_qreq = j[3:0]; // TODO: might be buggy
                has_winner_in_qreq = 1;
            end
        end
    end
   
    //S1.G Choose a winner for accessing tag
    // common resource: tag
    localparam NEW_L1TOL2_REQ = 5'b00001;
    localparam QREQ = 5'b00010;
    localparam DRTOL2_ACK = 5'b00100;
    localparam DRTOL2_ACK_WRITE = 5'b01000;
    logic [4:0] winner_for_tag;
    always_comb begin
        winner_for_tag = 0;
        predicted_index = 7'bx;
        // TODO: Any loser should retry
        case (1'b1)
            t2_qvalid: begin // VS T2: drtol2 ack write tag
                winner_for_tag = DRTOL2_ACK_WRITE;
                predicted_index = t2_q.drtol2_snack.paddr[12:6]; // this is not predictted actually
            end
            drtol2_ack: begin //VS T1: drtol2 ack read tag
                winner_for_tag = DRTOL2_ACK;
                predicted_index = drtol2_snack.paddr[12:6]; // this is not predictted actually
            end
            has_winner_in_qreq : begin
                winner_for_tag = QREQ;
                predicted_index = {qreq_q[winner_in_qreq].l1tol2_req.ppaddr[2], qreq_q[winner_in_qreq].l1tol2_req.poffset[11:6]};
            end
            s1_qvalid: begin // new l1tol2 req
                winner_for_tag = NEW_L1TOL2_REQ;
                predicted_index = {s1_q.l1tol2_req.ppaddr[2], s1_q.l1tol2_req.poffset[11:6]};
            end
            default: begin
                winner_for_tag = 0;
                predicted_index = 7'bx;
            end
        endcase
    end
    //assign  new_l1tol2_req_may_go = (~tag_bank0_busy && (tag_bank_id_s0==2'b00)) || (~tag_bank1_busy && (tag_bank_id_s0==2'b01)) 
    //        || (~tag_bank2_busy && (tag_bank_id_s0==2'b10)) || (~tag_bank3_busy && (tag_bank_id_s0==2'b11));
    assign  tag_bank_id = predicted_index[1:0];    
    //S1.H Access tag
    //S1.H.e update and evict tag
    tag_t new_tag;
    logic   found_empty_way;
    logic   [3:0]   empty_way;
    always_comb begin
        new_tag = t2_q.old_tag_content;
        found_empty_way = 0;
        for (int p=0; p<=15; p=p+1) begin
            if ((~t2_q.old_tag_content.valid[p]) && (~found_empty_way)) begin
                found_empty_way = 1;
                empty_way = p[3:0];
            end
        end
        for (int q=0; q<=3; q=q+1) begin
            case (empty_way)
                4'b0: begin tag_req_data_bank[q].valid[0] = 1; tag_req_data_bank[q].hpaddr_way0 = t2_q.drtol2_snack.hpaddr_hash; end
                //TODO: expand all the 16 ways
            endcase
        end
    end
    //S1.H.a Access bank0
    assign  tag_req_valid_bank[0] = (winner_for_tag>0) && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank[0] = (winner_for_tag == DRTOL2_ACK_WRITE) ? 1 : 0;// write or Read tag
    assign  tag_req_pos_bank[0] = predicted_index;
    assign  tag_req_data_bank[0] = t2_q.old_tag_content;
    // Set busy when access tag
    // Reset busy in next state (state2)
    //assign  tag_bank0_busy_next = tag_req_valid_bank[0] ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank0_busy ));


    //S1.H.b Access Bank1
    assign  tag_req_valid_bank[1] = (winner_for_tag>0) && (tag_bank_id == 2'b01);
    assign  tag_req_we_bank[1] = (winner_for_tag == DRTOL2_ACK_WRITE) ? 1 : 0;// write or Read tag
    assign  tag_req_pos_bank[1] = predicted_index;
    // Set busy when access tag
    // Reset busy in next state (state2)
    //assign  tag_bank1_busy_next = tag_req_valid_bank[1] ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank1_busy ));

    //S1.H.c Access Bank2
    assign  tag_req_valid_bank[2] = (winner_for_tag>0) && (tag_bank_id == 2'b10);
    assign  tag_req_we_bank[2] = (winner_for_tag == DRTOL2_ACK_WRITE) ? 1 : 0;// write or Read tag
    assign  tag_req_pos_bank[2] = predicted_index;
    // Set busy when access tag
    // Reset busy in next state (state2)
    //assign  tag_bank2_busy_next = tag_req_valid_bank[2] ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank2_busy ));

    //S1.H.d Access Bank3
    assign  tag_req_valid_bank[3] = (winner_for_tag>0)  && (tag_bank_id == 2'b11);
    assign  tag_req_we_bank[3] = (winner_for_tag == DRTOL2_ACK_WRITE) ? 1 : 0;// write or Read tag
    assign  tag_req_pos_bank[3] = predicted_index;
    // Set busy when access tag
    // Reset busy in next state (state2)
    //assign  tag_bank3_busy_next = tag_req_valid_bank[3] ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank3_busy ));

    //S1.I register fflop for s2
    // S1->S2
    assign  s2_next_dvalid = winner_for_tag>0;
    assign  s2_next_d.l1tol2_req = s1_q.l1tol2_req;
    assign  s2_next_d.hpaddr = qreq_q[winner_in_qreq].hpaddr;
    assign  s2_next_d.winner_for_tag = winner_for_tag;
    assign  s2_next_d.which_bank = tag_bank_id;
    // for drtol2 ack
    assign  s2_next_d.drtol2_snack = drtol2_snack;
    // TODO assign s2_next_d.paddr = ready req's paddr

       // Data bank stage
    //
    /*
    flop #(.Bits()) f_reg_ (
    .clk      (clk),
    .reset    (reset),
    .d        (),
    .q        ()
    );
    */
    
    logic   l1_match_l2tlb_l1id;
    logic   l1_match_l2tlb_ppaddr;
    
    logic   tag_hit;

    logic [3:0]    hit_way;

    /*
    fflop #(.Size($bits(I_l2tlbtol2_fwd_type))) f_l2tlbtol2_fwd_reg1 (
    .clk      (clk),
    .reset    (reset),

    .din      (),
    .dinValid (),
    .dinRetry (),

    .q        (),
    .qValid   (),
    .qRetry   ()
    );
    */
    
    // Signals for Data Bank
    typedef struct packed {
        SC_line_type    line;
        logic [36:0]   tag;
        logic           valid;
    } I_data_bank_line_type;
    localparam  DATA_BANK_WIDTH = $bits(I_data_bank_line_type);
    // Each way can be addressed independantly using the highest 4 bits of Data Bank Index
    localparam  DATA_BANK_SIZE = 16 * 128;
    // Data bank0 to bank3
    logic data_req_valid_bank[4];
    logic data_req_retry_bank[4];
    logic data_req_we_bank[4];
    logic   [`log2(DATA_BANK_SIZE)-1:0]  data_req_pos_bank[4];
    I_data_bank_line_type   data_req_data_bank[4];
    logic   data_ack_valid_bank[4];
    logic   data_ack_retry_bank[4];
    I_data_bank_line_type   data_ack_data_bank[4];
    //logic   data_req_back_press;

    // Instantiate Tag RAM
    // Width = TLB_HPADDRBITS
    // Size = 128 
    // Forward = 0
    // Bank0 Way0
    generate
        genvar k;
        for (k=0; k<=3; k=k+1) begin
            ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank (
                .clk            (clk),
                .reset          (reset),
                
                .req_valid      (tag_req_valid_bank[k]),
                .req_retry      (tag_req_retry_bank[k]),
                .req_we         (tag_req_we_bank[k]),
                .req_pos        (tag_req_pos_bank[k]),
                .req_data       (tag_req_data_bank[k]),

                .ack_valid      (tag_ack_valid_bank[k]),
                .ack_retry      (1'b0),
                //.ack_retry      (tag_ack_retry_bank[0]),
                .ack_data       (tag_ack_data_bank[k])
            );
        end
    endgenerate

    /*
    // Tag bank busy indicator
    // Bank0
    logic   [0:0]  tag_bank0_busy_next;
    logic   [0:0]  tag_bank0_busy;
    flop #(.Bits($bits(tag_bank0_busy))) f_reg_tag_bank0_busy (
    .clk      (clk),
    .reset    (reset),
    .d        (tag_bank0_busy_next),
    .q        (tag_bank0_busy)
    );

    // Bank1
    logic   [0:0]  tag_bank1_busy_next;
    logic   [0:0]  tag_bank1_busy;
    flop #(.Bits($bits(tag_bank1_busy))) f_reg_tag_bank1_busy (
    .clk      (clk),
    .reset    (reset),
    .d        (tag_bank1_busy_next),
    .q        (tag_bank1_busy)
    );

    // Bank2
    logic   [0:0]  tag_bank2_busy_next;
    logic   [0:0]  tag_bank2_busy;
    flop #(.Bits($bits(tag_bank2_busy))) f_reg_tag_bank2_busy (
    .clk      (clk),
    .reset    (reset),
    .d        (tag_bank2_busy_next),
    .q        (tag_bank2_busy)
    );

    // Bank3
    logic   [0:0]  tag_bank3_busy_next;
    logic   [0:0]  tag_bank3_busy;
    flop #(.Bits($bits(tag_bank3_busy))) f_reg_tag_bank3_busy (
    .clk      (clk),
    .reset    (reset),
    .d        (tag_bank3_busy_next),
    .q        (tag_bank3_busy)
    );
    */

    // Instantiate DATA Bank RAM
    generate
        genvar m;
        for (m=0; m<=3; m=m+1) begin
            ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank (
                .clk            (clk),
                .reset          (reset),
                
                .req_valid      (data_req_valid_bank[m]),
                .req_retry      (data_req_retry_bank[m]),
                .req_we         (data_req_we_bank[m]),
                .req_pos        (data_req_pos_bank[m]),
                .req_data       (data_req_data_bank[m]),

                .ack_valid      (data_ack_valid_bank[m]),
                .ack_retry      (1'b0),
                //.ack_retry      (data_ack_retry_bank[0]),
                .ack_data       (data_ack_data_bank[m])
            );
        end
    endgenerate


    // Instantiate q_l1tol2_req
    localparam  Q_L1TOL2_REQ_WIDTH = ($bits(I_q_l1tol2_req_type) ); // The extra 1 bit is for ppaddr_corrected
    localparam  Q_L1TOL2_REQ_SIZE = 8;
    logic                   req_wr_q_l1tol2_req_valid;
    logic                   req_wr_q_l1tol2_req_retry;
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] req_wr_q_l1tol2_req_addr;
    I_q_l1tol2_req_type     req_wr_q_l1tol2_req_data;

    logic                   req_rd_q_l1tol2_req_valid;
    logic                   req_rd_q_l1tol2_req_retry;
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] req_rd_q_l1tol2_req_addr;

    logic                   ack_rd_q_l1tol2_req_valid;
    logic                   ack_rd_q_l1tol2_req_retry;
    I_q_l1tol2_req_type     ack_rd_q_l1tol2_req_data;

    // qzhang33
    // Instantiate q_l1tol2_req_hpaddr_miss
    localparam  Q_L1TOL2_REQ_HPADDR_WIDTH = ($bits(I_q_l1tol2_req_hpaddr_miss_type) ); // The extra 1 bit is for next
    localparam  Q_L1TOL2_REQ_HPADDR_SIZE = 16;
    logic                   req_wr_q_l1tol2_req_hpaddr_miss_valid;
    logic                   req_wr_q_l1tol2_req_hpaddr_miss_retry;
    logic           [`log2(Q_L1TOL2_REQ_HPADDR_SIZE)-1 : 0] req_wr_q_l1tol2_req_hpaddr_miss_addr;
    I_q_l1tol2_req_hpaddr_miss_type     req_wr_q_l1tol2_req_hpaddr_miss_data;

    logic                   req_rd_q_l1tol2_req_hpaddr_miss_valid;
    logic                   req_rd_q_l1tol2_req_hpaddr_miss_retry;
    logic           [`log2(Q_L1TOL2_REQ_HPADDR_SIZE)-1 : 0] req_rd_q_l1tol2_req_hpaddr_miss_addr;

    logic                   ack_rd_q_l1tol2_req_hpaddr_miss_valid;
    logic                   ack_rd_q_l1tol2_req_hpaddr_miss_retry;
    I_q_l1tol2_req_hpaddr_miss_type     ack_rd_q_l1tol2_req_hpaddr_miss_data;

    // Instantiate q_l1tol2_req_linked_list
    localparam  Q_LINKED_LIST_WIDTH = ($bits(I_q_l1tol2_req_linked_list_type) ); 
    localparam  Q_LINKED_LIST_SIZE = 64;
    logic                   req_wr_q_l1tol2_req_linked_list_valid;
    logic                   req_wr_q_l1tol2_req_linked_list_retry;
    logic           [`log2(Q_LINKED_LIST_SIZE)-1 : 0]        req_wr_q_l1tol2_req_linked_list_addr;
    I_q_l1tol2_req_linked_list_type     req_wr_q_l1tol2_req_linked_list_data;

    logic                   req_rd_q_l1tol2_req_linked_list_valid;
    logic                   req_rd_q_l1tol2_req_linked_list_retry;
    logic           [`log2(Q_LINKED_LIST_SIZE)-1 : 0]        req_rd_q_l1tol2_req_linked_list_addr;

    logic                   ack_rd_q_l1tol2_req_linked_list_valid;
    logic                   ack_rd_q_l1tol2_req_linked_list_retry;
    I_q_l1tol2_req_linked_list_type     ack_rd_q_l1tol2_req_linked_list_data;
    // qzhang33

    ram_2port_fast #(.Width(Q_L1TOL2_REQ_WIDTH), .Size(Q_L1TOL2_REQ_SIZE), .Forward(0))  q_l1tol2_req (
        .clk            (clk),
        .reset          (reset),
        
        .req_wr_valid   (req_wr_q_l1tol2_req_valid),
        .req_wr_retry   (req_wr_q_l1tol2_req_retry),
        .req_wr_addr    (req_wr_q_l1tol2_req_addr),
        .req_wr_data    (req_wr_q_l1tol2_req_data),

        .req_rd_valid   (req_rd_q_l1tol2_req_valid),
        .req_rd_retry   (req_rd_q_l1tol2_req_retry),
        .req_rd_addr    (req_rd_q_l1tol2_req_addr),

        .ack_rd_valid   (ack_rd_q_l1tol2_req_valid),
        .ack_rd_retry   (1'b0),
        //.ack_rd_retry   (ack_rd_q_l1tol2_req_retry),
        .ack_rd_data    (ack_rd_q_l1tol2_req_data)
    );

    // qzhang33
    ram_2port_fast #(.Width(Q_L1TOL2_REQ_HPADDR_WIDTH), .Size(Q_L1TOL2_REQ_HPADDR_SIZE), .Forward(0))  q_l1tol2_req_hpaddr_miss (
        .clk            (clk),
        .reset          (reset),
        
        .req_wr_valid   (req_wr_q_l1tol2_req_hpaddr_miss_valid),
        .req_wr_retry   (req_wr_q_l1tol2_req_hpaddr_miss_retry),
        .req_wr_addr    (req_wr_q_l1tol2_req_hpaddr_miss_addr),
        .req_wr_data    (req_wr_q_l1tol2_req_hpaddr_miss_data),

        .req_rd_valid   (req_rd_q_l1tol2_req_hpaddr_miss_valid),
        .req_rd_retry   (req_rd_q_l1tol2_req_hpaddr_miss_retry),
        .req_rd_addr    (req_rd_q_l1tol2_req_hpaddr_miss_addr),

        .ack_rd_valid   (ack_rd_q_l1tol2_req_hpaddr_miss_valid),
        .ack_rd_retry   (1'b0),
        //.ack_rd_retry   (ack_rd_q_l1tol2_req_hpaddr_miss_retry),
        .ack_rd_data    (ack_rd_q_l1tol2_req_hpaddr_miss_data)
    );

    ram_2port_fast #(.Width(Q_LINKED_LIST_WIDTH), .Size(Q_LINKED_LIST_SIZE), .Forward(0))  q_l1tol2_req_linked_list (
        .clk            (clk),
        .reset          (reset),
        
        .req_wr_valid   (req_wr_q_l1tol2_req_linked_list_valid),
        .req_wr_retry   (req_wr_q_l1tol2_req_linked_list_retry),
        .req_wr_addr    (req_wr_q_l1tol2_req_linked_list_addr),
        .req_wr_data    (req_wr_q_l1tol2_req_linked_list_data),

        .req_rd_valid   (req_rd_q_l1tol2_req_linked_list_valid),
        .req_rd_retry   (req_rd_q_l1tol2_req_linked_list_retry),
        .req_rd_addr    (req_rd_q_l1tol2_req_linked_list_addr),

        .ack_rd_valid   (ack_rd_q_l1tol2_req_linked_list_valid),
        .ack_rd_retry   (1'b0),
        //.ack_rd_retry   (ack_rd_q_l1tol2_req_linked_list_retry),
        .ack_rd_data    (ack_rd_q_l1tol2_req_linked_list_data)
    );
    // qzhang33 

    /*
    ram_2port_fast #(.Width(), .Size(), .Forward()) (
        .clk            (),
        .reset          (),
        
        .req_wr_valid   (),
        .req_wr_retry   (),
        .req_wr_addr    (),
        .req_wr_data    (),

        .req_rd_valid   (),
        .req_rd_retry   (),
        .req_rd_addr    (),

        .ack_rd_valid   (),
        .ack_rd_retry   (),
        .ack_rd_data    ()
    ); 

    */
    
    //&& (!l1tol2_req_retry);

    /*
    * assign  l1tol2_req_retry =  (tag_req_valid_bank[0] && tag_req_retry_bank[0]) ||

                                (tag_req_valid_bank[1] && tag_req_retry_bank[1]) ||

                                (tag_req_valid_bank[2] && tag_req_retry_bank[2]) ||

                                (tag_req_valid_bank[3] && tag_req_retry_bank[3]);
    */


    // S2:  Access Tag 1
    //      And Handle input from l2tlb; *could arrive at any time
    // S2.A: Check if arrive on time
    always_comb begin
        l1_match_l2tlb_l1id = 0;
        l1_match_l2tlb_ppaddr = 0;
        if (l2tlbtol2_fwd_valid) begin
            if (s2_qvalid) begin
                // If l2tlb send a packet on time
                if (s2_q.winner_for_tag == NEW_L1TOL2_REQ) begin
                    // Compare l1_id
                    if (s2_q.l1tol2_req.l1id == l2tlbtol2_fwd.l1id) begin
                        // l1id match
                        l1_match_l2tlb_l1id = 1;
                    end
                    // verify ppaddr
                    if (l2tlbtol2_fwd.paddr[12] == s2_q.l1tol2_req.ppaddr[2]) begin// For 128
                        // ppaddr is correct
                        l1_match_l2tlb_ppaddr = 1;
                    end
                    //else ppaddr is incorrect
                end
            end 
        end
    end

    // S2.B: register fflop for s3
    // S2->S3
    assign  s3_next_dvalid = s2_qvalid;
    assign  s3_next_d.winner_for_tag = s2_q.winner_for_tag;
    assign  s3_next_d.l1tol2_req = s2_q.l1tol2_req;
    assign  s3_next_d.l1_match_l2tlb_l1id = l1_match_l2tlb_l1id;
    assign  s3_next_d.l1_match_l2tlb_ppaddr = l1_match_l2tlb_ppaddr;
    assign  s3_next_d.paddr = (l1_match_l2tlb_l1id && l1_match_l2tlb_ppaddr) ? l2tlbtol2_fwd.paddr : s2_q.paddr;
    assign  s3_next_d.hpaddr = (l1_match_l2tlb_l1id && l1_match_l2tlb_ppaddr) ? l2tlbtol2_fwd.hpaddr : s2_q.hpaddr;
    assign  s3_next_d.which_bank = s2_q.which_bank;
    // for drtol2 ack
    assign  s3_next_d.drtol2_snack = drtol2_snack;

    // S3: Tag Access_2
    // S3.A: extract hpaddr from tag read
    /*
    TLB_hpaddr_type  hpaddr_from_tag[16];
    assign {hpaddr_from_tag[0], hpaddr_from_tag[1], hpaddr_from_tag[2], hpaddr_from_tag[3],
            hpaddr_from_tag[4], hpaddr_from_tag[5], hpaddr_from_tag[6], hpaddr_from_tag[7],
            hpaddr_from_tag[8], hpaddr_from_tag[9], hpaddr_from_tag[10], hpaddr_from_tag[11],
            hpaddr_from_tag[12], hpaddr_from_tag[13], hpaddr_from_tag[14], hpaddr_from_tag[15]
            } = tag_ack_data_bank[s3_q.which_bank];// TODO extract hpaddr
    */
    assign  tag_ack_valid_banks_ways = tag_ack_valid_bank[0] | tag_ack_valid_bank[1] | tag_ack_valid_bank[2] | tag_ack_valid_bank[3];

    // S3.B: Handle tag result
    always_comb begin
        tag_hit = 0;
        hit_way = 4'bx;
        if (s3_qvalid) begin
        // Tag access result is ready
        // Could be l1tol2 access or DRTOL2_ACK
            if (((s3_q.l1_match_l2tlb_l1id && s3_q.l1_match_l2tlb_ppaddr) || (s3_q.winner_for_tag==DRTOL2_ACK)) && tag_ack_valid_banks_ways) begin
            // l1id matched and ppaddr is correct
                case (1'b1)
                    // Check way0
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way0 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0000;
                    end
                    // Check way1
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way1 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0001;
                    end
                    // Check way2
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way2 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0010;
                    end
                    // Check way3
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way3 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0011;
                    end
                    // Check way4
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way4 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0100;
                    end
                    // Check way5
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way5 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0101;
                    end
                    // Check way6
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way6 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0110;
                    end
                    // Check way7
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way7 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b0111;
                    end
                    // Check way8
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way8 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1000;
                    end
                    // Check way9
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way9 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1001;
                    end
                    // Check way10
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way10 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1010;
                    end
                    // Check way11
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way11 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1011;
                    end
                    // Check way12
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way12 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1100;
                    end
                    // Check way13
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way13 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1101;
                    end
                    // Check way14
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way14 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1110;
                    end
                    // Check way15
                    ((tag_ack_data_bank[s3_q.which_bank].hpaddr_way15 == s3_q.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit = 1;
                        hit_way = 4'b1111;
                    end
                endcase
            end
        end
    end

    // S3.C: Handle tag miss
    assign  tag_miss = (~tag_hit) && tag_ack_valid_banks_ways;
    // S3.C+: Send l2todr_req if miss
    
    // qzhang33

    // S3->S4
    assign  s4_next_dvalid = s3_qvalid && tag_hit && (s3_q.winner_for_tag==NEW_L1TOL2_REQ || s3_q.winner_for_tag==QREQ);
    assign  s4_next_d.winner_for_tag = s3_q.winner_for_tag;
    assign  s4_next_d.l1tol2_req = s3_q.l1tol2_req;
    assign  s4_next_d.tag_hit = tag_hit;
    assign  s4_next_d.tag_miss = tag_miss;
    assign  s4_next_d.hit_way = hit_way;
    assign  s4_next_d.paddr = s3_q.paddr;
    assign  s4_next_d.which_bank = s3_q.which_bank;
    assign  s4_next_d.hpaddr = s3_q.hpaddr;

    // S3->T2
    assign  t2_next_dvalid = s3_qvalid && (s3_q.winner_for_tag==DRTOL2_ACK) &&
            tag_ack_valid_bank[s3_q.which_bank];
    assign  t2_next_d.winner_for_tag = s3_q.winner_for_tag;
    assign  t2_next_d.drtol2_snack = s3_q.drtol2_snack;
    assign  t2_next_d.old_tag_content = tag_ack_data_bank[s3_q.which_bank];

    // Enter next pipe stage: s4_qvalid when tag hit

    // Access data bank under tag hit
    // S4: Data Access 0
    // S4.A: Initiate data access
    assign  data_req_valid = data_req_valid_bank[0] || data_req_valid_bank[1] || data_req_valid_bank[2] || data_req_valid_bank[3];
    assign  data_req_valid_bank[0] = (s4_q.l1tol2_req.poffset[7:6]==2'b00) && s4_qvalid && s4_q.tag_hit;
    assign  data_req_we_bank[0] = (s4_q.l1tol2_req.poffset[7:6]==2'b00) && s4_qvalid ? 0 : 0; // read
    assign  data_req_pos_bank[0] = {s4_q.hit_way, s4_q.l1tol2_req.ppaddr[2], s4_q.l1tol2_req.poffset[11:6]};
   
    assign  data_req_valid_bank[1] = (s4_q.l1tol2_req.poffset[7:6]==2'b00) && s4_qvalid && s4_q.tag_hit;
    assign  data_req_we_bank[1] = (s4_q.l1tol2_req.poffset[7:6]==2'b01) && s4_qvalid ? 0 : 0; // read
    assign  data_req_pos_bank[1] = {s4_q.hit_way, s4_q.l1tol2_req.ppaddr[2], s4_q.l1tol2_req.poffset[11:6]};
   
    assign  data_req_valid_bank[2] = (s4_q.l1tol2_req.poffset[7:6]==2'b10) && s4_qvalid && s4_q.tag_hit;
    assign  data_req_we_bank[2] = (s4_q.l1tol2_req.poffset[7:6]==2'b10) && s4_qvalid ? 0 : 0; // read
    assign  data_req_pos_bank[2] = {s4_q.hit_way, s4_q.l1tol2_req.ppaddr[2], s4_q.l1tol2_req.poffset[11:6]};
   
    assign  data_req_valid_bank[3] = (s4_q.l1tol2_req.poffset[7:6]==2'b00) && s4_qvalid && s4_q.tag_hit;
    assign  data_req_we_bank[3] = (s4_q.l1tol2_req.poffset[7:6]==2'b11) && s4_qvalid ? 0 : 0; // read
    assign  data_req_pos_bank[3] = {s4_q.hit_way, s4_q.l1tol2_req.ppaddr[2], s4_q.l1tol2_req.poffset[11:6]};
  
    // S4->S5
    assign  s5_next_d.winner_for_tag = s4_q.winner_for_tag;
    assign  s5_next_dvalid = s4_qvalid && data_req_valid;
    assign  s5_next_d.paddr = s4_q.paddr;
    assign  s5_next_d.hit_way = s4_q.hit_way;
    assign  s5_next_d.l1tol2_req = s4_q.l1tol2_req;
    assign  s5_next_d.which_bank = s4_q.which_bank;
    assign  s5_next_d.hpaddr = s4_q.hpaddr;

    // S5->S6
    assign  s6_next_d.winner_for_tag = s5_q.winner_for_tag;
    assign  s6_next_dvalid = s5_qvalid && data_req_valid;
    assign  s6_next_d.paddr = s5_q.paddr;
    assign  s6_next_d.hit_way = s5_q.hit_way;
    assign  s6_next_d.l1tol2_req = s5_q.l1tol2_req;
    assign  s6_next_d.which_bank = s5_q.which_bank;
    assign  s6_next_d.hpaddr = s5_q.hpaddr;

    // S6: Handle data access result
    // S6.A Verify full tag was correct:
    //      yes:    Send l2tol1_snack
    //      no:     reflow
    assign  final_tag_hit = s6_qvalid && data_ack_valid_bank[s6_q.which_bank] && (s6_q.paddr[49:13] == data_ack_data_bank[s6_q.which_bank].tag);
    assign  final_tag_miss =  s6_qvalid && data_ack_valid_bank[s6_q.which_bank] && (s6_q.paddr[49:13] != data_ack_data_bank[s6_q.which_bank].tag);

    // S6.B: Send l2tol1 ack on a hit
    // (S6.B+: Read llht)
    logic l2tol1_snack_next_valid;
    logic l2tol1_snack_next_retry;
    I_l2tol1_snack_type l2tol1_snack_next;
    assign l2tol1_snack_next_valid = final_tag_hit; // TODO: may need to check whether this is a request from l1
    always_comb begin
        if (l2tol1_snack_next_valid) begin
            l2tol1_snack_next.l1id = s6_q.l1tol2_req.l1id;
            l2tol1_snack_next.l2id = 0; // indicates this is an ack
            case (s6_q.l1tol2_req.cmd)
                `SC_CMD_REQ_S:   l2tol1_snack_next.snack = `SC_SCMD_ACK_S;
                `SC_CMD_REQ_M:   l2tol1_snack_next.snack = `SC_SCMD_ACK_M;
                `SC_CMD_REQ_NC:  l2tol1_snack_next.snack = `SC_SCMD_ACK_OTHERI;
                `SC_CMD_DRAINI:  l2tol1_snack_next.snack = `SC_SCMD_ACK_OTHERI;
            endcase
            l2tol1_snack_next.line = data_ack_data_bank[s6_q.which_bank].line;
            l2tol1_snack_next.poffset = s6_q.l1tol2_req.poffset;
            l2tol1_snack_next.hpaddr = s6_q.hpaddr;
        end
    end

    // S6.C: Send l2todr_req on a miss
    // (S6.c+: update qreq, mark the req as not ready)
    // VS S3.C+: Handle tag miss
    // If S6 conflict with S3, S3 needs to retry
    assign   s3_qretry_1 = final_tag_miss && (tag_miss && s3_qvalid);
    assign  l2todr_req_next_valid = final_tag_miss || (tag_miss && s3_qvalid);
    always_comb begin
        if (l2todr_req_next_valid) begin
            l2todr_req_next.nid = 5'b00000; // TODO: Could be wrong
            l2todr_req_next.l2id = final_tag_miss ? {1'b0, s6_q.l1tol2_req.l1id} : {1'b0 , s3_q.l1tol2_req.l1id}; // Don't use the msb
            l2todr_req_next.cmd = final_tag_miss? s6_q.l1tol2_req.cmd : s3_q.l1tol2_req.cmd ; // TODO: double check with Jose
            l2todr_req_next.paddr = final_tag_miss ? s6_q.paddr : s3_q.paddr;
        end
    end


    // S6->S7
    assign  s7_next_dvalid = final_tag_hit;
    assign  s7_next_d.l1tol2_req = s6_q.l1tol2_req;

    //S7 update llht

    // T1: drtol2 ack read tag
    

`endif
endmodule



