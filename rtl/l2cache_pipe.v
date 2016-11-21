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

`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
    assign l2todr_req_next_valid = l1tol2_req_valid;
    assign  l1tol2_req_retry = l2todr_req_next_retry;

    // Temp drive Begin
    //assign l1tol2_pfreq_retry = 0;
    //assign pftol2_pfreq_retry = 0;
    assign cachetopf_stats = 0;
    assign drtol2_dack_retry = 0;
    assign l2tlbtol2_fwd_retry = 0;
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
`endif

// -> drtol2_snack
// l2tol1_snack ->
`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
    logic l2tol1_snack_next_valid;
    logic l2tol1_snack_next_retry;
    I_l2tol1_snack_type l2tol1_snack_next;
    assign l2tol1_snack_next_valid = drtol2_snack_valid;
    assign drtol2_snack_retry = l2tol1_snack_next_retry;
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
    assign l2tlbtol2_fwd_retry = l2todr_pfreq_next_retry;
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
    logic l2todr_disp_next_valid;
    assign l2todr_disp_next_valid = l1tol2_disp_valid;
    logic l2todr_disp_next_retry;
    assign l1tol2_disp_retry = l2todr_disp_next_retry | l2tol1_dack_next_retry; // Note this is BUGGYYYYY!
    I_l2todr_disp_type l2todr_disp_next;
    always_comb begin
        if (l2todr_disp_next_valid) begin
            l2todr_disp_next.nid =  {5{1'b0}};
            l2todr_disp_next.l2id = l1tol2_disp.l2id;
            l2todr_disp_next.drid =  {6{1'b0}};
            l2todr_disp_next.mask = l1tol2_disp.mask;
            l2todr_disp_next.dcmd = l1tol2_disp.dcmd;
            l2todr_disp_next.line = l1tol2_disp.line;
            l2todr_disp_next.paddr = {{35{1'b0}},
                l1tol2_disp.ppaddr,
                {12{1'b0}}}; //35 + 3bit + 12bit
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

`ifdef L2_PASSTHROUGH
    `ifndef L2_COMPLETE
// (1) -> l1tol2_disp
// (2) l2todr_disp ->
// (2) l2tol1_dack ->
    logic l2tol1_dack_next_valid;
    assign l2tol1_dack_next_valid = l1tol2_disp_valid;
    logic l2tol1_dack_next_retry;
    I_l2tol1_dack_type l2tol1_dack_next;
    always_comb begin
        if (l2tol1_dack_next_valid) begin
            l2tol1_dack_next.l1id =  l1tol2_disp.l1id;
        end
    end

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
        I_l1tol2_req_type          l1tol2_req;
        logic                      next;
    } I_q_l1tol2_req_hpaddr_miss_type;

    typedef struct packed {
        logic    [3:0]           head;
        logic    [3:0]           tail;
    } I_q_l1tol2_req_linked_list_type;
    // qzhang33

    // Control regs
    // reg_new_l1tol2_req_tag_access_0
    logic   reg_new_l1tol2_req_tag_access_0;
    logic   reg_new_l1tol2_req_tag_access_0_next;
    logic   reg_new_l1tol2_req_tag_access_1;
    logic   reg_new_l1tol2_req_tag_access_1_next;
    logic   reg_new_l1tol2_req_tag_access_2;
    logic   reg_new_l1tol2_req_tag_access_2_next;

    flop #(.Bits(1)) f_reg_new_l1tol2_req_tag_access_0 (
    .clk      (clk),
    .reset    (reset),
    
    .d      (reg_new_l1tol2_req_tag_access_0_next),

    .q        (reg_new_l1tol2_req_tag_access_0)
    //.qRetry   (reg_new_l1tol2_req_tag_access_0_valid)

    );
    flop #(.Bits(1)) f_reg_new_l1tol2_req_tag_access_1 (
    .clk      (clk),
    .reset    (reset),
    .d        (reg_new_l1tol2_req_tag_access_1_next),
    .q        (reg_new_l1tol2_req_tag_access_1)
    );
    flop #(.Bits(1)) f_reg_new_l1tol2_req_tag_access_2 (
    .clk      (clk),
    .reset    (reset),
    .d        (reg_new_l1tol2_req_tag_access_2_next),
    .q        (reg_new_l1tol2_req_tag_access_2)
    );

    // Data bank stage
    logic   reg_new_l1tol2_req_data_access_0;
    logic   reg_new_l1tol2_req_data_access_0_next;
    flop #(.Bits(1)) f_reg_new_l1tol2_data_access_0 (
    .clk      (clk),
    .reset    (reset),
    .d        (reg_new_l1tol2_req_data_access_0_next),
    .q        (reg_new_l1tol2_req_data_access_0)
    );

    logic   reg_new_l1tol2_req_data_access_1;
    logic   reg_new_l1tol2_req_data_access_1_next;
    flop #(.Bits(1)) f_reg_new_l1tol2_data_access_1 (
    .clk      (clk),
    .reset    (reset),
    .d        (reg_new_l1tol2_req_data_access_1_next),
    .q        (reg_new_l1tol2_req_data_access_1)
    );

    logic   reg_new_l1tol2_req_data_access_2;
    logic   reg_new_l1tol2_req_data_access_2_next;
    flop #(.Bits(1)) f_reg_new_l1tol2_data_access_2 (
    .clk      (clk),
    .reset    (reset),
    .d        (reg_new_l1tol2_req_data_access_2_next),
    .q        (reg_new_l1tol2_req_data_access_2)
    );


    //
    /*
    flop #(.Bits()) f_reg_ (
    .clk      (clk),
    .reset    (reset),
    .d        (),
    .q        ()
    );
    */
    
    logic   l1_match_l2tlb_l1id_next;
    logic   l1_match_l2tlb_ppaddr_next;
    logic   l1_match_l2tlb_l1id;
    logic   l1_match_l2tlb_ppaddr;
    flop #(.Bits(1)) f_reg_l1_match_l2tlb_l1id (
    .clk      (clk),
    .reset    (reset),
    .d        (l1_match_l2tlb_l1id_next),
    .q        (l1_match_l2tlb_l1id)
    );

    flop #(.Bits(1)) f_reg_l1_match_l2tlb_ppaddr (
    .clk      (clk),
    .reset    (reset),
    .d        (l1_match_l2tlb_ppaddr_next),
    .q        (l1_match_l2tlb_ppaddr)
    );
    
    logic   tag_hit_next;
    logic   tag_hit;
    flop #(.Bits(1)) f_reg_tag_hit (
    .clk      (clk),
    .reset    (reset),
    .d        (tag_hit_next),
    .q        (tag_hit)
    );

    logic [3:0]    hit_way_next;
    logic [3:0]    hit_way;

    flop #(.Bits(4)) f_reg_hit_way (
    .clk      (clk),
    .reset    (reset),
    .d        (hit_way_next),
    .q        (hit_way)
    );

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
    // Data path pipe regs
    // Register l1tol2_req
    I_l1tol2_req_type   l1tol2_req_reg1;
    logic   l1tol2_req_reg1_valid;
    logic   l1tol2_req_reg1_retry;
    fflop #(.Size($bits(I_l1tol2_req_type))) f_l1tol2_req_reg1 (
    .clk      (clk),
    .reset    (reset),

    .din      (l1tol2_req),
    .dinValid (l1tol2_req_valid),
    .dinRetry (l1tol2_req_retry),

    .q        (l1tol2_req_reg1),
    .qValid   (l1tol2_req_reg1_valid),
    .qRetry     (1'b0)
    //.qRetry   (l1tol2_req_reg1_retry)
    );

    I_l1tol2_req_type   l1tol2_req_reg2;
    logic   l1tol2_req_reg2_valid;
    logic   l1tol2_req_reg2_retry;
    fflop #(.Size($bits(I_l1tol2_req_type))) f_l1tol2_req_reg2 (
    .clk      (clk),
    .reset    (reset),

    .din      (l1tol2_req_reg1),
    .dinValid (l1tol2_req_reg1_valid),
    .dinRetry (l1tol2_req_reg1_retry),

    .q        (l1tol2_req_reg2),
    .qValid   (l1tol2_req_reg2_valid),
    .qRetry (1'b0)
    //.qRetry   (l1tol2_req_reg2_retry)
    );

    I_l1tol2_req_type   l1tol2_req_reg3;
    logic   l1tol2_req_reg3_valid;
    logic   l1tol2_req_reg3_retry;
    fflop #(.Size($bits(I_l1tol2_req_type))) f_l1tol2_req_reg3 (
    .clk      (clk),
    .reset    (reset),

    .din      (l1tol2_req_reg2),
    .dinValid (l1tol2_req_reg2_valid),
    .dinRetry (l1tol2_req_reg2_retry),

    .q        (l1tol2_req_reg3),
    .qValid   (l1tol2_req_reg3_valid),
    .qRetry     (1'b0)
    //.qRetry   (l1tol2_req_reg3_retry)
    );

    I_l1tol2_req_type   l1tol2_req_reg4;
    logic   l1tol2_req_reg4_valid;
    logic   l1tol2_req_reg4_retry;
    fflop #(.Size($bits(I_l1tol2_req_type))) f_l1tol2_req_reg4 (
    .clk      (clk),
    .reset    (reset),

    .din      (l1tol2_req_reg3),
    .dinValid (l1tol2_req_reg3_valid),
    .dinRetry (l1tol2_req_reg3_retry),

    .q        (l1tol2_req_reg4),
    .qValid   (l1tol2_req_reg4_valid),
    .qRetry     (1'b0)
    //.qRetry   (l1tol2_req_reg4_retry)
    );


    // Register l2tlbtol2_fwd
    I_l2tlbtol2_fwd_type    l2tlbtol2_fwd_reg1;
    logic   l2tlbtol2_fwd_reg1_valid;
    logic   l2tlbtol2_fwd_reg1_retry;
    fflop #(.Size($bits(I_l2tlbtol2_fwd_type))) f_l2tlbtol2_fwd_reg1 (
    .clk      (clk),
    .reset    (reset),

    .din      (l2tlbtol2_fwd),
    .dinValid (l2tlbtol2_fwd_valid),
    .dinRetry (l2tlbtol2_fwd_retry),

    .q        (l2tlbtol2_fwd_reg1),
    .qValid   (l2tlbtol2_fwd_reg1_valid),
    .qRetry     (1'b0)
    //.qRetry   (l2tlbtol2_fwd_reg1_retry)
    );

    // Nothing blocks the second cycle of tag access
    assign  reg_new_l1tol2_req_tag_access_1_next = reg_new_l1tol2_req_tag_access_0;
    assign  reg_new_l1tol2_req_tag_access_2_next = reg_new_l1tol2_req_tag_access_1;

    // Signals for tag
    // Each tag "line" contains all 16 ways 
    localparam  TAG_WIDTH = (16 * `TLB_HPADDRBITS);
    localparam  TAG_SIZE = 128;
    logic   [1:0]   tag_bank_id_s0;
    logic   [6:0]  predicted_index_s0;
    logic   [1:0]   tag_bank_id_s1;
    logic   [6:0]  predicted_index_s1;
    // bank0
    // way0 to way15
    logic tag_req_valid_bank0_ways;
    logic tag_req_retry_bank0_ways;
    logic tag_req_we_bank0_ways;
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank0_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank0_ways;
    logic   tag_ack_valid_bank0_ways;
    logic   tag_ack_retry_bank0_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank0_ways;

    // bank1
    // way0 to way15
    logic tag_req_valid_bank1_ways;
    logic tag_req_retry_bank1_ways;
    logic tag_req_we_bank1_ways;
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank1_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank1_ways;
    logic   tag_ack_valid_bank1_ways;
    logic   tag_ack_retry_bank1_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank1_ways;

    // bank2
    // way0 to way15
    logic tag_req_valid_bank2_ways;
    logic tag_req_retry_bank2_ways;
    logic tag_req_we_bank2_ways;
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank2_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank2_ways;
    logic   tag_ack_valid_bank2_ways;
    logic   tag_ack_retry_bank2_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank2_ways;

    // bank3
    // way0 to way15
    logic tag_req_valid_bank3_ways;
    logic tag_req_retry_bank3_ways;
    logic tag_req_we_bank3_ways;
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank3_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank3_ways;
    logic   tag_ack_valid_bank3_ways;
    logic   tag_ack_retry_bank3_ways;
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank3_ways;


    // Signals for Data Bank
    typedef struct packed {
        SC_line_type    line;
        SC_paddr_type   paddr;
        logic           valid;
    } I_data_bank_line_type;
    localparam  DATA_BANK_WIDTH = $bits(I_data_bank_line_type);
    // Each way can be addressed independantly using the highest 4 bits of Data Bank Index
    localparam  DATA_BANK_SIZE = 16 * 128;
    // Data bank0
    logic data_req_valid_bank0_way;
    logic data_req_retry_bank0_way;
    logic data_req_we_bank0_way;
    logic   [`log2(DATA_BANK_SIZE)-1:0]  data_req_pos_bank0_way;
    I_data_bank_line_type   data_req_data_bank0_way;
    logic   data_ack_valid_bank0_way;
    logic   data_ack_retry_bank0_way;
    I_data_bank_line_type   data_ack_data_bank0_way;
    logic   data_req_back_press;

    // Data bank1
    logic data_req_valid_bank1_way;
    logic data_req_retry_bank1_way;
    logic data_req_we_bank1_way;
    logic   [`log2(DATA_BANK_SIZE)-1:0]  data_req_pos_bank1_way;
    I_data_bank_line_type   data_req_data_bank1_way;
    logic   data_ack_valid_bank1_way;
    logic   data_ack_retry_bank1_way;
    I_data_bank_line_type   data_ack_data_bank1_way;

    // Data bank2
    logic data_req_valid_bank2_way;
    logic data_req_retry_bank2_way;
    logic data_req_we_bank2_way;
    logic   [`log2(DATA_BANK_SIZE)-1:0]  data_req_pos_bank2_way;
    I_data_bank_line_type   data_req_data_bank2_way;
    logic   data_ack_valid_bank2_way;
    logic   data_ack_retry_bank2_way;
    I_data_bank_line_type   data_ack_data_bank2_way;

    // Data bank3
    logic data_req_valid_bank3_way;
    logic data_req_retry_bank3_way;
    logic data_req_we_bank3_way;
    logic   [`log2(DATA_BANK_SIZE)-1:0]  data_req_pos_bank3_way;
    I_data_bank_line_type   data_req_data_bank3_way;
    logic   data_ack_valid_bank3_way;
    logic   data_ack_retry_bank3_way;
    I_data_bank_line_type   data_ack_data_bank3_way;


    // Instantiate Tag RAM
    // Width = TLB_HPADDRBITS
    // Size = 128 
    // Forward = 0
    // Bank0 Way0
    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_ways (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_ways),
        .req_retry      (tag_req_retry_bank0_ways),
        .req_we         (tag_req_we_bank0_ways),
        .req_pos        (tag_req_pos_bank0_ways),
        .req_data       (tag_req_data_bank0_ways),

        .ack_valid      (tag_ack_valid_bank0_ways),
        .ack_retry      (1'b0),
        //.ack_retry      (tag_ack_retry_bank0_ways),
        .ack_data       (tag_ack_data_bank0_ways)
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_ways (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_ways),
        .req_retry      (tag_req_retry_bank1_ways),
        .req_we         (tag_req_we_bank1_ways),
        .req_pos        (tag_req_pos_bank1_ways),
        .req_data       (tag_req_data_bank1_ways),

        .ack_valid      (tag_ack_valid_bank1_ways),
        .ack_retry      (1'b0),
        //.ack_retry      (tag_ack_retry_bank1_ways),
        .ack_data       (tag_ack_data_bank1_ways)
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_ways (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_ways),
        .req_retry      (tag_req_retry_bank2_ways),
        .req_we         (tag_req_we_bank2_ways),
        .req_pos        (tag_req_pos_bank2_ways),
        .req_data       (tag_req_data_bank2_ways),

        .ack_valid      (tag_ack_valid_bank2_ways),
        .ack_retry      (1'b0),
        //.ack_retry      (tag_ack_retry_bank2_ways),
        .ack_data       (tag_ack_data_bank2_ways)
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_ways (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_ways),
        .req_retry      (tag_req_retry_bank3_ways),
        .req_we         (tag_req_we_bank3_ways),
        .req_pos        (tag_req_pos_bank3_ways),
        .req_data       (tag_req_data_bank3_ways),

        .ack_valid      (tag_ack_valid_bank3_ways),
        .ack_retry      (1'b0),
        //.ack_retry      (tag_ack_retry_bank3_ways),
        .ack_data       (tag_ack_data_bank3_ways)
    );

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


    // Instantiate Bank RAM
    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way),
        .req_retry      (data_req_retry_bank0_way),
        .req_we         (data_req_we_bank0_way),
        .req_pos        (data_req_pos_bank0_way),
        .req_data       (data_req_data_bank0_way),

        .ack_valid      (data_ack_valid_bank0_way),
        .ack_retry      (1'b0),
        //.ack_retry      (data_ack_retry_bank0_way),
        .ack_data       (data_ack_data_bank0_way)
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way),
        .req_retry      (data_req_retry_bank1_way),
        .req_we         (data_req_we_bank1_way),
        .req_pos        (data_req_pos_bank1_way),
        .req_data       (data_req_data_bank1_way),

        .ack_valid      (data_ack_valid_bank1_way),
        .ack_retry      (1'b0),
        //.ack_retry      (data_ack_retry_bank1_way),
        .ack_data       (data_ack_data_bank1_way)
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way),
        .req_retry      (data_req_retry_bank2_way),
        .req_we         (data_req_we_bank2_way),
        .req_pos        (data_req_pos_bank2_way),
        .req_data       (data_req_data_bank2_way),

        .ack_valid      (data_ack_valid_bank2_way),
        .ack_retry      (1'b0),
        //.ack_retry      (data_ack_retry_bank2_way),
        .ack_data       (data_ack_data_bank2_way)
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way),
        .req_retry      (data_req_retry_bank3_way),
        .req_we         (data_req_we_bank3_way),
        .req_pos        (data_req_pos_bank3_way),
        .req_data       (data_req_data_bank3_way),

        .ack_valid      (data_ack_valid_bank3_way),
        .ack_retry      (1'b0),
        //.ack_retry      (data_ack_retry_bank3_way),
        .ack_data       (data_ack_data_bank3_way)
    );


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
    localparam  Q_LINKED_LIST_SIZE = 16;
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

    // read & write pointer and counter for the q_l1tol2_req
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] q_l1tol2_req_rd_pointer;
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] q_l1tol2_req_wr_pointer;
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] q_l1tol2_req_rd_pointer_next;
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] q_l1tol2_req_wr_pointer_next;
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] q_l1tol2_req_counter_next;
    logic   [`log2(Q_L1TOL2_REQ_SIZE)-1 : 0] q_l1tol2_req_counter;
    logic   [1:0]   q_l1tol2_req_rd_vs_wr;

    // Increment pointers and Adjust counter
    assign  q_l1tol2_req_rd_pointer_next = (req_rd_q_l1tol2_req_valid) ? (q_l1tol2_req_rd_pointer + 1) : q_l1tol2_req_rd_pointer;
    //assign  q_l1tol2_req_rd_pointer_next = (req_rd_q_l1tol2_req_valid && req_rd_q_l1tol2_req_retry) ? (q_l1tol2_req_rd_pointer + 1) : q_l1tol2_req_rd_pointer;
    assign  q_l1tol2_req_wr_pointer_next = (req_wr_q_l1tol2_req_valid) ? (q_l1tol2_req_wr_pointer + 1) : q_l1tol2_req_wr_pointer;
    //assign  q_l1tol2_req_wr_pointer_next = (req_wr_q_l1tol2_req_valid && req_wr_q_l1tol2_req_retry) ? (q_l1tol2_req_wr_pointer + 1) : q_l1tol2_req_wr_pointer;
    assign  q_l1tol2_req_rd_vs_wr = {req_rd_q_l1tol2_req_valid, req_wr_q_l1tol2_req_valid};
    //assign  q_l1tol2_req_rd_vs_wr = {(req_rd_q_l1tol2_req_valid && req_rd_q_l1tol2_req_retry),
    //    (req_wr_q_l1tol2_req_valid && req_wr_q_l1tol2_req_retry) };
    assign  q_l1tol2_req_counter_next = (q_l1tol2_req_rd_vs_wr==2'b01) ? (q_l1tol2_req_counter + 1) :
        ((q_l1tol2_req_rd_vs_wr==2'b10) ? (q_l1tol2_req_counter - 1) : q_l1tol2_req_counter);
    
    // The pointers are the addresses for read and write
    assign  req_rd_q_l1tol2_req_addr = q_l1tol2_req_rd_pointer;
    assign  req_wr_q_l1tol2_req_addr = q_l1tol2_req_wr_pointer;


    flop #(.Bits(`log2(Q_L1TOL2_REQ_SIZE))) f_reg_q_l1tol2_req_rd_pointer (
    .clk      (clk),
    .reset    (reset),
    .d        (q_l1tol2_req_rd_pointer_next),
    .q        (q_l1tol2_req_rd_pointer)
    );

    flop #(.Bits(`log2(Q_L1TOL2_REQ_SIZE))) f_reg_q_l1tol2_req_wr_pointer (
    .clk      (clk),
    .reset    (reset),
    .d        (q_l1tol2_req_wr_pointer_next),
    .q        (q_l1tol2_req_wr_pointer)
    );

    flop #(.Bits(`log2(Q_L1TOL2_REQ_SIZE))) f_reg_q_l1tol2_req_counter (
    .clk      (clk),
    .reset    (reset),
    .d        (q_l1tol2_req_counter_next),
    .q        (q_l1tol2_req_counter)
    );


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
    localparam NEW_L1TOL2_REQ = 5'b00001;
    logic [4:0] winner_for_tag;
    // Initial stage
    // Handle new l1tol2_req
    // Check if the new l1tol2_req has the highest priority
    // TODO
    assign  predicted_index_s0 =  l1tol2_req_valid ? ({l1tol2_req.ppaddr[2], l1tol2_req.poffset[11:6]}) : 0;
    assign  tag_bank_id_s0 = l1tol2_req_valid?  predicted_index_s0[1:0] : 0;
    assign  new_l1tol2_req_may_go = (~tag_bank0_busy && (tag_bank_id_s0==2'b00)) || (~tag_bank1_busy && (tag_bank_id_s0==2'b01)) 
            || (~tag_bank2_busy && (tag_bank_id_s0==2'b10)) || (~tag_bank3_busy && (tag_bank_id_s0==2'b11));
    assign  winner_for_tag = new_l1tol2_req_may_go ? NEW_L1TOL2_REQ : 0;
    // TODO
    // // If the new l1tol2_req is not the winner for tag,
        // it enters l1tol2_req_q, set reg_enqueue_l1tol2_req_1
    
    // If it has the highest priority then will access tag in next stage
    // set reg_new_l1tol2_req_tag_access_0
    assign  reg_new_l1tol2_req_tag_access_0_next = read_tag_for_sure;
    assign  reg_new_l1tol2_req_tag_access_0_next_valid = read_tag_for_sure;
    assign  read_tag_for_sure = l1tol2_req_valid && (winner_for_tag == NEW_L1TOL2_REQ);

    // Access tag
    // @ state1: reg_new_l1tol2_req_tag_access_0
    assign  predicted_index_s1 = reg_new_l1tol2_req_tag_access_0 ? ({l1tol2_req_reg1.ppaddr[2], l1tol2_req_reg1.poffset[11:6]})
    : 0; // For 128
    assign  tag_bank_id_s1 = reg_new_l1tol2_req_tag_access_0 ?  predicted_index_s1[1:0] : 0;
    
    
    // Access bank0
    assign  tag_req_valid_bank0_ways = reg_new_l1tol2_req_tag_access_0 && (tag_bank_id_s1 == 2'b00);
    assign  tag_req_we_bank0_ways = tag_req_valid_bank0_ways ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_ways = reg_new_l1tol2_req_tag_access_0 ? predicted_index_s1 : 'b0;
    // Set busy when access tag
    // Reset busy in next state (state2)
    assign  tag_bank0_busy_next = tag_req_valid_bank0_ways ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank0_busy ));


    // Access Bank1
    assign  tag_req_valid_bank1_ways = reg_new_l1tol2_req_tag_access_0 && (tag_bank_id_s1 == 2'b01);
    assign  tag_req_we_bank1_ways = tag_req_valid_bank1_ways ? 0 : 0;// Read tag
    assign  tag_req_pos_bank1_ways = reg_new_l1tol2_req_tag_access_0 ? predicted_index_s1 : 'b0;
    // Set busy when access tag
    // Reset busy in next state (state2)
    assign  tag_bank1_busy_next = tag_req_valid_bank1_ways ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank1_busy ));



    // Access Bank2
    assign  tag_req_valid_bank2_ways = reg_new_l1tol2_req_tag_access_0 && (tag_bank_id_s1 == 2'b10);
    assign  tag_req_we_bank2_ways = tag_req_valid_bank2_ways ? 0 : 0;// Read tag
    assign  tag_req_pos_bank2_ways = reg_new_l1tol2_req_tag_access_0 ? predicted_index_s1 : 'b0;
    // Set busy when access tag
    // Reset busy in next state (state2)
    assign  tag_bank2_busy_next = tag_req_valid_bank2_ways ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank2_busy ));



    // Access Bank3
    assign  tag_req_valid_bank3_ways = reg_new_l1tol2_req_tag_access_0 && (tag_bank_id_s1 == 2'b11);
    assign  tag_req_we_bank3_ways = tag_req_valid_bank3_ways ? 0 : 0;// Read tag
    assign  tag_req_pos_bank3_ways = reg_new_l1tol2_req_tag_access_0 ? predicted_index_s1 : 'b0;
    // Set busy when access tag
    // Reset busy in next state (state2)
    assign  tag_bank3_busy_next = tag_req_valid_bank3_ways ? 1'b1 : ( (reg_new_l1tol2_req_tag_access_1 ? 1'b0 : tag_bank3_busy ));


    //&& (!l1tol2_req_retry);

    /*
    * assign  l1tol2_req_retry =  (tag_req_valid_bank0_ways && tag_req_retry_bank0_ways) ||

                                (tag_req_valid_bank1_ways && tag_req_retry_bank1_ways) ||

                                (tag_req_valid_bank2_ways && tag_req_retry_bank2_ways) ||

                                (tag_req_valid_bank3_ways && tag_req_retry_bank3_ways);
    */


    // Handle input from l2tlb
    // state2: @ reg_new_l1tol2_req_tag_access_1
    always_comb begin
        l1_match_l2tlb_l1id_next = 0;
        l1_match_l2tlb_ppaddr_next = 0;
        req_wr_q_l1tol2_req_valid = 0;
        if (l2tlbtol2_fwd_valid) begin
            if (reg_new_l1tol2_req_tag_access_1) begin
                // l2tlb send a packet on time
                if (l1tol2_req_reg1_valid) begin
                    // Compare l1_id
                    if (l1tol2_req_reg1.l1id == l2tlbtol2_fwd.l1id) begin
                        // l1id match
                        l1_match_l2tlb_l1id_next = 1;
                    end
                    // verify ppaddr
                    if (l2tlbtol2_fwd.paddr[12] == l1tol2_req_reg1.ppaddr[2]) begin// For 128
                        // ppaddr is correct
                        l1_match_l2tlb_ppaddr_next = 1;
                    end
                    else begin
                        // ppaddr is incorrect
                        // Enqueue l1tol2_req to q_l1tol2_req with corrected ppaddr
                        req_wr_q_l1tol2_req_data.l1tol2_req = l1tol2_req_reg1;
                        // Correct ppaddr
                        req_wr_q_l1tol2_req_data.
                          l1tol2_req.ppaddr = l2tlbtol2_fwd.paddr[14:12];
                        req_wr_q_l1tol2_req_data.ppaddr_corrected = 1;
                        req_wr_q_l1tol2_req_valid = 1;
                    end
                end
            end // end of if (reg_new_l1tol2_req_tag_access_1) 
            else begin
                // l2tlb send a delayed packet
            end
        end
    end
    
    TLB_hpaddr_type  hpaddr_from_tag[16];
    assign {hpaddr_from_tag[0], hpaddr_from_tag[1], hpaddr_from_tag[2], hpaddr_from_tag[3],
            hpaddr_from_tag[4], hpaddr_from_tag[5], hpaddr_from_tag[6], hpaddr_from_tag[7],
            hpaddr_from_tag[8], hpaddr_from_tag[9], hpaddr_from_tag[10], hpaddr_from_tag[11],
            hpaddr_from_tag[12], hpaddr_from_tag[13], hpaddr_from_tag[14], hpaddr_from_tag[15]
            } = tag_ack_valid_bank0_ways ? tag_ack_data_bank0_ways : ( 
                (tag_ack_valid_bank1_ways ? tag_ack_data_bank1_ways : 
                (tag_ack_valid_bank2_ways ? tag_ack_data_bank2_ways :
                (tag_ack_valid_bank3_ways ? tag_ack_data_bank3_ways : 'b0
              ))));    // TODO extract hpaddr
    assign  tag_ack_valid_banks_ways = tag_ack_valid_bank0_ways | tag_ack_valid_bank1_ways | tag_ack_valid_bank2_ways | tag_ack_valid_bank3_ways;

    // Handle tag result
    // state3: @ reg_new_l1tol2_req_tag_access_2
    always_comb begin
        tag_hit_next = 0;
        if (reg_new_l1tol2_req_tag_access_2) begin
            // Tag access result is ready
            if (l2tlbtol2_fwd_reg1_valid && l1_match_l2tlb_l1id && l1_match_l2tlb_ppaddr && tag_ack_valid_banks_ways) begin
                // l1id matched and ppaddr is correct
                case (1'b1)
                    // Check way0
                    ((hpaddr_from_tag[0] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0000;
                    end
                    // Check way1
                    ((hpaddr_from_tag[1] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0001;
                    end
                    // Check way2
                    ((hpaddr_from_tag[2] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0010;
                    end
                    // Check way3
                    ((hpaddr_from_tag[3] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0011;
                    end
                    // Check way4
                    ((hpaddr_from_tag[4] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0100;
                    end
                    // Check way5
                    ((hpaddr_from_tag[5] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0101;
                    end
                    // Check way6
                    ((hpaddr_from_tag[6] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0110;
                    end
                    // Check way7
                    ((hpaddr_from_tag[7] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b0111;
                    end
                    // Check way8
                    ((hpaddr_from_tag[8] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1000;
                    end
                    // Check way9
                    ((hpaddr_from_tag[9] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1001;
                    end
                    // Check way10
                    ((hpaddr_from_tag[10] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1010;
                    end
                    // Check way11
                    ((hpaddr_from_tag[11] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1011;
                    end
                    // Check way12
                    ((hpaddr_from_tag[12] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1100;
                    end
                    // Check way13
                    ((hpaddr_from_tag[13] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1101;
                    end
                    // Check way14
                    ((hpaddr_from_tag[14] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1110;
                    end
                    // Check way15
                    ((hpaddr_from_tag[15] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 4'b1111;
                    end
                endcase
            end
        end
    end

    // Handle tag miss
    assign  tag_miss = (~tag_hit_next) && tag_ack_valid_banks_ways;
    // Enqueue linked list
    /* qzhang33
    always_comb begin
      if (reg_new_l1tol2_req_tag_access_2) begin
        req_wr_q_l1tol2_req_hpaddr_miss_data.hpaddr = 0;
        if (tag_miss) begin
          if ( !req_wr_q_l1tol2_req_hpaddr_miss_data.hpaddr ) begin
            req_wr_q_l1tol2_req_hpaddr_miss_data.hpaddr = l2tlbtol2_fwd_reg1.hpaddr;
            req_wr_q_l1tol2_req_hpaddr_miss_data.next   = 0;
            req_wr_q_l1tol2_req_linked_list_data.head   = 
          end else if (req_wr_q_l1tol2_req_hpaddr_miss_data.hpaddr == l2tlbtol2_fwd.hpaddr) begin
            req_wr_q_l1tol2_req_hpaddr_miss_data.next   = req_wr_q_l1tol2_req_hpaddr_miss_data.next + 1;

        
          end
        end
      end
    end
    qzhang33 */

    // Enter next pipe stage: reg_new_l1tol2_req_data_access_0 when tag hit
    assign  reg_new_l1tol2_req_data_access_0_next = tag_hit_next && reg_new_l1tol2_req_tag_access_2;

    // Access data bank under tag hit
    // state4: @ reg_new_l1tol2_req_data_access_0
    // TODO Verify: Pass retry to previous stages:
    // should be from l2tlbtol2_fwd_reg1_retry to  l2tlbtol2_fwd_retry and
    // from l1tol2_req_reg3_retry to l1tol2_req_reg2_retry
    //assign  l2tlbtol2_fwd_reg1_retry = (data_req_back_press);
    //assign  l1tol2_req_reg3_retry = (data_req_back_press);
    //assign  data_req_back_press = data_req_retry_bank0_way || data_req_retry_bank1_way || data_req_retry_bank2_way || data_req_retry_bank3_way;
    assign  data_req_valid = data_req_valid_bank0_way || data_req_valid_bank1_way || data_req_valid_bank2_way || data_req_valid_bank3_way;
    assign  data_req_valid_bank0_way = (l1tol2_req_reg4.poffset[7:6]==2'b00) && reg_new_l1tol2_req_data_access_0 && tag_hit;
    assign  data_req_we_bank0_way = (l1tol2_req_reg4.poffset[7:6]==2'b00) && reg_new_l1tol2_req_data_access_0 ? 0 : 0; // read
    assign  data_req_pos_bank0_way = {hit_way, l1tol2_req_reg4.ppaddr[2], l1tol2_req_reg4.poffset[11:6]};
   
    assign  data_req_valid_bank1_way = (l1tol2_req_reg4.poffset[7:6]==2'b00) && reg_new_l1tol2_req_data_access_0 && tag_hit;
    assign  data_req_we_bank1_way = (l1tol2_req_reg4.poffset[7:6]==2'b01) && reg_new_l1tol2_req_data_access_0 ? 0 : 0; // read
    assign  data_req_pos_bank1_way = {hit_way, l1tol2_req_reg4.ppaddr[2], l1tol2_req_reg4.poffset[11:6]};
   
    assign  data_req_valid_bank2_way = (l1tol2_req_reg4.poffset[7:6]==2'b10) && reg_new_l1tol2_req_data_access_0 && tag_hit;
    assign  data_req_we_bank2_way = (l1tol2_req_reg4.poffset[7:6]==2'b10) && reg_new_l1tol2_req_data_access_0 ? 0 : 0; // read
    assign  data_req_pos_bank2_way = {hit_way, l1tol2_req_reg4.ppaddr[2], l1tol2_req_reg4.poffset[11:6]};
   
    assign  data_req_valid_bank3_way = (l1tol2_req_reg4.poffset[7:6]==2'b00) && reg_new_l1tol2_req_data_access_0 && tag_hit;
    assign  data_req_we_bank3_way = (l1tol2_req_reg4.poffset[7:6]==2'b11) && reg_new_l1tol2_req_data_access_0 ? 0 : 0; // read
    assign  data_req_pos_bank3_way = {hit_way, l1tol2_req_reg4.ppaddr[2], l1tol2_req_reg4.poffset[11:6]};
  
    // Enter next pipe stage: reg_new_l1tol2_req_data_access_1
    assign  reg_new_l1tol2_req_data_access_1_next = reg_new_l1tol2_req_data_access_0 && data_req_valid;

    // Enter next pipe stage: reg_new_l1tol2_req_data_access_2
    assign  reg_new_l1tol2_req_data_access_2_next = reg_new_l1tol2_req_data_access_1;

    // @ state5: reg_new_l1tol2_req_data_access_2
    // Verify full tag was correct:
    //      yes:    Send l2tol1_snack
    //      no:     reflow
`endif
endmodule

