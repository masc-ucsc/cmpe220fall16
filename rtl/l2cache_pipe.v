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
    } I_q_l1tol2_req_type;

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
    .d        (reg_new_l1tol2_req_tag_access_0_next),
    .q        (reg_new_l1tol2_req_tag_access_0)
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

    logic [15:0]    hit_way_next;
    logic [15:0]    hit_way;

    flop #(.Bits(16)) f_reg_hit_way (
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
    .qRetry   (l1tol2_req_reg1_retry)
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
    .qRetry   (l1tol2_req_reg2_retry)
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
    .qRetry   (l1tol2_req_reg3_retry)
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
    .qRetry   (l2tlbtol2_fwd_reg1_retry)
    );


    // Nothing blocks the second cycle of tag access
    assign  reg_new_l1tol2_req_tag_access_1_next = reg_new_l1tol2_req_tag_access_0;
    assign  reg_new_l1tol2_req_tag_access_2_next = reg_new_l1tol2_req_tag_access_1;

    // Signals for tag
    localparam  TAG_WIDTH = `TLB_HPADDRBITS;
    localparam  TAG_SIZE = 128;
    logic   [1:0]   tag_bank_id;
    logic   [6:0]  predicted_index;
    // bank0
    // way0 to way15
    logic tag_req_valid_bank0_way[16];
    logic tag_req_retry_bank0_way[16];
    logic tag_req_we_bank0_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank0_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank0_way[16];
    logic   tag_ack_valid_bank0_way[16];
    logic   tag_ack_retry_bank0_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank0_way[16];

    // bank1
    // way0 to way15
    logic tag_req_valid_bank1_way[16];
    logic tag_req_retry_bank1_way[16];
    logic tag_req_we_bank1_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank1_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank1_way[16];
    logic   tag_ack_valid_bank1_way[16];
    logic   tag_ack_retry_bank1_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank1_way[16];

    // bank2
    // way0 to way15
    logic tag_req_valid_bank2_way[16];
    logic tag_req_retry_bank2_way[16];
    logic tag_req_we_bank2_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank2_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank2_way[16];
    logic   tag_ack_valid_bank2_way[16];
    logic   tag_ack_retry_bank2_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank2_way[16];

    // bank3
    // way0 to way15
    logic tag_req_valid_bank3_way[16];
    logic tag_req_retry_bank3_way[16];
    logic tag_req_we_bank3_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  tag_req_pos_bank3_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_req_data_bank3_way[16];
    logic   tag_ack_valid_bank3_way[16];
    logic   tag_ack_retry_bank3_way[16];
    logic   [TAG_WIDTH-1 : 0]  tag_ack_data_bank3_way[16];



    // Signals for Data Bank
    typedef struct packed {
        SC_line_type    line;
        SC_paddr_type   paddr;
        logic           valid;
    } I_data_bank_line_type;
    localparam  DATA_BANK_WIDTH = $bits(I_data_bank_line_type);
    localparam  DATA_BANK_SIZE = 128;
    // Data bank0
    logic data_req_valid_bank0_way[16];
    logic data_req_retry_bank0_way[16];
    logic data_req_we_bank0_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  data_req_pos_bank0_way[16];
    I_data_bank_line_type   data_req_data_bank0_way[16];
    logic   data_ack_valid_bank0_way[16];
    logic   data_ack_retry_bank0_way[16];
    I_data_bank_line_type   data_ack_data_bank0_way[16];

    // Data bank1
    logic data_req_valid_bank1_way[16];
    logic data_req_retry_bank1_way[16];
    logic data_req_we_bank1_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  data_req_pos_bank1_way[16];
    I_data_bank_line_type   data_req_data_bank1_way[16];
    logic   data_ack_valid_bank1_way[16];
    logic   data_ack_retry_bank1_way[16];
    I_data_bank_line_type   data_ack_data_bank1_way[16];

    // Data bank2
    logic data_req_valid_bank2_way[16];
    logic data_req_retry_bank2_way[16];
    logic data_req_we_bank2_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  data_req_pos_bank2_way[16];
    I_data_bank_line_type   data_req_data_bank2_way[16];
    logic   data_ack_valid_bank2_way[16];
    logic   data_ack_retry_bank2_way[16];
    I_data_bank_line_type   data_ack_data_bank2_way[16];

    // Data bank3
    logic data_req_valid_bank3_way[16];
    logic data_req_retry_bank3_way[16];
    logic data_req_we_bank3_way[16];
    logic   [`log2(TAG_SIZE)-1:0]  data_req_pos_bank3_way[16];
    I_data_bank_line_type   data_req_data_bank3_way[16];
    logic   data_ack_valid_bank3_way[16];
    logic   data_ack_retry_bank3_way[16];
    I_data_bank_line_type   data_ack_data_bank3_way[16];


    // Instantiate Tag RAM
    // Width = TLB_HPADDRBITS
    // Size = 128 
    // Forward = 0
    // Bank0 Way0
    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[0]),
        .req_retry      (tag_req_retry_bank0_way[0]),
        .req_we         (tag_req_we_bank0_way[0]),
        .req_pos        (tag_req_pos_bank0_way[0]),
        .req_data       (tag_req_data_bank0_way[0]),

        .ack_valid      (tag_ack_valid_bank0_way[0]),
        .ack_retry      (tag_ack_retry_bank0_way[0]),
        .ack_data       (tag_ack_data_bank0_way[0])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[1]),
        .req_retry      (tag_req_retry_bank0_way[1]),
        .req_we         (tag_req_we_bank0_way[1]),
        .req_pos        (tag_req_pos_bank0_way[1]),
        .req_data       (tag_req_data_bank0_way[1]),

        .ack_valid      (tag_ack_valid_bank0_way[1]),
        .ack_retry      (tag_ack_retry_bank0_way[1]),
        .ack_data       (tag_ack_data_bank0_way[1])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[2]),
        .req_retry      (tag_req_retry_bank0_way[2]),
        .req_we         (tag_req_we_bank0_way[2]),
        .req_pos        (tag_req_pos_bank0_way[2]),
        .req_data       (tag_req_data_bank0_way[2]),

        .ack_valid      (tag_ack_valid_bank0_way[2]),
        .ack_retry      (tag_ack_retry_bank0_way[2]),
        .ack_data       (tag_ack_data_bank0_way[2])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[3]),
        .req_retry      (tag_req_retry_bank0_way[3]),
        .req_we         (tag_req_we_bank0_way[3]),
        .req_pos        (tag_req_pos_bank0_way[3]),
        .req_data       (tag_req_data_bank0_way[3]),

        .ack_valid      (tag_ack_valid_bank0_way[3]),
        .ack_retry      (tag_ack_retry_bank0_way[3]),
        .ack_data       (tag_ack_data_bank0_way[3])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[4]),
        .req_retry      (tag_req_retry_bank0_way[4]),
        .req_we         (tag_req_we_bank0_way[4]),
        .req_pos        (tag_req_pos_bank0_way[4]),
        .req_data       (tag_req_data_bank0_way[4]),

        .ack_valid      (tag_ack_valid_bank0_way[4]),
        .ack_retry      (tag_ack_retry_bank0_way[4]),
        .ack_data       (tag_ack_data_bank0_way[4])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[5]),
        .req_retry      (tag_req_retry_bank0_way[5]),
        .req_we         (tag_req_we_bank0_way[5]),
        .req_pos        (tag_req_pos_bank0_way[5]),
        .req_data       (tag_req_data_bank0_way[5]),

        .ack_valid      (tag_ack_valid_bank0_way[5]),
        .ack_retry      (tag_ack_retry_bank0_way[5]),
        .ack_data       (tag_ack_data_bank0_way[5])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[6]),
        .req_retry      (tag_req_retry_bank0_way[6]),
        .req_we         (tag_req_we_bank0_way[6]),
        .req_pos        (tag_req_pos_bank0_way[6]),
        .req_data       (tag_req_data_bank0_way[6]),

        .ack_valid      (tag_ack_valid_bank0_way[6]),
        .ack_retry      (tag_ack_retry_bank0_way[6]),
        .ack_data       (tag_ack_data_bank0_way[6])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[7]),
        .req_retry      (tag_req_retry_bank0_way[7]),
        .req_we         (tag_req_we_bank0_way[7]),
        .req_pos        (tag_req_pos_bank0_way[7]),
        .req_data       (tag_req_data_bank0_way[7]),

        .ack_valid      (tag_ack_valid_bank0_way[7]),
        .ack_retry      (tag_ack_retry_bank0_way[7]),
        .ack_data       (tag_ack_data_bank0_way[7])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[8]),
        .req_retry      (tag_req_retry_bank0_way[8]),
        .req_we         (tag_req_we_bank0_way[8]),
        .req_pos        (tag_req_pos_bank0_way[8]),
        .req_data       (tag_req_data_bank0_way[8]),

        .ack_valid      (tag_ack_valid_bank0_way[8]),
        .ack_retry      (tag_ack_retry_bank0_way[8]),
        .ack_data       (tag_ack_data_bank0_way[8])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[9]),
        .req_retry      (tag_req_retry_bank0_way[9]),
        .req_we         (tag_req_we_bank0_way[9]),
        .req_pos        (tag_req_pos_bank0_way[9]),
        .req_data       (tag_req_data_bank0_way[9]),

        .ack_valid      (tag_ack_valid_bank0_way[9]),
        .ack_retry      (tag_ack_retry_bank0_way[9]),
        .ack_data       (tag_ack_data_bank0_way[9])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[10]),
        .req_retry      (tag_req_retry_bank0_way[10]),
        .req_we         (tag_req_we_bank0_way[10]),
        .req_pos        (tag_req_pos_bank0_way[10]),
        .req_data       (tag_req_data_bank0_way[10]),

        .ack_valid      (tag_ack_valid_bank0_way[10]),
        .ack_retry      (tag_ack_retry_bank0_way[10]),
        .ack_data       (tag_ack_data_bank0_way[10])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[11]),
        .req_retry      (tag_req_retry_bank0_way[11]),
        .req_we         (tag_req_we_bank0_way[11]),
        .req_pos        (tag_req_pos_bank0_way[11]),
        .req_data       (tag_req_data_bank0_way[11]),

        .ack_valid      (tag_ack_valid_bank0_way[11]),
        .ack_retry      (tag_ack_retry_bank0_way[11]),
        .ack_data       (tag_ack_data_bank0_way[11])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[12]),
        .req_retry      (tag_req_retry_bank0_way[12]),
        .req_we         (tag_req_we_bank0_way[12]),
        .req_pos        (tag_req_pos_bank0_way[12]),
        .req_data       (tag_req_data_bank0_way[12]),

        .ack_valid      (tag_ack_valid_bank0_way[12]),
        .ack_retry      (tag_ack_retry_bank0_way[12]),
        .ack_data       (tag_ack_data_bank0_way[12])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[13]),
        .req_retry      (tag_req_retry_bank0_way[13]),
        .req_we         (tag_req_we_bank0_way[13]),
        .req_pos        (tag_req_pos_bank0_way[13]),
        .req_data       (tag_req_data_bank0_way[13]),

        .ack_valid      (tag_ack_valid_bank0_way[13]),
        .ack_retry      (tag_ack_retry_bank0_way[13]),
        .ack_data       (tag_ack_data_bank0_way[13])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[14]),
        .req_retry      (tag_req_retry_bank0_way[14]),
        .req_we         (tag_req_we_bank0_way[14]),
        .req_pos        (tag_req_pos_bank0_way[14]),
        .req_data       (tag_req_data_bank0_way[14]),

        .ack_valid      (tag_ack_valid_bank0_way[14]),
        .ack_retry      (tag_ack_retry_bank0_way[14]),
        .ack_data       (tag_ack_data_bank0_way[14])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank0_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank0_way[15]),
        .req_retry      (tag_req_retry_bank0_way[15]),
        .req_we         (tag_req_we_bank0_way[15]),
        .req_pos        (tag_req_pos_bank0_way[15]),
        .req_data       (tag_req_data_bank0_way[15]),

        .ack_valid      (tag_ack_valid_bank0_way[15]),
        .ack_retry      (tag_ack_retry_bank0_way[15]),
        .ack_data       (tag_ack_data_bank0_way[15])
    );

ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[0]),
        .req_retry      (tag_req_retry_bank1_way[0]),
        .req_we         (tag_req_we_bank1_way[0]),
        .req_pos        (tag_req_pos_bank1_way[0]),
        .req_data       (tag_req_data_bank1_way[0]),

        .ack_valid      (tag_ack_valid_bank1_way[0]),
        .ack_retry      (tag_ack_retry_bank1_way[0]),
        .ack_data       (tag_ack_data_bank1_way[0])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[1]),
        .req_retry      (tag_req_retry_bank1_way[1]),
        .req_we         (tag_req_we_bank1_way[1]),
        .req_pos        (tag_req_pos_bank1_way[1]),
        .req_data       (tag_req_data_bank1_way[1]),

        .ack_valid      (tag_ack_valid_bank1_way[1]),
        .ack_retry      (tag_ack_retry_bank1_way[1]),
        .ack_data       (tag_ack_data_bank1_way[1])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[2]),
        .req_retry      (tag_req_retry_bank1_way[2]),
        .req_we         (tag_req_we_bank1_way[2]),
        .req_pos        (tag_req_pos_bank1_way[2]),
        .req_data       (tag_req_data_bank1_way[2]),

        .ack_valid      (tag_ack_valid_bank1_way[2]),
        .ack_retry      (tag_ack_retry_bank1_way[2]),
        .ack_data       (tag_ack_data_bank1_way[2])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[3]),
        .req_retry      (tag_req_retry_bank1_way[3]),
        .req_we         (tag_req_we_bank1_way[3]),
        .req_pos        (tag_req_pos_bank1_way[3]),
        .req_data       (tag_req_data_bank1_way[3]),

        .ack_valid      (tag_ack_valid_bank1_way[3]),
        .ack_retry      (tag_ack_retry_bank1_way[3]),
        .ack_data       (tag_ack_data_bank1_way[3])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[4]),
        .req_retry      (tag_req_retry_bank1_way[4]),
        .req_we         (tag_req_we_bank1_way[4]),
        .req_pos        (tag_req_pos_bank1_way[4]),
        .req_data       (tag_req_data_bank1_way[4]),

        .ack_valid      (tag_ack_valid_bank1_way[4]),
        .ack_retry      (tag_ack_retry_bank1_way[4]),
        .ack_data       (tag_ack_data_bank1_way[4])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[5]),
        .req_retry      (tag_req_retry_bank1_way[5]),
        .req_we         (tag_req_we_bank1_way[5]),
        .req_pos        (tag_req_pos_bank1_way[5]),
        .req_data       (tag_req_data_bank1_way[5]),

        .ack_valid      (tag_ack_valid_bank1_way[5]),
        .ack_retry      (tag_ack_retry_bank1_way[5]),
        .ack_data       (tag_ack_data_bank1_way[5])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[6]),
        .req_retry      (tag_req_retry_bank1_way[6]),
        .req_we         (tag_req_we_bank1_way[6]),
        .req_pos        (tag_req_pos_bank1_way[6]),
        .req_data       (tag_req_data_bank1_way[6]),

        .ack_valid      (tag_ack_valid_bank1_way[6]),
        .ack_retry      (tag_ack_retry_bank1_way[6]),
        .ack_data       (tag_ack_data_bank1_way[6])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[7]),
        .req_retry      (tag_req_retry_bank1_way[7]),
        .req_we         (tag_req_we_bank1_way[7]),
        .req_pos        (tag_req_pos_bank1_way[7]),
        .req_data       (tag_req_data_bank1_way[7]),

        .ack_valid      (tag_ack_valid_bank1_way[7]),
        .ack_retry      (tag_ack_retry_bank1_way[7]),
        .ack_data       (tag_ack_data_bank1_way[7])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[8]),
        .req_retry      (tag_req_retry_bank1_way[8]),
        .req_we         (tag_req_we_bank1_way[8]),
        .req_pos        (tag_req_pos_bank1_way[8]),
        .req_data       (tag_req_data_bank1_way[8]),

        .ack_valid      (tag_ack_valid_bank1_way[8]),
        .ack_retry      (tag_ack_retry_bank1_way[8]),
        .ack_data       (tag_ack_data_bank1_way[8])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[9]),
        .req_retry      (tag_req_retry_bank1_way[9]),
        .req_we         (tag_req_we_bank1_way[9]),
        .req_pos        (tag_req_pos_bank1_way[9]),
        .req_data       (tag_req_data_bank1_way[9]),

        .ack_valid      (tag_ack_valid_bank1_way[9]),
        .ack_retry      (tag_ack_retry_bank1_way[9]),
        .ack_data       (tag_ack_data_bank1_way[9])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[10]),
        .req_retry      (tag_req_retry_bank1_way[10]),
        .req_we         (tag_req_we_bank1_way[10]),
        .req_pos        (tag_req_pos_bank1_way[10]),
        .req_data       (tag_req_data_bank1_way[10]),

        .ack_valid      (tag_ack_valid_bank1_way[10]),
        .ack_retry      (tag_ack_retry_bank1_way[10]),
        .ack_data       (tag_ack_data_bank1_way[10])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[11]),
        .req_retry      (tag_req_retry_bank1_way[11]),
        .req_we         (tag_req_we_bank1_way[11]),
        .req_pos        (tag_req_pos_bank1_way[11]),
        .req_data       (tag_req_data_bank1_way[11]),

        .ack_valid      (tag_ack_valid_bank1_way[11]),
        .ack_retry      (tag_ack_retry_bank1_way[11]),
        .ack_data       (tag_ack_data_bank1_way[11])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[12]),
        .req_retry      (tag_req_retry_bank1_way[12]),
        .req_we         (tag_req_we_bank1_way[12]),
        .req_pos        (tag_req_pos_bank1_way[12]),
        .req_data       (tag_req_data_bank1_way[12]),

        .ack_valid      (tag_ack_valid_bank1_way[12]),
        .ack_retry      (tag_ack_retry_bank1_way[12]),
        .ack_data       (tag_ack_data_bank1_way[12])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[13]),
        .req_retry      (tag_req_retry_bank1_way[13]),
        .req_we         (tag_req_we_bank1_way[13]),
        .req_pos        (tag_req_pos_bank1_way[13]),
        .req_data       (tag_req_data_bank1_way[13]),

        .ack_valid      (tag_ack_valid_bank1_way[13]),
        .ack_retry      (tag_ack_retry_bank1_way[13]),
        .ack_data       (tag_ack_data_bank1_way[13])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[14]),
        .req_retry      (tag_req_retry_bank1_way[14]),
        .req_we         (tag_req_we_bank1_way[14]),
        .req_pos        (tag_req_pos_bank1_way[14]),
        .req_data       (tag_req_data_bank1_way[14]),

        .ack_valid      (tag_ack_valid_bank1_way[14]),
        .ack_retry      (tag_ack_retry_bank1_way[14]),
        .ack_data       (tag_ack_data_bank1_way[14])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank1_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank1_way[15]),
        .req_retry      (tag_req_retry_bank1_way[15]),
        .req_we         (tag_req_we_bank1_way[15]),
        .req_pos        (tag_req_pos_bank1_way[15]),
        .req_data       (tag_req_data_bank1_way[15]),

        .ack_valid      (tag_ack_valid_bank1_way[15]),
        .ack_retry      (tag_ack_retry_bank1_way[15]),
        .ack_data       (tag_ack_data_bank1_way[15])
    );

ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[0]),
        .req_retry      (tag_req_retry_bank2_way[0]),
        .req_we         (tag_req_we_bank2_way[0]),
        .req_pos        (tag_req_pos_bank2_way[0]),
        .req_data       (tag_req_data_bank2_way[0]),

        .ack_valid      (tag_ack_valid_bank2_way[0]),
        .ack_retry      (tag_ack_retry_bank2_way[0]),
        .ack_data       (tag_ack_data_bank2_way[0])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[1]),
        .req_retry      (tag_req_retry_bank2_way[1]),
        .req_we         (tag_req_we_bank2_way[1]),
        .req_pos        (tag_req_pos_bank2_way[1]),
        .req_data       (tag_req_data_bank2_way[1]),

        .ack_valid      (tag_ack_valid_bank2_way[1]),
        .ack_retry      (tag_ack_retry_bank2_way[1]),
        .ack_data       (tag_ack_data_bank2_way[1])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[2]),
        .req_retry      (tag_req_retry_bank2_way[2]),
        .req_we         (tag_req_we_bank2_way[2]),
        .req_pos        (tag_req_pos_bank2_way[2]),
        .req_data       (tag_req_data_bank2_way[2]),

        .ack_valid      (tag_ack_valid_bank2_way[2]),
        .ack_retry      (tag_ack_retry_bank2_way[2]),
        .ack_data       (tag_ack_data_bank2_way[2])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[3]),
        .req_retry      (tag_req_retry_bank2_way[3]),
        .req_we         (tag_req_we_bank2_way[3]),
        .req_pos        (tag_req_pos_bank2_way[3]),
        .req_data       (tag_req_data_bank2_way[3]),

        .ack_valid      (tag_ack_valid_bank2_way[3]),
        .ack_retry      (tag_ack_retry_bank2_way[3]),
        .ack_data       (tag_ack_data_bank2_way[3])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[4]),
        .req_retry      (tag_req_retry_bank2_way[4]),
        .req_we         (tag_req_we_bank2_way[4]),
        .req_pos        (tag_req_pos_bank2_way[4]),
        .req_data       (tag_req_data_bank2_way[4]),

        .ack_valid      (tag_ack_valid_bank2_way[4]),
        .ack_retry      (tag_ack_retry_bank2_way[4]),
        .ack_data       (tag_ack_data_bank2_way[4])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[5]),
        .req_retry      (tag_req_retry_bank2_way[5]),
        .req_we         (tag_req_we_bank2_way[5]),
        .req_pos        (tag_req_pos_bank2_way[5]),
        .req_data       (tag_req_data_bank2_way[5]),

        .ack_valid      (tag_ack_valid_bank2_way[5]),
        .ack_retry      (tag_ack_retry_bank2_way[5]),
        .ack_data       (tag_ack_data_bank2_way[5])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[6]),
        .req_retry      (tag_req_retry_bank2_way[6]),
        .req_we         (tag_req_we_bank2_way[6]),
        .req_pos        (tag_req_pos_bank2_way[6]),
        .req_data       (tag_req_data_bank2_way[6]),

        .ack_valid      (tag_ack_valid_bank2_way[6]),
        .ack_retry      (tag_ack_retry_bank2_way[6]),
        .ack_data       (tag_ack_data_bank2_way[6])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[7]),
        .req_retry      (tag_req_retry_bank2_way[7]),
        .req_we         (tag_req_we_bank2_way[7]),
        .req_pos        (tag_req_pos_bank2_way[7]),
        .req_data       (tag_req_data_bank2_way[7]),

        .ack_valid      (tag_ack_valid_bank2_way[7]),
        .ack_retry      (tag_ack_retry_bank2_way[7]),
        .ack_data       (tag_ack_data_bank2_way[7])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[8]),
        .req_retry      (tag_req_retry_bank2_way[8]),
        .req_we         (tag_req_we_bank2_way[8]),
        .req_pos        (tag_req_pos_bank2_way[8]),
        .req_data       (tag_req_data_bank2_way[8]),

        .ack_valid      (tag_ack_valid_bank2_way[8]),
        .ack_retry      (tag_ack_retry_bank2_way[8]),
        .ack_data       (tag_ack_data_bank2_way[8])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[9]),
        .req_retry      (tag_req_retry_bank2_way[9]),
        .req_we         (tag_req_we_bank2_way[9]),
        .req_pos        (tag_req_pos_bank2_way[9]),
        .req_data       (tag_req_data_bank2_way[9]),

        .ack_valid      (tag_ack_valid_bank2_way[9]),
        .ack_retry      (tag_ack_retry_bank2_way[9]),
        .ack_data       (tag_ack_data_bank2_way[9])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[10]),
        .req_retry      (tag_req_retry_bank2_way[10]),
        .req_we         (tag_req_we_bank2_way[10]),
        .req_pos        (tag_req_pos_bank2_way[10]),
        .req_data       (tag_req_data_bank2_way[10]),

        .ack_valid      (tag_ack_valid_bank2_way[10]),
        .ack_retry      (tag_ack_retry_bank2_way[10]),
        .ack_data       (tag_ack_data_bank2_way[10])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[11]),
        .req_retry      (tag_req_retry_bank2_way[11]),
        .req_we         (tag_req_we_bank2_way[11]),
        .req_pos        (tag_req_pos_bank2_way[11]),
        .req_data       (tag_req_data_bank2_way[11]),

        .ack_valid      (tag_ack_valid_bank2_way[11]),
        .ack_retry      (tag_ack_retry_bank2_way[11]),
        .ack_data       (tag_ack_data_bank2_way[11])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[12]),
        .req_retry      (tag_req_retry_bank2_way[12]),
        .req_we         (tag_req_we_bank2_way[12]),
        .req_pos        (tag_req_pos_bank2_way[12]),
        .req_data       (tag_req_data_bank2_way[12]),

        .ack_valid      (tag_ack_valid_bank2_way[12]),
        .ack_retry      (tag_ack_retry_bank2_way[12]),
        .ack_data       (tag_ack_data_bank2_way[12])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[13]),
        .req_retry      (tag_req_retry_bank2_way[13]),
        .req_we         (tag_req_we_bank2_way[13]),
        .req_pos        (tag_req_pos_bank2_way[13]),
        .req_data       (tag_req_data_bank2_way[13]),

        .ack_valid      (tag_ack_valid_bank2_way[13]),
        .ack_retry      (tag_ack_retry_bank2_way[13]),
        .ack_data       (tag_ack_data_bank2_way[13])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[14]),
        .req_retry      (tag_req_retry_bank2_way[14]),
        .req_we         (tag_req_we_bank2_way[14]),
        .req_pos        (tag_req_pos_bank2_way[14]),
        .req_data       (tag_req_data_bank2_way[14]),

        .ack_valid      (tag_ack_valid_bank2_way[14]),
        .ack_retry      (tag_ack_retry_bank2_way[14]),
        .ack_data       (tag_ack_data_bank2_way[14])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank2_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank2_way[15]),
        .req_retry      (tag_req_retry_bank2_way[15]),
        .req_we         (tag_req_we_bank2_way[15]),
        .req_pos        (tag_req_pos_bank2_way[15]),
        .req_data       (tag_req_data_bank2_way[15]),

        .ack_valid      (tag_ack_valid_bank2_way[15]),
        .ack_retry      (tag_ack_retry_bank2_way[15]),
        .ack_data       (tag_ack_data_bank2_way[15])
    );

ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[0]),
        .req_retry      (tag_req_retry_bank3_way[0]),
        .req_we         (tag_req_we_bank3_way[0]),
        .req_pos        (tag_req_pos_bank3_way[0]),
        .req_data       (tag_req_data_bank3_way[0]),

        .ack_valid      (tag_ack_valid_bank3_way[0]),
        .ack_retry      (tag_ack_retry_bank3_way[0]),
        .ack_data       (tag_ack_data_bank3_way[0])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[1]),
        .req_retry      (tag_req_retry_bank3_way[1]),
        .req_we         (tag_req_we_bank3_way[1]),
        .req_pos        (tag_req_pos_bank3_way[1]),
        .req_data       (tag_req_data_bank3_way[1]),

        .ack_valid      (tag_ack_valid_bank3_way[1]),
        .ack_retry      (tag_ack_retry_bank3_way[1]),
        .ack_data       (tag_ack_data_bank3_way[1])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[2]),
        .req_retry      (tag_req_retry_bank3_way[2]),
        .req_we         (tag_req_we_bank3_way[2]),
        .req_pos        (tag_req_pos_bank3_way[2]),
        .req_data       (tag_req_data_bank3_way[2]),

        .ack_valid      (tag_ack_valid_bank3_way[2]),
        .ack_retry      (tag_ack_retry_bank3_way[2]),
        .ack_data       (tag_ack_data_bank3_way[2])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[3]),
        .req_retry      (tag_req_retry_bank3_way[3]),
        .req_we         (tag_req_we_bank3_way[3]),
        .req_pos        (tag_req_pos_bank3_way[3]),
        .req_data       (tag_req_data_bank3_way[3]),

        .ack_valid      (tag_ack_valid_bank3_way[3]),
        .ack_retry      (tag_ack_retry_bank3_way[3]),
        .ack_data       (tag_ack_data_bank3_way[3])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[4]),
        .req_retry      (tag_req_retry_bank3_way[4]),
        .req_we         (tag_req_we_bank3_way[4]),
        .req_pos        (tag_req_pos_bank3_way[4]),
        .req_data       (tag_req_data_bank3_way[4]),

        .ack_valid      (tag_ack_valid_bank3_way[4]),
        .ack_retry      (tag_ack_retry_bank3_way[4]),
        .ack_data       (tag_ack_data_bank3_way[4])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[5]),
        .req_retry      (tag_req_retry_bank3_way[5]),
        .req_we         (tag_req_we_bank3_way[5]),
        .req_pos        (tag_req_pos_bank3_way[5]),
        .req_data       (tag_req_data_bank3_way[5]),

        .ack_valid      (tag_ack_valid_bank3_way[5]),
        .ack_retry      (tag_ack_retry_bank3_way[5]),
        .ack_data       (tag_ack_data_bank3_way[5])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[6]),
        .req_retry      (tag_req_retry_bank3_way[6]),
        .req_we         (tag_req_we_bank3_way[6]),
        .req_pos        (tag_req_pos_bank3_way[6]),
        .req_data       (tag_req_data_bank3_way[6]),

        .ack_valid      (tag_ack_valid_bank3_way[6]),
        .ack_retry      (tag_ack_retry_bank3_way[6]),
        .ack_data       (tag_ack_data_bank3_way[6])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[7]),
        .req_retry      (tag_req_retry_bank3_way[7]),
        .req_we         (tag_req_we_bank3_way[7]),
        .req_pos        (tag_req_pos_bank3_way[7]),
        .req_data       (tag_req_data_bank3_way[7]),

        .ack_valid      (tag_ack_valid_bank3_way[7]),
        .ack_retry      (tag_ack_retry_bank3_way[7]),
        .ack_data       (tag_ack_data_bank3_way[7])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[8]),
        .req_retry      (tag_req_retry_bank3_way[8]),
        .req_we         (tag_req_we_bank3_way[8]),
        .req_pos        (tag_req_pos_bank3_way[8]),
        .req_data       (tag_req_data_bank3_way[8]),

        .ack_valid      (tag_ack_valid_bank3_way[8]),
        .ack_retry      (tag_ack_retry_bank3_way[8]),
        .ack_data       (tag_ack_data_bank3_way[8])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[9]),
        .req_retry      (tag_req_retry_bank3_way[9]),
        .req_we         (tag_req_we_bank3_way[9]),
        .req_pos        (tag_req_pos_bank3_way[9]),
        .req_data       (tag_req_data_bank3_way[9]),

        .ack_valid      (tag_ack_valid_bank3_way[9]),
        .ack_retry      (tag_ack_retry_bank3_way[9]),
        .ack_data       (tag_ack_data_bank3_way[9])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[10]),
        .req_retry      (tag_req_retry_bank3_way[10]),
        .req_we         (tag_req_we_bank3_way[10]),
        .req_pos        (tag_req_pos_bank3_way[10]),
        .req_data       (tag_req_data_bank3_way[10]),

        .ack_valid      (tag_ack_valid_bank3_way[10]),
        .ack_retry      (tag_ack_retry_bank3_way[10]),
        .ack_data       (tag_ack_data_bank3_way[10])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[11]),
        .req_retry      (tag_req_retry_bank3_way[11]),
        .req_we         (tag_req_we_bank3_way[11]),
        .req_pos        (tag_req_pos_bank3_way[11]),
        .req_data       (tag_req_data_bank3_way[11]),

        .ack_valid      (tag_ack_valid_bank3_way[11]),
        .ack_retry      (tag_ack_retry_bank3_way[11]),
        .ack_data       (tag_ack_data_bank3_way[11])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[12]),
        .req_retry      (tag_req_retry_bank3_way[12]),
        .req_we         (tag_req_we_bank3_way[12]),
        .req_pos        (tag_req_pos_bank3_way[12]),
        .req_data       (tag_req_data_bank3_way[12]),

        .ack_valid      (tag_ack_valid_bank3_way[12]),
        .ack_retry      (tag_ack_retry_bank3_way[12]),
        .ack_data       (tag_ack_data_bank3_way[12])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[13]),
        .req_retry      (tag_req_retry_bank3_way[13]),
        .req_we         (tag_req_we_bank3_way[13]),
        .req_pos        (tag_req_pos_bank3_way[13]),
        .req_data       (tag_req_data_bank3_way[13]),

        .ack_valid      (tag_ack_valid_bank3_way[13]),
        .ack_retry      (tag_ack_retry_bank3_way[13]),
        .ack_data       (tag_ack_data_bank3_way[13])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[14]),
        .req_retry      (tag_req_retry_bank3_way[14]),
        .req_we         (tag_req_we_bank3_way[14]),
        .req_pos        (tag_req_pos_bank3_way[14]),
        .req_data       (tag_req_data_bank3_way[14]),

        .ack_valid      (tag_ack_valid_bank3_way[14]),
        .ack_retry      (tag_ack_retry_bank3_way[14]),
        .ack_data       (tag_ack_data_bank3_way[14])
    );

    ram_1port_dense #(TAG_WIDTH, TAG_SIZE, 0) tag_bank3_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (tag_req_valid_bank3_way[15]),
        .req_retry      (tag_req_retry_bank3_way[15]),
        .req_we         (tag_req_we_bank3_way[15]),
        .req_pos        (tag_req_pos_bank3_way[15]),
        .req_data       (tag_req_data_bank3_way[15]),

        .ack_valid      (tag_ack_valid_bank3_way[15]),
        .ack_retry      (tag_ack_retry_bank3_way[15]),
        .ack_data       (tag_ack_data_bank3_way[15])
    );



    // Instantiate Dank RAM
    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[0]),
        .req_retry      (data_req_retry_bank0_way[0]),
        .req_we         (data_req_we_bank0_way[0]),
        .req_pos        (data_req_pos_bank0_way[0]),
        .req_data       (data_req_data_bank0_way[0]),

        .ack_valid      (data_ack_valid_bank0_way[0]),
        .ack_retry      (data_ack_retry_bank0_way[0]),
        .ack_data       (data_ack_data_bank0_way[0])
    );

ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[1]),
        .req_retry      (data_req_retry_bank0_way[1]),
        .req_we         (data_req_we_bank0_way[1]),
        .req_pos        (data_req_pos_bank0_way[1]),
        .req_data       (data_req_data_bank0_way[1]),

        .ack_valid      (data_ack_valid_bank0_way[1]),
        .ack_retry      (data_ack_retry_bank0_way[1]),
        .ack_data       (data_ack_data_bank0_way[1])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[2]),
        .req_retry      (data_req_retry_bank0_way[2]),
        .req_we         (data_req_we_bank0_way[2]),
        .req_pos        (data_req_pos_bank0_way[2]),
        .req_data       (data_req_data_bank0_way[2]),

        .ack_valid      (data_ack_valid_bank0_way[2]),
        .ack_retry      (data_ack_retry_bank0_way[2]),
        .ack_data       (data_ack_data_bank0_way[2])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[3]),
        .req_retry      (data_req_retry_bank0_way[3]),
        .req_we         (data_req_we_bank0_way[3]),
        .req_pos        (data_req_pos_bank0_way[3]),
        .req_data       (data_req_data_bank0_way[3]),

        .ack_valid      (data_ack_valid_bank0_way[3]),
        .ack_retry      (data_ack_retry_bank0_way[3]),
        .ack_data       (data_ack_data_bank0_way[3])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[4]),
        .req_retry      (data_req_retry_bank0_way[4]),
        .req_we         (data_req_we_bank0_way[4]),
        .req_pos        (data_req_pos_bank0_way[4]),
        .req_data       (data_req_data_bank0_way[4]),

        .ack_valid      (data_ack_valid_bank0_way[4]),
        .ack_retry      (data_ack_retry_bank0_way[4]),
        .ack_data       (data_ack_data_bank0_way[4])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[5]),
        .req_retry      (data_req_retry_bank0_way[5]),
        .req_we         (data_req_we_bank0_way[5]),
        .req_pos        (data_req_pos_bank0_way[5]),
        .req_data       (data_req_data_bank0_way[5]),

        .ack_valid      (data_ack_valid_bank0_way[5]),
        .ack_retry      (data_ack_retry_bank0_way[5]),
        .ack_data       (data_ack_data_bank0_way[5])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[6]),
        .req_retry      (data_req_retry_bank0_way[6]),
        .req_we         (data_req_we_bank0_way[6]),
        .req_pos        (data_req_pos_bank0_way[6]),
        .req_data       (data_req_data_bank0_way[6]),

        .ack_valid      (data_ack_valid_bank0_way[6]),
        .ack_retry      (data_ack_retry_bank0_way[6]),
        .ack_data       (data_ack_data_bank0_way[6])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[7]),
        .req_retry      (data_req_retry_bank0_way[7]),
        .req_we         (data_req_we_bank0_way[7]),
        .req_pos        (data_req_pos_bank0_way[7]),
        .req_data       (data_req_data_bank0_way[7]),

        .ack_valid      (data_ack_valid_bank0_way[7]),
        .ack_retry      (data_ack_retry_bank0_way[7]),
        .ack_data       (data_ack_data_bank0_way[7])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[8]),
        .req_retry      (data_req_retry_bank0_way[8]),
        .req_we         (data_req_we_bank0_way[8]),
        .req_pos        (data_req_pos_bank0_way[8]),
        .req_data       (data_req_data_bank0_way[8]),

        .ack_valid      (data_ack_valid_bank0_way[8]),
        .ack_retry      (data_ack_retry_bank0_way[8]),
        .ack_data       (data_ack_data_bank0_way[8])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[9]),
        .req_retry      (data_req_retry_bank0_way[9]),
        .req_we         (data_req_we_bank0_way[9]),
        .req_pos        (data_req_pos_bank0_way[9]),
        .req_data       (data_req_data_bank0_way[9]),

        .ack_valid      (data_ack_valid_bank0_way[9]),
        .ack_retry      (data_ack_retry_bank0_way[9]),
        .ack_data       (data_ack_data_bank0_way[9])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[10]),
        .req_retry      (data_req_retry_bank0_way[10]),
        .req_we         (data_req_we_bank0_way[10]),
        .req_pos        (data_req_pos_bank0_way[10]),
        .req_data       (data_req_data_bank0_way[10]),

        .ack_valid      (data_ack_valid_bank0_way[10]),
        .ack_retry      (data_ack_retry_bank0_way[10]),
        .ack_data       (data_ack_data_bank0_way[10])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[11]),
        .req_retry      (data_req_retry_bank0_way[11]),
        .req_we         (data_req_we_bank0_way[11]),
        .req_pos        (data_req_pos_bank0_way[11]),
        .req_data       (data_req_data_bank0_way[11]),

        .ack_valid      (data_ack_valid_bank0_way[11]),
        .ack_retry      (data_ack_retry_bank0_way[11]),
        .ack_data       (data_ack_data_bank0_way[11])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[12]),
        .req_retry      (data_req_retry_bank0_way[12]),
        .req_we         (data_req_we_bank0_way[12]),
        .req_pos        (data_req_pos_bank0_way[12]),
        .req_data       (data_req_data_bank0_way[12]),

        .ack_valid      (data_ack_valid_bank0_way[12]),
        .ack_retry      (data_ack_retry_bank0_way[12]),
        .ack_data       (data_ack_data_bank0_way[12])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[13]),
        .req_retry      (data_req_retry_bank0_way[13]),
        .req_we         (data_req_we_bank0_way[13]),
        .req_pos        (data_req_pos_bank0_way[13]),
        .req_data       (data_req_data_bank0_way[13]),

        .ack_valid      (data_ack_valid_bank0_way[13]),
        .ack_retry      (data_ack_retry_bank0_way[13]),
        .ack_data       (data_ack_data_bank0_way[13])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[14]),
        .req_retry      (data_req_retry_bank0_way[14]),
        .req_we         (data_req_we_bank0_way[14]),
        .req_pos        (data_req_pos_bank0_way[14]),
        .req_data       (data_req_data_bank0_way[14]),

        .ack_valid      (data_ack_valid_bank0_way[14]),
        .ack_retry      (data_ack_retry_bank0_way[14]),
        .ack_data       (data_ack_data_bank0_way[14])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank0_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank0_way[15]),
        .req_retry      (data_req_retry_bank0_way[15]),
        .req_we         (data_req_we_bank0_way[15]),
        .req_pos        (data_req_pos_bank0_way[15]),
        .req_data       (data_req_data_bank0_way[15]),

        .ack_valid      (data_ack_valid_bank0_way[15]),
        .ack_retry      (data_ack_retry_bank0_way[15]),
        .ack_data       (data_ack_data_bank0_way[15])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[0]),
        .req_retry      (data_req_retry_bank1_way[0]),
        .req_we         (data_req_we_bank1_way[0]),
        .req_pos        (data_req_pos_bank1_way[0]),
        .req_data       (data_req_data_bank1_way[0]),

        .ack_valid      (data_ack_valid_bank1_way[0]),
        .ack_retry      (data_ack_retry_bank1_way[0]),
        .ack_data       (data_ack_data_bank1_way[0])
    );

ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[1]),
        .req_retry      (data_req_retry_bank1_way[1]),
        .req_we         (data_req_we_bank1_way[1]),
        .req_pos        (data_req_pos_bank1_way[1]),
        .req_data       (data_req_data_bank1_way[1]),

        .ack_valid      (data_ack_valid_bank1_way[1]),
        .ack_retry      (data_ack_retry_bank1_way[1]),
        .ack_data       (data_ack_data_bank1_way[1])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[2]),
        .req_retry      (data_req_retry_bank1_way[2]),
        .req_we         (data_req_we_bank1_way[2]),
        .req_pos        (data_req_pos_bank1_way[2]),
        .req_data       (data_req_data_bank1_way[2]),

        .ack_valid      (data_ack_valid_bank1_way[2]),
        .ack_retry      (data_ack_retry_bank1_way[2]),
        .ack_data       (data_ack_data_bank1_way[2])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[3]),
        .req_retry      (data_req_retry_bank1_way[3]),
        .req_we         (data_req_we_bank1_way[3]),
        .req_pos        (data_req_pos_bank1_way[3]),
        .req_data       (data_req_data_bank1_way[3]),

        .ack_valid      (data_ack_valid_bank1_way[3]),
        .ack_retry      (data_ack_retry_bank1_way[3]),
        .ack_data       (data_ack_data_bank1_way[3])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[4]),
        .req_retry      (data_req_retry_bank1_way[4]),
        .req_we         (data_req_we_bank1_way[4]),
        .req_pos        (data_req_pos_bank1_way[4]),
        .req_data       (data_req_data_bank1_way[4]),

        .ack_valid      (data_ack_valid_bank1_way[4]),
        .ack_retry      (data_ack_retry_bank1_way[4]),
        .ack_data       (data_ack_data_bank1_way[4])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[5]),
        .req_retry      (data_req_retry_bank1_way[5]),
        .req_we         (data_req_we_bank1_way[5]),
        .req_pos        (data_req_pos_bank1_way[5]),
        .req_data       (data_req_data_bank1_way[5]),

        .ack_valid      (data_ack_valid_bank1_way[5]),
        .ack_retry      (data_ack_retry_bank1_way[5]),
        .ack_data       (data_ack_data_bank1_way[5])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[6]),
        .req_retry      (data_req_retry_bank1_way[6]),
        .req_we         (data_req_we_bank1_way[6]),
        .req_pos        (data_req_pos_bank1_way[6]),
        .req_data       (data_req_data_bank1_way[6]),

        .ack_valid      (data_ack_valid_bank1_way[6]),
        .ack_retry      (data_ack_retry_bank1_way[6]),
        .ack_data       (data_ack_data_bank1_way[6])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[7]),
        .req_retry      (data_req_retry_bank1_way[7]),
        .req_we         (data_req_we_bank1_way[7]),
        .req_pos        (data_req_pos_bank1_way[7]),
        .req_data       (data_req_data_bank1_way[7]),

        .ack_valid      (data_ack_valid_bank1_way[7]),
        .ack_retry      (data_ack_retry_bank1_way[7]),
        .ack_data       (data_ack_data_bank1_way[7])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[8]),
        .req_retry      (data_req_retry_bank1_way[8]),
        .req_we         (data_req_we_bank1_way[8]),
        .req_pos        (data_req_pos_bank1_way[8]),
        .req_data       (data_req_data_bank1_way[8]),

        .ack_valid      (data_ack_valid_bank1_way[8]),
        .ack_retry      (data_ack_retry_bank1_way[8]),
        .ack_data       (data_ack_data_bank1_way[8])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[9]),
        .req_retry      (data_req_retry_bank1_way[9]),
        .req_we         (data_req_we_bank1_way[9]),
        .req_pos        (data_req_pos_bank1_way[9]),
        .req_data       (data_req_data_bank1_way[9]),

        .ack_valid      (data_ack_valid_bank1_way[9]),
        .ack_retry      (data_ack_retry_bank1_way[9]),
        .ack_data       (data_ack_data_bank1_way[9])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[10]),
        .req_retry      (data_req_retry_bank1_way[10]),
        .req_we         (data_req_we_bank1_way[10]),
        .req_pos        (data_req_pos_bank1_way[10]),
        .req_data       (data_req_data_bank1_way[10]),

        .ack_valid      (data_ack_valid_bank1_way[10]),
        .ack_retry      (data_ack_retry_bank1_way[10]),
        .ack_data       (data_ack_data_bank1_way[10])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[11]),
        .req_retry      (data_req_retry_bank1_way[11]),
        .req_we         (data_req_we_bank1_way[11]),
        .req_pos        (data_req_pos_bank1_way[11]),
        .req_data       (data_req_data_bank1_way[11]),

        .ack_valid      (data_ack_valid_bank1_way[11]),
        .ack_retry      (data_ack_retry_bank1_way[11]),
        .ack_data       (data_ack_data_bank1_way[11])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[12]),
        .req_retry      (data_req_retry_bank1_way[12]),
        .req_we         (data_req_we_bank1_way[12]),
        .req_pos        (data_req_pos_bank1_way[12]),
        .req_data       (data_req_data_bank1_way[12]),

        .ack_valid      (data_ack_valid_bank1_way[12]),
        .ack_retry      (data_ack_retry_bank1_way[12]),
        .ack_data       (data_ack_data_bank1_way[12])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[13]),
        .req_retry      (data_req_retry_bank1_way[13]),
        .req_we         (data_req_we_bank1_way[13]),
        .req_pos        (data_req_pos_bank1_way[13]),
        .req_data       (data_req_data_bank1_way[13]),

        .ack_valid      (data_ack_valid_bank1_way[13]),
        .ack_retry      (data_ack_retry_bank1_way[13]),
        .ack_data       (data_ack_data_bank1_way[13])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[14]),
        .req_retry      (data_req_retry_bank1_way[14]),
        .req_we         (data_req_we_bank1_way[14]),
        .req_pos        (data_req_pos_bank1_way[14]),
        .req_data       (data_req_data_bank1_way[14]),

        .ack_valid      (data_ack_valid_bank1_way[14]),
        .ack_retry      (data_ack_retry_bank1_way[14]),
        .ack_data       (data_ack_data_bank1_way[14])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank1_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank1_way[15]),
        .req_retry      (data_req_retry_bank1_way[15]),
        .req_we         (data_req_we_bank1_way[15]),
        .req_pos        (data_req_pos_bank1_way[15]),
        .req_data       (data_req_data_bank1_way[15]),

        .ack_valid      (data_ack_valid_bank1_way[15]),
        .ack_retry      (data_ack_retry_bank1_way[15]),
        .ack_data       (data_ack_data_bank1_way[15])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[0]),
        .req_retry      (data_req_retry_bank2_way[0]),
        .req_we         (data_req_we_bank2_way[0]),
        .req_pos        (data_req_pos_bank2_way[0]),
        .req_data       (data_req_data_bank2_way[0]),

        .ack_valid      (data_ack_valid_bank2_way[0]),
        .ack_retry      (data_ack_retry_bank2_way[0]),
        .ack_data       (data_ack_data_bank2_way[0])
    );

ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[1]),
        .req_retry      (data_req_retry_bank2_way[1]),
        .req_we         (data_req_we_bank2_way[1]),
        .req_pos        (data_req_pos_bank2_way[1]),
        .req_data       (data_req_data_bank2_way[1]),

        .ack_valid      (data_ack_valid_bank2_way[1]),
        .ack_retry      (data_ack_retry_bank2_way[1]),
        .ack_data       (data_ack_data_bank2_way[1])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[2]),
        .req_retry      (data_req_retry_bank2_way[2]),
        .req_we         (data_req_we_bank2_way[2]),
        .req_pos        (data_req_pos_bank2_way[2]),
        .req_data       (data_req_data_bank2_way[2]),

        .ack_valid      (data_ack_valid_bank2_way[2]),
        .ack_retry      (data_ack_retry_bank2_way[2]),
        .ack_data       (data_ack_data_bank2_way[2])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[3]),
        .req_retry      (data_req_retry_bank2_way[3]),
        .req_we         (data_req_we_bank2_way[3]),
        .req_pos        (data_req_pos_bank2_way[3]),
        .req_data       (data_req_data_bank2_way[3]),

        .ack_valid      (data_ack_valid_bank2_way[3]),
        .ack_retry      (data_ack_retry_bank2_way[3]),
        .ack_data       (data_ack_data_bank2_way[3])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[4]),
        .req_retry      (data_req_retry_bank2_way[4]),
        .req_we         (data_req_we_bank2_way[4]),
        .req_pos        (data_req_pos_bank2_way[4]),
        .req_data       (data_req_data_bank2_way[4]),

        .ack_valid      (data_ack_valid_bank2_way[4]),
        .ack_retry      (data_ack_retry_bank2_way[4]),
        .ack_data       (data_ack_data_bank2_way[4])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[5]),
        .req_retry      (data_req_retry_bank2_way[5]),
        .req_we         (data_req_we_bank2_way[5]),
        .req_pos        (data_req_pos_bank2_way[5]),
        .req_data       (data_req_data_bank2_way[5]),

        .ack_valid      (data_ack_valid_bank2_way[5]),
        .ack_retry      (data_ack_retry_bank2_way[5]),
        .ack_data       (data_ack_data_bank2_way[5])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[6]),
        .req_retry      (data_req_retry_bank2_way[6]),
        .req_we         (data_req_we_bank2_way[6]),
        .req_pos        (data_req_pos_bank2_way[6]),
        .req_data       (data_req_data_bank2_way[6]),

        .ack_valid      (data_ack_valid_bank2_way[6]),
        .ack_retry      (data_ack_retry_bank2_way[6]),
        .ack_data       (data_ack_data_bank2_way[6])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[7]),
        .req_retry      (data_req_retry_bank2_way[7]),
        .req_we         (data_req_we_bank2_way[7]),
        .req_pos        (data_req_pos_bank2_way[7]),
        .req_data       (data_req_data_bank2_way[7]),

        .ack_valid      (data_ack_valid_bank2_way[7]),
        .ack_retry      (data_ack_retry_bank2_way[7]),
        .ack_data       (data_ack_data_bank2_way[7])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[8]),
        .req_retry      (data_req_retry_bank2_way[8]),
        .req_we         (data_req_we_bank2_way[8]),
        .req_pos        (data_req_pos_bank2_way[8]),
        .req_data       (data_req_data_bank2_way[8]),

        .ack_valid      (data_ack_valid_bank2_way[8]),
        .ack_retry      (data_ack_retry_bank2_way[8]),
        .ack_data       (data_ack_data_bank2_way[8])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[9]),
        .req_retry      (data_req_retry_bank2_way[9]),
        .req_we         (data_req_we_bank2_way[9]),
        .req_pos        (data_req_pos_bank2_way[9]),
        .req_data       (data_req_data_bank2_way[9]),

        .ack_valid      (data_ack_valid_bank2_way[9]),
        .ack_retry      (data_ack_retry_bank2_way[9]),
        .ack_data       (data_ack_data_bank2_way[9])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[10]),
        .req_retry      (data_req_retry_bank2_way[10]),
        .req_we         (data_req_we_bank2_way[10]),
        .req_pos        (data_req_pos_bank2_way[10]),
        .req_data       (data_req_data_bank2_way[10]),

        .ack_valid      (data_ack_valid_bank2_way[10]),
        .ack_retry      (data_ack_retry_bank2_way[10]),
        .ack_data       (data_ack_data_bank2_way[10])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[11]),
        .req_retry      (data_req_retry_bank2_way[11]),
        .req_we         (data_req_we_bank2_way[11]),
        .req_pos        (data_req_pos_bank2_way[11]),
        .req_data       (data_req_data_bank2_way[11]),

        .ack_valid      (data_ack_valid_bank2_way[11]),
        .ack_retry      (data_ack_retry_bank2_way[11]),
        .ack_data       (data_ack_data_bank2_way[11])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[12]),
        .req_retry      (data_req_retry_bank2_way[12]),
        .req_we         (data_req_we_bank2_way[12]),
        .req_pos        (data_req_pos_bank2_way[12]),
        .req_data       (data_req_data_bank2_way[12]),

        .ack_valid      (data_ack_valid_bank2_way[12]),
        .ack_retry      (data_ack_retry_bank2_way[12]),
        .ack_data       (data_ack_data_bank2_way[12])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[13]),
        .req_retry      (data_req_retry_bank2_way[13]),
        .req_we         (data_req_we_bank2_way[13]),
        .req_pos        (data_req_pos_bank2_way[13]),
        .req_data       (data_req_data_bank2_way[13]),

        .ack_valid      (data_ack_valid_bank2_way[13]),
        .ack_retry      (data_ack_retry_bank2_way[13]),
        .ack_data       (data_ack_data_bank2_way[13])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[14]),
        .req_retry      (data_req_retry_bank2_way[14]),
        .req_we         (data_req_we_bank2_way[14]),
        .req_pos        (data_req_pos_bank2_way[14]),
        .req_data       (data_req_data_bank2_way[14]),

        .ack_valid      (data_ack_valid_bank2_way[14]),
        .ack_retry      (data_ack_retry_bank2_way[14]),
        .ack_data       (data_ack_data_bank2_way[14])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank2_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank2_way[15]),
        .req_retry      (data_req_retry_bank2_way[15]),
        .req_we         (data_req_we_bank2_way[15]),
        .req_pos        (data_req_pos_bank2_way[15]),
        .req_data       (data_req_data_bank2_way[15]),

        .ack_valid      (data_ack_valid_bank2_way[15]),
        .ack_retry      (data_ack_retry_bank2_way[15]),
        .ack_data       (data_ack_data_bank2_way[15])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way0 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[0]),
        .req_retry      (data_req_retry_bank3_way[0]),
        .req_we         (data_req_we_bank3_way[0]),
        .req_pos        (data_req_pos_bank3_way[0]),
        .req_data       (data_req_data_bank3_way[0]),

        .ack_valid      (data_ack_valid_bank3_way[0]),
        .ack_retry      (data_ack_retry_bank3_way[0]),
        .ack_data       (data_ack_data_bank3_way[0])
    );

ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way1 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[1]),
        .req_retry      (data_req_retry_bank3_way[1]),
        .req_we         (data_req_we_bank3_way[1]),
        .req_pos        (data_req_pos_bank3_way[1]),
        .req_data       (data_req_data_bank3_way[1]),

        .ack_valid      (data_ack_valid_bank3_way[1]),
        .ack_retry      (data_ack_retry_bank3_way[1]),
        .ack_data       (data_ack_data_bank3_way[1])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way2 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[2]),
        .req_retry      (data_req_retry_bank3_way[2]),
        .req_we         (data_req_we_bank3_way[2]),
        .req_pos        (data_req_pos_bank3_way[2]),
        .req_data       (data_req_data_bank3_way[2]),

        .ack_valid      (data_ack_valid_bank3_way[2]),
        .ack_retry      (data_ack_retry_bank3_way[2]),
        .ack_data       (data_ack_data_bank3_way[2])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way3 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[3]),
        .req_retry      (data_req_retry_bank3_way[3]),
        .req_we         (data_req_we_bank3_way[3]),
        .req_pos        (data_req_pos_bank3_way[3]),
        .req_data       (data_req_data_bank3_way[3]),

        .ack_valid      (data_ack_valid_bank3_way[3]),
        .ack_retry      (data_ack_retry_bank3_way[3]),
        .ack_data       (data_ack_data_bank3_way[3])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way4 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[4]),
        .req_retry      (data_req_retry_bank3_way[4]),
        .req_we         (data_req_we_bank3_way[4]),
        .req_pos        (data_req_pos_bank3_way[4]),
        .req_data       (data_req_data_bank3_way[4]),

        .ack_valid      (data_ack_valid_bank3_way[4]),
        .ack_retry      (data_ack_retry_bank3_way[4]),
        .ack_data       (data_ack_data_bank3_way[4])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way5 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[5]),
        .req_retry      (data_req_retry_bank3_way[5]),
        .req_we         (data_req_we_bank3_way[5]),
        .req_pos        (data_req_pos_bank3_way[5]),
        .req_data       (data_req_data_bank3_way[5]),

        .ack_valid      (data_ack_valid_bank3_way[5]),
        .ack_retry      (data_ack_retry_bank3_way[5]),
        .ack_data       (data_ack_data_bank3_way[5])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way6 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[6]),
        .req_retry      (data_req_retry_bank3_way[6]),
        .req_we         (data_req_we_bank3_way[6]),
        .req_pos        (data_req_pos_bank3_way[6]),
        .req_data       (data_req_data_bank3_way[6]),

        .ack_valid      (data_ack_valid_bank3_way[6]),
        .ack_retry      (data_ack_retry_bank3_way[6]),
        .ack_data       (data_ack_data_bank3_way[6])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way7 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[7]),
        .req_retry      (data_req_retry_bank3_way[7]),
        .req_we         (data_req_we_bank3_way[7]),
        .req_pos        (data_req_pos_bank3_way[7]),
        .req_data       (data_req_data_bank3_way[7]),

        .ack_valid      (data_ack_valid_bank3_way[7]),
        .ack_retry      (data_ack_retry_bank3_way[7]),
        .ack_data       (data_ack_data_bank3_way[7])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way8 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[8]),
        .req_retry      (data_req_retry_bank3_way[8]),
        .req_we         (data_req_we_bank3_way[8]),
        .req_pos        (data_req_pos_bank3_way[8]),
        .req_data       (data_req_data_bank3_way[8]),

        .ack_valid      (data_ack_valid_bank3_way[8]),
        .ack_retry      (data_ack_retry_bank3_way[8]),
        .ack_data       (data_ack_data_bank3_way[8])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way9 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[9]),
        .req_retry      (data_req_retry_bank3_way[9]),
        .req_we         (data_req_we_bank3_way[9]),
        .req_pos        (data_req_pos_bank3_way[9]),
        .req_data       (data_req_data_bank3_way[9]),

        .ack_valid      (data_ack_valid_bank3_way[9]),
        .ack_retry      (data_ack_retry_bank3_way[9]),
        .ack_data       (data_ack_data_bank3_way[9])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way10 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[10]),
        .req_retry      (data_req_retry_bank3_way[10]),
        .req_we         (data_req_we_bank3_way[10]),
        .req_pos        (data_req_pos_bank3_way[10]),
        .req_data       (data_req_data_bank3_way[10]),

        .ack_valid      (data_ack_valid_bank3_way[10]),
        .ack_retry      (data_ack_retry_bank3_way[10]),
        .ack_data       (data_ack_data_bank3_way[10])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way11 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[11]),
        .req_retry      (data_req_retry_bank3_way[11]),
        .req_we         (data_req_we_bank3_way[11]),
        .req_pos        (data_req_pos_bank3_way[11]),
        .req_data       (data_req_data_bank3_way[11]),

        .ack_valid      (data_ack_valid_bank3_way[11]),
        .ack_retry      (data_ack_retry_bank3_way[11]),
        .ack_data       (data_ack_data_bank3_way[11])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way12 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[12]),
        .req_retry      (data_req_retry_bank3_way[12]),
        .req_we         (data_req_we_bank3_way[12]),
        .req_pos        (data_req_pos_bank3_way[12]),
        .req_data       (data_req_data_bank3_way[12]),

        .ack_valid      (data_ack_valid_bank3_way[12]),
        .ack_retry      (data_ack_retry_bank3_way[12]),
        .ack_data       (data_ack_data_bank3_way[12])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way13 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[13]),
        .req_retry      (data_req_retry_bank3_way[13]),
        .req_we         (data_req_we_bank3_way[13]),
        .req_pos        (data_req_pos_bank3_way[13]),
        .req_data       (data_req_data_bank3_way[13]),

        .ack_valid      (data_ack_valid_bank3_way[13]),
        .ack_retry      (data_ack_retry_bank3_way[13]),
        .ack_data       (data_ack_data_bank3_way[13])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way14 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[14]),
        .req_retry      (data_req_retry_bank3_way[14]),
        .req_we         (data_req_we_bank3_way[14]),
        .req_pos        (data_req_pos_bank3_way[14]),
        .req_data       (data_req_data_bank3_way[14]),

        .ack_valid      (data_ack_valid_bank3_way[14]),
        .ack_retry      (data_ack_retry_bank3_way[14]),
        .ack_data       (data_ack_data_bank3_way[14])
    );

    ram_1port_dense #(DATA_BANK_WIDTH, DATA_BANK_SIZE, 0) data_bank3_way15 (
        .clk            (clk),
        .reset          (reset),
        
        .req_valid      (data_req_valid_bank3_way[15]),
        .req_retry      (data_req_retry_bank3_way[15]),
        .req_we         (data_req_we_bank3_way[15]),
        .req_pos        (data_req_pos_bank3_way[15]),
        .req_data       (data_req_data_bank3_way[15]),

        .ack_valid      (data_ack_valid_bank3_way[15]),
        .ack_retry      (data_ack_retry_bank3_way[15]),
        .ack_data       (data_ack_data_bank3_way[15])
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
        .ack_rd_retry   (ack_rd_q_l1tol2_req_retry),
        .ack_rd_data    (ack_rd_q_l1tol2_req_data)
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
    // Check if the new l1tol2_req has the highest priority
    // TODO
    assign  winner_for_tag = NEW_L1TOL2_REQ;
    // TODO
    // // If the new l2tol2_req is not the winner for tag,
        // it enters l1tol2_req_q, set reg_enqueue_l1tol2_req_1
    assign  predicted_index = {l1tol2_req.ppaddr[2], l1tol2_req.poffset[11:6]}; // For 128
    assign  tag_bank_id = predicted_index[1:0];
    // If it has the highest priority then directly access tag
    assign  read_tag_for_sure = l1tol2_req_valid && (winner_for_tag == NEW_L1TOL2_REQ);
    // Access bank0
    // Access way0
    assign  tag_req_valid_bank0_way[0] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[0] = tag_req_valid_bank0_way[0] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[0] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way1
    assign  tag_req_valid_bank0_way[1] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[1] = tag_req_valid_bank0_way[1] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[1] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way2
    assign  tag_req_valid_bank0_way[2] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[2] = tag_req_valid_bank0_way[2] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[2] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way3
    assign  tag_req_valid_bank0_way[3] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[3] = tag_req_valid_bank0_way[3] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[3] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way4
    assign  tag_req_valid_bank0_way[4] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[4] = tag_req_valid_bank0_way[4] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[4] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way5
    assign  tag_req_valid_bank0_way[5] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[5] = tag_req_valid_bank0_way[5] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[5] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way6
    assign  tag_req_valid_bank0_way[6] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[6] = tag_req_valid_bank0_way[6] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[6] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way7
    assign  tag_req_valid_bank0_way[7] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[7] = tag_req_valid_bank0_way[7] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[7] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way8
    assign  tag_req_valid_bank0_way[8] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[8] = tag_req_valid_bank0_way[8] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[8] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way9
    assign  tag_req_valid_bank0_way[9] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[9] = tag_req_valid_bank0_way[9] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[9] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way10
    assign  tag_req_valid_bank0_way[10] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[10] = tag_req_valid_bank0_way[10] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[10] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way11
    assign  tag_req_valid_bank0_way[11] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[11] = tag_req_valid_bank0_way[11] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[11] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way12
    assign  tag_req_valid_bank0_way[12] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[12] = tag_req_valid_bank0_way[12] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[12] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way13
    assign  tag_req_valid_bank0_way[13] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[13]= tag_req_valid_bank0_way[13] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[13] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way14
    assign  tag_req_valid_bank0_way[14] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[14] = tag_req_valid_bank0_way[14] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[14] = read_tag_for_sure ? predicted_index : 'b0;

    // Access way15
    assign  tag_req_valid_bank0_way[15] = read_tag_for_sure && (tag_bank_id == 2'b00);
    assign  tag_req_we_bank0_way[15] = tag_req_valid_bank0_way[15] ? 0 : 0;// Read tag
    assign  tag_req_pos_bank0_way[15] = read_tag_for_sure ? predicted_index : 'b0;

    // set reg_new_l1tol2_req_tag_access_0
    assign  reg_new_l1tol2_req_tag_access_0_next = read_tag_for_sure;
    assign  l1tol2_req_retry =  (tag_req_valid_bank0_way[0] && tag_req_retry_bank0_way[0]) ||
                                (tag_req_valid_bank0_way[1] && tag_req_retry_bank0_way[1]) ||
                                (tag_req_valid_bank0_way[2] && tag_req_retry_bank0_way[2]) ||
                                (tag_req_valid_bank0_way[3] && tag_req_retry_bank0_way[3]) ||
                                (tag_req_valid_bank0_way[4] && tag_req_retry_bank0_way[4]) ||
                                (tag_req_valid_bank0_way[5] && tag_req_retry_bank0_way[5]) ||
                                (tag_req_valid_bank0_way[6] && tag_req_retry_bank0_way[6]) ||
                                (tag_req_valid_bank0_way[7] && tag_req_retry_bank0_way[7]) ||
                                (tag_req_valid_bank0_way[8] && tag_req_retry_bank0_way[8]) ||
                                (tag_req_valid_bank0_way[9] && tag_req_retry_bank0_way[9]) ||
                                (tag_req_valid_bank0_way[10] && tag_req_retry_bank0_way[10]) ||
                                (tag_req_valid_bank0_way[11] && tag_req_retry_bank0_way[11]) ||
                                (tag_req_valid_bank0_way[12] && tag_req_retry_bank0_way[12]) ||
                                (tag_req_valid_bank0_way[13] && tag_req_retry_bank0_way[13]) ||
                                (tag_req_valid_bank0_way[14] && tag_req_retry_bank0_way[14]) ||
                                (tag_req_valid_bank0_way[15] && tag_req_retry_bank0_way[15]) ||

                                (tag_req_valid_bank1_way[0] && tag_req_retry_bank1_way[0]) ||
                                (tag_req_valid_bank1_way[1] && tag_req_retry_bank1_way[1]) ||
                                (tag_req_valid_bank1_way[2] && tag_req_retry_bank1_way[2]) ||
                                (tag_req_valid_bank1_way[3] && tag_req_retry_bank1_way[3]) ||
                                (tag_req_valid_bank1_way[4] && tag_req_retry_bank1_way[4]) ||
                                (tag_req_valid_bank1_way[5] && tag_req_retry_bank1_way[5]) ||
                                (tag_req_valid_bank1_way[6] && tag_req_retry_bank1_way[6]) ||
                                (tag_req_valid_bank1_way[7] && tag_req_retry_bank1_way[7]) ||
                                (tag_req_valid_bank1_way[8] && tag_req_retry_bank1_way[8]) ||
                                (tag_req_valid_bank1_way[9] && tag_req_retry_bank1_way[9]) ||
                                (tag_req_valid_bank1_way[10] && tag_req_retry_bank1_way[10]) ||
                                (tag_req_valid_bank1_way[11] && tag_req_retry_bank1_way[11]) ||
                                (tag_req_valid_bank1_way[12] && tag_req_retry_bank1_way[12]) ||
                                (tag_req_valid_bank1_way[13] && tag_req_retry_bank1_way[13]) ||
                                (tag_req_valid_bank1_way[14] && tag_req_retry_bank1_way[14]) ||
                                (tag_req_valid_bank1_way[15] && tag_req_retry_bank1_way[15]) ||

                                (tag_req_valid_bank2_way[0] && tag_req_retry_bank2_way[0]) ||
                                (tag_req_valid_bank2_way[1] && tag_req_retry_bank2_way[1]) ||
                                (tag_req_valid_bank2_way[2] && tag_req_retry_bank2_way[2]) ||
                                (tag_req_valid_bank2_way[3] && tag_req_retry_bank2_way[3]) ||
                                (tag_req_valid_bank2_way[4] && tag_req_retry_bank2_way[4]) ||
                                (tag_req_valid_bank2_way[5] && tag_req_retry_bank2_way[5]) ||
                                (tag_req_valid_bank2_way[6] && tag_req_retry_bank2_way[6]) ||
                                (tag_req_valid_bank2_way[7] && tag_req_retry_bank2_way[7]) ||
                                (tag_req_valid_bank2_way[8] && tag_req_retry_bank2_way[8]) ||
                                (tag_req_valid_bank2_way[9] && tag_req_retry_bank2_way[9]) ||
                                (tag_req_valid_bank2_way[10] && tag_req_retry_bank2_way[10]) ||
                                (tag_req_valid_bank2_way[11] && tag_req_retry_bank2_way[11]) ||
                                (tag_req_valid_bank2_way[12] && tag_req_retry_bank2_way[12]) ||
                                (tag_req_valid_bank2_way[13] && tag_req_retry_bank2_way[13]) ||
                                (tag_req_valid_bank2_way[14] && tag_req_retry_bank2_way[14]) ||
                                (tag_req_valid_bank2_way[15] && tag_req_retry_bank2_way[15]) ||

                                (tag_req_valid_bank3_way[0] && tag_req_retry_bank3_way[0]) ||
                                (tag_req_valid_bank3_way[1] && tag_req_retry_bank3_way[1]) ||
                                (tag_req_valid_bank3_way[2] && tag_req_retry_bank3_way[2]) ||
                                (tag_req_valid_bank3_way[3] && tag_req_retry_bank3_way[3]) ||
                                (tag_req_valid_bank3_way[4] && tag_req_retry_bank3_way[4]) ||
                                (tag_req_valid_bank3_way[5] && tag_req_retry_bank3_way[5]) ||
                                (tag_req_valid_bank3_way[6] && tag_req_retry_bank3_way[6]) ||
                                (tag_req_valid_bank3_way[7] && tag_req_retry_bank3_way[7]) ||
                                (tag_req_valid_bank3_way[8] && tag_req_retry_bank3_way[8]) ||
                                (tag_req_valid_bank3_way[9] && tag_req_retry_bank3_way[9]) ||
                                (tag_req_valid_bank3_way[10] && tag_req_retry_bank3_way[10]) ||
                                (tag_req_valid_bank3_way[11] && tag_req_retry_bank3_way[11]) ||
                                (tag_req_valid_bank3_way[12] && tag_req_retry_bank3_way[12]) ||
                                (tag_req_valid_bank3_way[13] && tag_req_retry_bank3_way[13]) ||
                                (tag_req_valid_bank3_way[14] && tag_req_retry_bank3_way[14]) ||
                                (tag_req_valid_bank3_way[15] && tag_req_retry_bank3_way[15]);


    // Handle input from l2tlb
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
    assign hpaddr_from_tag[0] = tag_ack_data_bank0_way[0]; // TODO extract hpaddr
    assign hpaddr_from_tag[1] = tag_ack_data_bank0_way[1]; // TODO extract hpaddr
    assign hpaddr_from_tag[2] = tag_ack_data_bank0_way[2]; // TODO extract hpaddr
    assign hpaddr_from_tag[3] = tag_ack_data_bank0_way[3]; // TODO extract hpaddr
    assign hpaddr_from_tag[4] = tag_ack_data_bank0_way[4]; // TODO extract hpaddr
    assign hpaddr_from_tag[5] = tag_ack_data_bank0_way[5]; // TODO extract hpaddr
    assign hpaddr_from_tag[6] = tag_ack_data_bank0_way[6]; // TODO extract hpaddr
    assign hpaddr_from_tag[7] = tag_ack_data_bank0_way[7]; // TODO extract hpaddr
    assign hpaddr_from_tag[8] = tag_ack_data_bank0_way[8]; // TODO extract hpaddr
    assign hpaddr_from_tag[9] = tag_ack_data_bank0_way[9]; // TODO extract hpaddr
    assign hpaddr_from_tag[10] = tag_ack_data_bank0_way[10]; // TODO extract hpaddr
    assign hpaddr_from_tag[11] = tag_ack_data_bank0_way[11]; // TODO extract hpaddr
    assign hpaddr_from_tag[12] = tag_ack_data_bank0_way[12]; // TODO extract hpaddr
    assign hpaddr_from_tag[13] = tag_ack_data_bank0_way[13]; // TODO extract hpaddr
    assign hpaddr_from_tag[14] = tag_ack_data_bank0_way[14]; // TODO extract hpaddr
    assign hpaddr_from_tag[15] = tag_ack_data_bank0_way[15]; // TODO extract hpaddr

    // Handle tag result
    // reg_new_l1tol2_req_tag_access_2
    always_comb begin
        tag_hit_next = 0;
        if (reg_new_l1tol2_req_tag_access_2) begin
            // Tag access result is ready
            if (l2tlbtol2_fwd_reg1_valid && l1_match_l2tlb_l1id && l1_match_l2tlb_ppaddr) begin
                // l1id matched and ppaddr is correct
                case (1'b1)
                    // Check way0
                    (tag_ack_valid_bank0_way[0] && (hpaddr_from_tag[0] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_0000_0001;
                    end
                    // Check way1
                    (tag_ack_valid_bank0_way[1] && (hpaddr_from_tag[1] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_0000_0010;
                    end
                    // Check way2
                    (tag_ack_valid_bank0_way[2] && (hpaddr_from_tag[2] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_0000_0100;
                    end
                    // Check way3
                    (tag_ack_valid_bank0_way[3] && (hpaddr_from_tag[3] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_0000_1000;
                    end
                    // Check way4
                    (tag_ack_valid_bank0_way[4] && (hpaddr_from_tag[4] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_0001_0000;
                    end
                    // Check way5
                    (tag_ack_valid_bank0_way[5] && (hpaddr_from_tag[5] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_0010_0000;
                    end
                    // Check way6
                    (tag_ack_valid_bank0_way[6] && (hpaddr_from_tag[6] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_0100_0000;
                    end
                    // Check way7
                    (tag_ack_valid_bank0_way[7] && (hpaddr_from_tag[7] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0000_1000_0000;
                    end
                    // Check way8
                    (tag_ack_valid_bank0_way[8] && (hpaddr_from_tag[8] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0001_0000_0000;
                    end
                    // Check way9
                    (tag_ack_valid_bank0_way[9] && (hpaddr_from_tag[9] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0010_0000_0000;
                    end
                    // Check way10
                    (tag_ack_valid_bank0_way[10] && (hpaddr_from_tag[10] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_0100_0000_0000;
                    end
                    // Check way11
                    (tag_ack_valid_bank0_way[11] && (hpaddr_from_tag[11] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0000_1000_0000_0000;
                    end
                    // Check way12
                    (tag_ack_valid_bank0_way[12] && (hpaddr_from_tag[12] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0001_0000_0000_0000;
                    end
                    // Check way13
                    (tag_ack_valid_bank0_way[13] && (hpaddr_from_tag[13] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0010_0000_0000_0000;
                    end
                    // Check way14
                    (tag_ack_valid_bank0_way[14] && (hpaddr_from_tag[14] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b0100_0000_0000_0000;
                    end
                    // Check way15
                    (tag_ack_valid_bank0_way[15] && (hpaddr_from_tag[15] == l2tlbtol2_fwd_reg1.hpaddr)) : begin
                        // (hpaddr) Tag hit
                        tag_hit_next = 1;
                        hit_way_next = 16'b1000_0000_0000_0000;
                    end
                endcase
            end
        end
    end

    // Access data bank under tag hit
    // @ reg_new_l1tol2_req_tag_access_2
    // TODO Pass retry to previous stages: should be l2tlbtol2_fwd_retry and l1tol2_req_reg2_retry
    assign  data_req_valid_bank0_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0001);
    assign  data_req_we_bank0_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[0] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};
   
    assign  data_req_valid_bank0_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0010);
    assign  data_req_we_bank0_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[1] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0100);
    assign  data_req_we_bank0_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[2] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_1000);
    assign  data_req_we_bank0_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[3] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0001_0000);
    assign  data_req_we_bank0_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[4] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0010_0000);
    assign  data_req_we_bank0_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[5] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0100_0000);
    assign  data_req_we_bank0_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[6] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_1000_0000);
    assign  data_req_we_bank0_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[7] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0001_0000_0000);
    assign  data_req_we_bank0_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[8] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0010_0000_0000);
    assign  data_req_we_bank0_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[9] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0100_0000_0000);
    assign  data_req_we_bank0_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[10] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_1000_0000_0000);
    assign  data_req_we_bank0_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[11] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0001_0000_0000_0000);
    assign  data_req_we_bank0_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[12] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0010_0000_0000_0000);
    assign  data_req_we_bank0_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[13] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0100_0000_0000_0000);
    assign  data_req_we_bank0_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[14] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank0_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b1000_0000_0000_0000);
    assign  data_req_we_bank0_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank0_way[15] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0001);
    assign  data_req_we_bank1_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[0] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};
   
    assign  data_req_valid_bank1_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0010);
    assign  data_req_we_bank1_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[1] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0100);
    assign  data_req_we_bank1_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[2] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_1000);
    assign  data_req_we_bank1_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[3] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0001_0000);
    assign  data_req_we_bank1_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[4] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0010_0000);
    assign  data_req_we_bank1_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[5] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0100_0000);
    assign  data_req_we_bank1_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[6] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_1000_0000);
    assign  data_req_we_bank1_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[7] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0001_0000_0000);
    assign  data_req_we_bank1_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[8] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0010_0000_0000);
    assign  data_req_we_bank1_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[9] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0100_0000_0000);
    assign  data_req_we_bank1_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[10] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_1000_0000_0000);
    assign  data_req_we_bank1_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[11] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0001_0000_0000_0000);
    assign  data_req_we_bank1_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[12] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0010_0000_0000_0000);
    assign  data_req_we_bank1_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[13] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0100_0000_0000_0000);
    assign  data_req_we_bank1_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[14] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank1_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b1000_0000_0000_0000);
    assign  data_req_we_bank1_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b01) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank1_way[15] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0001);
    assign  data_req_we_bank2_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[0] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};
   
    assign  data_req_valid_bank2_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0010);
    assign  data_req_we_bank2_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[1] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0100);
    assign  data_req_we_bank2_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[2] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_1000);
    assign  data_req_we_bank2_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[3] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0001_0000);
    assign  data_req_we_bank2_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[4] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0010_0000);
    assign  data_req_we_bank2_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[5] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0100_0000);
    assign  data_req_we_bank2_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[6] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_1000_0000);
    assign  data_req_we_bank2_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[7] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0001_0000_0000);
    assign  data_req_we_bank2_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[8] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0010_0000_0000);
    assign  data_req_we_bank2_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[9] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0100_0000_0000);
    assign  data_req_we_bank2_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[10] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_1000_0000_0000);
    assign  data_req_we_bank2_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[11] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0001_0000_0000_0000);
    assign  data_req_we_bank2_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[12] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0010_0000_0000_0000);
    assign  data_req_we_bank2_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[13] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0100_0000_0000_0000);
    assign  data_req_we_bank2_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[14] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank2_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b1000_0000_0000_0000);
    assign  data_req_we_bank2_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b10) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank2_way[15] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b00) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0001);
    assign  data_req_we_bank3_way[0] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[0] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};
   
    assign  data_req_valid_bank3_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0010);
    assign  data_req_we_bank3_way[1] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[1] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_0100);
    assign  data_req_we_bank3_way[2] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[2] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0000_1000);
    assign  data_req_we_bank3_way[3] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[3] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0001_0000);
    assign  data_req_we_bank3_way[4] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[4] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0010_0000);
    assign  data_req_we_bank3_way[5] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[5] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_0100_0000);
    assign  data_req_we_bank3_way[6] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[6] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0000_1000_0000);
    assign  data_req_we_bank3_way[7] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[7] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0001_0000_0000);
    assign  data_req_we_bank3_way[8] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[8] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0010_0000_0000);
    assign  data_req_we_bank3_way[9] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[9] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_0100_0000_0000);
    assign  data_req_we_bank3_way[10] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[10] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0000_1000_0000_0000);
    assign  data_req_we_bank3_way[11] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[11] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0001_0000_0000_0000);
    assign  data_req_we_bank3_way[12] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[12] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0010_0000_0000_0000);
    assign  data_req_we_bank3_way[13] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[13] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b0100_0000_0000_0000);
    assign  data_req_we_bank3_way[14] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[14] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

    assign  data_req_valid_bank3_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 && tag_hit_next && (hit_way_next == 16'b1000_0000_0000_0000);
    assign  data_req_we_bank3_way[15] = (l1tol2_req_reg3.poffset[7:6]==2'b11) && reg_new_l1tol2_req_tag_access_2 ? 0 : 0; // read
    assign  data_req_pos_bank3_way[15] = {l1tol2_req_reg3.ppaddr[2], l1tol2_req_reg3.poffset[11:6]};

`endif
endmodule

