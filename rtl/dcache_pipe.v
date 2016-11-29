`include "scmem.vh"
`include "logfunc.h"
`define     DC_PASSTHROUGH
`define     FFLOP_HANDLE
//`define    COMPLETE

`ifdef COMPLETE
// define states for the state machine
`define       IDLE                   0

`define       LOAD_PROC              1
`define       LOAD_COREID_FAULT      2
`define       LOAD_MISS              3
`define       LOAD_HIT               4

`define       SNOOP_PROC             5
`define       STORE_PROC             6
typedef logic [7:0] state_type;

state_type  stage1_current_state;
state_type  stage1_next_state;
state_type  stage2_current_state;
state_type  stage2_next_state;
state_type  stage3_current_state;
state_type  stage3_next_state;
// end define states

///////////////////////////////////////////////////////////
// 2 to 1 MUX
///////////////////////////////////////////////////////////
module mux (
  a,
  sel,
  b
);

parameter Value = 0;
parameter Width = 1;

input [Width-1:0]  a;
input              sel;
output [Width-1:0] b;

assign b = (sel)?Value:a;

endmodule
///////////////////////////////////////////////////////////
// FIFO BUFFER
///////////////////////////////////////////////////////////
module fifo_buffer (
  clk,
  reset,

  write_en,
  data_in,
  data_in_valid,
  data_in_retry,

  read_en,
  data_out,
  data_out_valid,
  data_out_retry,
  
  empty,
  full
);

// Parameterize the module
parameter DATA_WIDTH = 8;
parameter ENTRIES = 8;
parameter ADDR_WIDTH = log2(ENTRIES);
// Port declaration
input                   clk;
input                   reset;

input                   write_en;
input [DATA_WIDTH-1:0]  data_in;
input                   data_in_valid;
output                  data_in_retry;

input                   read_en;
output [DATA_WIDTH-1:0] data_out;
output                  data_out_valid;
input                   data_out_retry;

output                  empty;
output                  full;
// Internal signals
logic [DATA_WIDTH-1:0]    req_data;
logic                     req_valid;
logic                     req_retry;
logic                     req_we;
logic [ADDR_WIDTH-1:0]    req_pos;
logic [DATA_WIDTH-1:0]    ack_data;
logic                     ack_valid;
logic                     ack_retry;

//clear on reset
//reset state machie
logic [ADDR_WIDTH-1:0] reset_count;
always @(posedge reset or posedge clk) begin
  if (posedge reset) begin
    reset_count <= 0;
  end

  if (reset) begin
    reset_count <= reset_count + 1; 
  end
end

//status counter
logic [ADDR_WIDTH  :0] status_counter;
logic [ADDR_WIDTH-1:0] read_pointer;
logic [ADDR_WIDTH-1:0] write_pointer;
always @(posedge clk or posedge reset) begin
  if (reset) begin
    status_counter <= 0;
    read_pointer <= 0;
    write_pointer <= 0;
  end else begin 
    if (write_en && !read_en && status_count<ENTRIES) begin
      status_count <= status_count + 1;
      write_pointer <= write_pointer + 1;
    end else if (read_en && !write_en && status_count!=0) begin
      status_count <= status_count - 1;
      read_pointer <= read_pointer + 1;
    end
  end
end

// write/read handle
always_comb begin
  if (reset) begin
    req_data = 0;
    req_we = 1;
    req_pos = reset_count;
  end else begin
    if (write_en && !read_en) begin
      req_we = 1;
      req_pos = write_pointer;
    end else begin
      req_we = 0;
      req_pos = read_pointer;
    end
    req_valid = data_in_valid;
    req_data = data_in;
    data_out_retry = req_retry;
    ack_retry = 0;
    data_out_valid = ack_valid && (status_count != 0);
    data_in_retry = (status_count == ENTRIES);
  end
end

// empty and full signal handle
always_comb begin
  full = (status_count == ENTRIES);
  empty = (status_count == 0);
end

// instantiate the ram block
ram_1port_fast 
  #(.Width(DATA_WIDTH), .Size(ENTRIES)) 
storage (
  .clk                (clk),
  .reset              (reset),

  .req_valid          (req_valid),
  .req_retry          (req_retry),
  .req_we             (req_we),
  .req_pos            (req_pos),
  .req_data           (req_data),

  .ack_valid          (ack_valid),
  .ack_retry          (ack_retry),
  .ack_data           (ack_data)
);


endmodule

///////////////////////////////////////////////////////////
// DATA CACHE TAG BANK
///////////////////////////////////////////////////////////
`define TAGBANK_ENTRIES 32
`define INDEX_SIZE      5
`define TAG_SIZE        11

typedef struct packed {
  logic [TAG_SIZE-1:0]    tag;
  logic [2:0]             state;
  logic [1:0]             count; // for replacement policy
} tagbank_data_type;

typedef struct packet {
  logic                   hit;
  logic [2:0]             state;
} tagbank_output_type

module dcache_tagbank(
  input                        clk,
  input                        reset,
  input                        enable,

  input                        write, //write==0 implies read

  input                        data_valid,
  output                       data_retry,
  input   tagbank_data_type    data,
 
  input   [INDEX_SIZE-1:0]     index,

  output                       tagbank_output_valid,
  input                        tagbank_output_retry,
  output  tagbank_output_type  tagbank_output

);


logic data_retry_1;
logic data_retry_2;
logic data_retry_3;
logic data_retry_4;
logic data_retry_5;
logic data_retry_6;
logic data_retry_7;
logic data_retry_8;
logic ack_valid_1;
logic ack_valid_2;
logic ack_valid_3;
logic ack_valid_4;
logic ack_valid_5;
logic ack_valid_6;
logic ack_valid_7;
logic ack_valid_8;
tagbank_data_type way1_data;
tagbank_data_type way2_data;
tagbank_data_type way3_data;
tagbank_data_type way4_data;
tagbank_data_type way5_data;
tagbank_data_type way6_data;
tagbank_data_type way7_data;
tagbank_data_type way8_data;

// WAY 1
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way1 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_1),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_1),
  .ack_retry          (hit_retry),
  .ack_data           (way1_data)
);


// WAY 2
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way2 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_2),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_2),
  .ack_retry          (hit_retry),
  .ack_data           (way2_data)
);

// WAY 3
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way3 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_3),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_3),
  .ack_retry          (hit_retry),
  .ack_data           (way3_data)
);

// WAY 4
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way4 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_4),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_4),
  .ack_retry          (hit_retry),
  .ack_data           (way4_data)
);

// WAY 5
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way4 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_5),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_5),
  .ack_retry          (hit_retry),
  .ack_data           (way5_data)
);

// WAY 6
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way4 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_6),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_6),
  .ack_retry          (hit_retry),
  .ack_data           (way6_data)
);

// WAY 7
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way4 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_7),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_7),
  .ack_retry          (hit_retry),
  .ack_data           (way7_data)
);

// WAY 8
ram_1port_fast 
#(.Width($bits(tagbank_data_type)), .Size(TAGBANK_ENTRIES)) 
way4 (
  .clk                (clk&enable),
  .reset              (reset),

  .req_valid          (data_valid),
  .req_retry          (data_retry_8),
  .req_we             (write),
  .req_pos            (index),
  .req_data           (data),

  .ack_valid          (ack_valid_8),
  .ack_retry          (hit_retry),
  .ack_data           (way8_data)
);
logic [7:0] hits;
always_comb begin
  data_retry = data_retry_1&data_retry_2&data_retry_3&data_retry_4&data_retry_5&data_retry_6&data_retry_7&data_retry_8;
  hit_valid = ack_valid_1&ack_valid_2&ack_valid_3&ack_valid_4&ack_valid_5&ack_valid_6&ack_valid_7&ack_valid_8;
  hits = {(way1_data.tag == tag),
          (way2_data.tag == tag),
          (way3_data.tag == tag),
          (way4_data.tag == tag),
          (way5_data.tag == tag),
          (way6_data.tag == tag),
          (way7_data.tag == tag),
          (way8_data.tag == tag)};
end

logic [2:0] cache_line_state;
always_comb begin
  if (hit_valid) begin
    case (hits)
      8'b10000000: cache_line_state = way1_data.state; 
      8'b01000000: cache_line_state = way2_data.state; 
      8'b00100000: cache_line_state = way3_data.state; 
      8'b00010000: cache_line_state = way4_data.state; 
      8'b00001000: cache_line_state = way5_data.state; 
      8'b00000100: cache_line_state = way6_data.state; 
      8'b00000010: cache_line_state = way7_data.state; 
      8'b00000001: cache_line_state = way8_data.state; 
    endcase
  end
end

always_comb begin
  line_state = cache_line_state;
end
endmodule
`endif
// L1 CACHE
// L1 detailed description:
// 16KB, 8 way, 8 banks
//
// Each bank 64bit data wide. Stores and Loads to 
// different banks can happen in the same cycle. 
// 
// 4 oustanding requests queues:
//
// Load_miss_queue, store_queue, pref_queue, snoop_queue
//
// load_miss_queue allocated on load cache miss. Configurable size 8 or 16
//
// store_queue allocated when a store is received. The loads must check
// against outstanding stores. The store queue has data, and it keeps 4 or 8
// stores.
//
// The loads have higher priority than stores, prefetches have the lowest
// priority, and snoops have higher priority than stores.
//
// The snoop_queue has 2 entries. If the snoop queue is full or it has been
// with an entry over 4 cycles, all the other inputs are set to retry, and
// the snoops are drained with the highest priority.
//
// L1 cache replacement: 3-bit RRIP (Static). Prefetch has low priority (7).
// Store misses allocate likely low (6), load use between 0-5 using the RRIP
// paper policy.
//
// It time permits, once the project works it may be good to have a small
// victim cache under the DL1 to tolerate higher store conflicts. 8 entry VC
// with entries allocated at L1 conflict capacity.
//
//-----------------------------
//
// L1 data cache
//
// UMESI states:
//
// M: Modified and coherent (typical M state)
//
// UM: Locally modified and uncoherent, must synchronize using word mask
// before committing/sync
//
// E: Exclusive and coherent (typical E state)
//
// UE: Exclusive and uncoherent. If COMMIT in this state, it can be
// transitioned to E state. If SYNC in this state, it MUST be transitioned to
// E state.
//
// If UE and invalidated is recived, a US is generated.
//
// S: Exclusive and coherent (typical S state)
//
// US: Uncoherent and shared. If there is a normal commit, the line must be
// discarded (I). If there is a parallel spec check commit. The task must be
// restarted because it had a speculative read and it got restarted.
//
// I or UI: Invalid, no difference
//
// The dcache supports two types of transactions:
//
// core_CKP_BEGIN_S (store-only checkpoints)
// core_CKP_BEGIN_LS (load and store checkpoints)
//
// The cache is has operating modes Either Store-only transaction, load-store
// transaction, or no transaction 
// 
//
// rules in no-transction mode:
//
//  +Similar to MESI coherence, but the lines can be also in U state. The
//  allowed states are M, UM, S, US, E, I
//
//  +The task never aborts, the KILL/RESTART perform a COMMIT which is the
//  same as new MOP_BEGIN executed at retirement.
//
//  +The cache lines are not marked with any version
//
//  +Request with PNR set are performed immediately even if device access
//
// rules in Store-only transaction mode:
//
//  +Stores pindown or lock the cache line. lock lines can not be replaced.
//
//  +A cache line can be lock by a single store checkpoint id.
//
//  +A load reads hitting multiple lines with same address but different
//  versions performs a read to the line with the newest version.
//
//  +Loads do not lock the cache. As a result no atomics can be done.
//
//  +No atomic operations are allowed.
//
//  +Stores can not be visible outside the cache until the task commits.
//
//  +Store-only transactions are un-ordered across cores but ordered within
//  core. COMMIT is performed as soon as COMMIT instruction retires.
//
//  +Transactions are strictly ordered within core. If an older transaction
//  aborts, the newer transaction has to abort too.
//
//  +Multiple transactions can start (called decode) before they finish
//  (called retirement). As a result, multiple transactions can be in-flight.
//  The system is sized to handle around 8 in-flight transactions with 32
//  stores per transaction on average.
//
//  +Similar to MESI coherence, but the lines can be also in U state. The
//  stores MUST go to UM (no M allowed). The allowed states are I,UM,S,US,E
//
//
//  +A cacheline has 8bits (one per version) to indicate the the line is
//  locked. When a store is performed, if there is no other pindown line
//  with the same address, the new line or existing line is marked with the
//  version. If another line is pin lock, a copy is performed for the new
//  store, and the oldest is marked with the new version too.
//
//
// rules in Load-Store transaction mode:
//
//  +Load-store checkpoints, both loads and stores pindown the checkpoint in
//  a given version.
//
//  +A cache line can be lock by a single store/load checkpoint id.
//
//  +Loads and stores trigger a cacheline lock.
//
//  +Load-Store transactions are ordered (BEGIN_OLS) or un-ordered (BEGIN_ULS)
//  across cores and always ordered within core. The order across transactions
//  in the system is using the checkpoint version provided at BEGIN_LS (data
//  field).
//
//  +COMMIT is performed as soon as COMMIT instruction retires. The core
//  sending the COMMIT is responsible to send the COMMIT only when all the
//  previous transactions have sent a COMMIT (BEGIN_OLS). Commits across
//  cores must be ordered (BEGIN_OLS).
//
//  +Transactions are strictly ordered within core. If an older transaction
//  aborts, the newer transaction has to abort too. The core is responsible to
//  send a KILL in other cores (not local) when older version are running.
//
//  +When a KILL is received with a younger version number (data field), all
//  the older lines must be invalidated. Notice that this applies only to
//  orddered transactions. Unordered transaction ignore the kill command
//  unless the ckeckpoint id matches.
//
//  +Atomic operations can only be done with load-store transaction mode.
//
// rules in in any transaction mode:
//
//  +An access to a device access (LD/ST) is not performed unless the LD/ST
//  commes with the pnr flag set. An nc_abort is triggered for device unless
//  the pnr flag is set.
//
//  +When a COMMIT happens, if there is a single version maching, the line is
//  marked as not speculative. If there are more versions marked, the version
//  in the line is cleared a state machine must be called to decide which
//  lines get invalidated and which marked as non-speculative. Same for CSYNC,
//  but it delayes the ack until all the lines are non-speculative and in MESI
//  states.
//
//  +Transactions can abort if no buffering space is available. Loads and
//  stores may not perform if the buffering (associativity) demand requires
//  more cache lines than associativility available. In this case, the resonse
//  sends an overflow message. The core is responsible to abort the
//  transaction or to resend the load later or with pnr which specifically means
//  that it is not versioned. The latest may be fine for Device access or when
//  there is a guarantee of not restarting.
//
//  +Non-Cacheable lines are kept in cache until MOP_COMMIT or MOP_CSYNC. At
//  this point, all the lines accessed with NC (but not device) are writeback
//  invalidated (M) or invalidated (E/S). Noth MOP_COMMIT and MOP_CSYNC would
//  be delayed until all the NC are written back/invalidated. 
//
//  +The difference between MOP_CSYNC and MOP_COMMIT is that the U states are
//  allowed to be kept with MOP_COMMIT while MOP_CSYNC acknowledge will wait
//  until all the lines in the current checkpoint remove the U state.
//
// The cache is optimized to have 8 in-flight version. This means that each
// cacheline has 8 bits indicating if the line is "lock/pindown" for a given
// version.
//
// A load/store to a non-cachable/device memory is not performed unless it has
// the pnr (Point of Non-Return) bit set during request. When the load/store
// is the oldest in the processor and there is guarantee of not restarting the
// transaction, the core can set the pnr bit for all the memory operations to
// avoid the costly reflow of device operations. 
//
// Non-aligned accesses will result in generating 2 dcache requests (to
// different pipes). In theory, one can be NC/Dev and the other cacheable
// (different pages). In this case, the core should get a reflow for the NC
// and nothing special from the other slice.
//
//
// Load store exclusive is implemented as a load-store transaction memory mode
// where the load pins down the memory and the store performs a commit
// afterwards. If another core triggers an invalidate, the transaction is
// aborted. The remote invalidation is detected when the COMMIT is sent. The
// commit ack is generated with an overflow flag set.
//
// Sample sequence operations:
//
// MOP_BEGIN_OLS // Called at decode
// LD [b],a
// add a,a,1
// ST [b],a
// MOP_BEGIN_S // BEGIN_S called at decode, CSYNC at retirement
// LD [b],a // does not pindown the line
// LD [c],d  // Must be a+1 
// add a,a,1
// ST [b],a
// ...
// LD [b],e  // a == e ; Must be the same, line was pindown
// LD [c],f  // f == d || f != d ; Another core may have change the value
// MOP_COMMIT // BEGIN_S at decode, COMMIT at retirement
// LD [a],f
// MOP_BEGIN // BEGIN called at decode, CSYNC at retirement
// ST [b],a // should be in M if it was M, otherwise UM
// ..
// MOP_BEGIN // called at decode, CSYNC at retirement (not much effect)
// ST [b],a 
// MOP_CSYNC // BEGIN called at decode, CSYNC called at retirement
//
// For ordered transactions, based on the src_nid and src_ckpid (!= 0), the
// dcache can get the version number of the checkpoint. This allows to compare
// the local and remote version to know if there is a restart.
//
// Order of implementation:
//
//  no transaction mode
//  st transaction mode
//  ld-st transaction mode (Not for cmpe220, too much)
//

module dcache_pipe(
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
   input clk
  ,input reset

  //---------------------------
  // core interface LD
  ,input                           coretodc_ld_valid
  ,output                          coretodc_ld_retry
  ,input  I_coretodc_ld_type       coretodc_ld

  ,output                          dctocore_ld_valid
  ,input                           dctocore_ld_retry
  ,output I_dctocore_ld_type       dctocore_ld

  //---------------------------
  // core interface STD
  ,input                           coretodc_std_valid
  ,output                          coretodc_std_retry
  ,input  I_coretodc_std_type      coretodc_std

  ,output                          dctocore_std_ack_valid
  ,input                           dctocore_std_ack_retry
  ,output I_dctocore_std_ack_type  dctocore_std_ack

  //---------------------------
  // core Prefetch interface
  ,output PF_cache_stats_type      cachetopf_stats

  //---------------------------
  // TLB interface
 
  // TLB interface LD
  ,input                           l1tlbtol1_fwd0_valid
  ,output                          l1tlbtol1_fwd0_retry
  ,input  I_l1tlbtol1_fwd_type     l1tlbtol1_fwd0
  // TLB interface STD
  ,input                           l1tlbtol1_fwd1_valid
  ,output                          l1tlbtol1_fwd1_retry
  ,input  I_l1tlbtol1_fwd_type     l1tlbtol1_fwd1

  // Notify the L1 that the index of the TLB is gone
  ,input                           l1tlbtol1_cmd_valid
  ,output                          l1tlbtol1_cmd_retry
  ,input  I_l1tlbtol1_cmd_type     l1tlbtol1_cmd

  //---------------------------
  // L2 interface (same for IC and DC)
  ,output                          l1tol2tlb_req_valid
  ,input                           l1tol2tlb_req_retry
  ,output I_l1tol2tlb_req_type     l1tol2tlb_req

  ,output                          l1tol2_req_valid
  ,input                           l1tol2_req_retry
  ,output I_l1tol2_req_type        l1tol2_req

  ,input                           l2tol1_snack_valid
  ,output                          l2tol1_snack_retry
  ,input  I_l2tol1_snack_type      l2tol1_snack

  ,output                          l1tol2_snoop_ack_valid
  ,input                           l1tol2_snoop_ack_retry
  ,output I_l2snoop_ack_type       l1tol2_snoop_ack

  ,output                          l1tol2_disp_valid
  ,input                           l1tol2_disp_retry
  ,output I_l1tol2_disp_type       l1tol2_disp

  ,input                           l2tol1_dack_valid
  ,output                          l2tol1_dack_retry
  ,input  I_l2tol1_dack_type       l2tol1_dack

  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
);
`ifdef FFLOP_HANDLE
//--------------------------------------------
// HANDLE FLUID FLOPS
// Flop all the inputs and outputs
//--------------------------------------------
//
// Fluid flop interface
//
//                  ----------
//                  |        |
//      valid_in--->|        |--->valid_out
//     retry_out<---|        |<---retry_in
//                  |        |
//                  ----------
//
//--------------------------------------------

  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
// CORE TO DC (LOAD)-------------------------------------------------
I_coretodc_ld_type coretodc_ld_current; // data coming in
logic ff_coretodc_ld_valid_in;
logic ff_coretodc_ld_valid_out;
logic ff_coretodc_ld_retry_in;
logic ff_coretodc_ld_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign ff_coretodc_ld_valid_in = coretodc_ld_valid;
assign coretodc_ld_retry = ff_coretodc_ld_retry_out;

// instantiate fluid flop
fflop #(.Size($bits(I_coretodc_ld_type))) ff_coretodc_ld (
  .clk      (clk),
  .reset    (reset),

  .din      (coretodc_ld),
  .dinValid (ff_coretodc_ld_valid_in),
  .dinRetry (ff_coretodc_ld_retry_out),

  .q        (coretodc_ld_current),
  .qValid   (ff_coretodc_ld_valid_out),
  .qRetry   (ff_coretodc_ld_retry_in) 
);


// DC TO CORE (LOAD)-------------------------------------------------
I_dctocore_ld_type dctocore_ld_current; // data going out 
logic ff_dctocore_ld_valid_in;
logic ff_dctocore_ld_valid_out;
logic ff_dctocore_ld_retry_in;
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
logic ff_dctocore_ld_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

//hook up the wires
assign dctocore_ld_valid = ff_dctocore_ld_valid_out;
assign ff_dctocore_ld_retry_in = dctocore_ld_retry;

// instantiate fluid flop
fflop #(.Size($bits(I_dctocore_ld_type))) ff_dctocore_ld (
  .clk      (clk),
  .reset    (reset),

  .din      (dctocore_ld_current),
  .dinValid (ff_dctocore_ld_valid_in),
  .dinRetry (ff_dctocore_ld_retry_out),

  .q        (dctocore_ld),
  .qValid   (ff_dctocore_ld_valid_out),
  .qRetry   (ff_dctocore_ld_retry_in) 
);


// CORE TO DC (STORE)------------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_coretodc_std_type coretodc_std_current; // data coming in
logic ff_coretodc_std_valid_in;
logic ff_coretodc_std_valid_out;
logic ff_coretodc_std_retry_in;
logic ff_coretodc_std_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign ff_coretodc_std_valid_in = coretodc_std_valid;
assign coretodc_std_retry = ff_coretodc_std_retry_out;

// instantiate fluid flop
fflop #(.Size($bits(I_coretodc_std_type))) ff_coretodc_std (
  .clk      (clk),
  .reset    (reset),

  .din      (coretodc_std),
  .dinValid (ff_coretodc_std_valid_in),
  .dinRetry (ff_coretodc_std_retry_out),

  .q        (coretodc_std_current),
  .qValid   (ff_coretodc_std_valid_out),
  .qRetry   (ff_coretodc_std_retry_in) 
);


// DC TO CORE (STORE ACK)--------------------------------------------
I_dctocore_std_ack_type dctocore_std_ack_current; // data going out
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
logic ff_dctocore_std_ack_valid_in;
logic ff_dctocore_std_ack_valid_out;
logic ff_dctocore_std_ack_retry_in;
logic ff_dctocore_std_ack_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign dctocore_std_ack_valid = ff_dctocore_std_ack_valid_out;
assign ff_dctocore_std_ack_retry_in = dctocore_std_ack_retry;

// instantiate fluid flop
fflop #(.Size($bits(I_dctocore_std_ack_type))) ff_dctocore_std_ack (
  .clk      (clk),
  .reset    (reset),

  .din      (dctocore_std_ack_current),
  .dinValid (ff_dctocore_std_ack_valid_in),
  .dinRetry (ff_dctocore_std_ack_retry_out),

  .q        (dctocore_std_ack),
  .qValid   (ff_dctocore_std_ack_valid_out),
  .qRetry   (ff_dctocore_std_ack_retry_in) 
);


// L1 TLB TO L1 (LOAD)-----------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l1tlbtol1_fwd_type l1tlbtol1_fwd0_current; // data coming in
logic ff_l1tlbtol1_fwd0_valid_in;
logic ff_l1tlbtol1_fwd0_valid_out;
logic ff_l1tlbtol1_fwd0_retry_in;
logic ff_l1tlbtol1_fwd0_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign ff_l1tlbtol1_fwd0_valid_in = l1tlbtol1_fwd0_valid;
assign l1tlbtol1_fwd0_retry = ff_l1tlbtol1_fwd0_retry_out;

//instantiate fluid flop
fflop #(.Size($bits(I_l1tlbtol1_fwd_type))) ff_l1tlbtol1_fwd0 (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tlbtol1_fwd0),
  .dinValid (ff_l1tlbtol1_fwd0_valid_in),
  .dinRetry (ff_l1tlbtol1_fwd0_retry_out),

  .q        (l1tlbtol1_fwd0_current),
  .qValid   (ff_l1tlbtol1_fwd0_valid_out),
  .qRetry   (ff_l1tlbtol1_fwd0_retry_in) 
);


// L1 TLB TO L1 (STORE)----------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l1tlbtol1_fwd_type l1tlbtol1_fwd1_current; // data coming in
logic ff_l1tlbtol1_fwd1_valid_in;
logic ff_l1tlbtol1_fwd1_valid_out;
logic ff_l1tlbtol1_fwd1_retry_in;
logic ff_l1tlbtol1_fwd1_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign ff_l1tlbtol1_fwd1_valid_in = l1tlbtol1_fwd1_valid;
assign l1tlbtol1_fwd1_retry = ff_l1tlbtol1_fwd1_retry_out;

//instantiate fluid flop
fflop #(.Size($bits(I_l1tlbtol1_fwd_type))) ff_l1tlbtol1_fwd1 (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tlbtol1_fwd1),
  .dinValid (ff_l1tlbtol1_fwd1_valid_in),
  .dinRetry (ff_l1tlbtol1_fwd1_retry_out),

  .q        (l1tlbtol1_fwd1_current),
  .qValid   (ff_l1tlbtol1_fwd1_valid_out),
  .qRetry   (ff_l1tlbtol1_fwd1_retry_in) 
);


// L1 TLB TO L1 (NOTIFY)---------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l1tlbtol1_cmd_type l1tlbtol1_cmd_current; // data coming in
logic ff_l1tlbtol1_cmd_valid_in;
logic ff_l1tlbtol1_cmd_valid_out;
logic ff_l1tlbtol1_cmd_retry_in;
logic ff_l1tlbtol1_cmd_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign ff_l1tlbtol1_cmd_valid_in = l1tlbtol1_cmd_valid;
assign l1tlbtol1_cmd_retry = ff_l1tlbtol1_cmd_retry_out;

//instantiate fluid flop
fflop #(.Size($bits(I_l1tlbtol1_cmd_type))) ff_l1tlbtol1_cmd (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tlbtol1_cmd),
  .dinValid (ff_l1tlbtol1_cmd_valid_in),
  .dinRetry (ff_l1tlbtol1_cmd_retry_out),

  .q        (l1tlbtol1_cmd_current),
  .qValid   (ff_l1tlbtol1_cmd_valid_out),
  .qRetry   (ff_l1tlbtol1_cmd_retry_in) 
);


// L1 TO L2 TLB REQUEST----------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l1tol2tlb_req_type l1tol2tlb_req_current; // data going out
logic ff_l1tol2tlb_req_valid_in;
logic ff_l1tol2tlb_req_valid_out;
logic ff_l1tol2tlb_req_retry_in;
logic ff_l1tol2tlb_req_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign l1tol2tlb_req_valid = ff_l1tol2tlb_req_valid_out;
assign ff_l1tol2tlb_req_retry_in = l1tol2tlb_req_retry;
 
// instantiate fluid flop
fflop #(.Size($bits(I_l1tol2tlb_req_type))) ff_l1tol2tlb_req (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tol2tlb_req_current),
  .dinValid (ff_l1tol2tlb_req_valid_in),
  .dinRetry (ff_l1tol2tlb_req_retry_out),

  .q        (l1tol2tlb_req),
  .qValid   (ff_l1tol2tlb_req_valid_out),
  .qRetry   (ff_l1tol2tlb_req_retry_in) 
);


// L1 TO L2 REQUEST--------------------------------------------------
I_l1tol2_req_type l1tol2_req_current; // data going out
logic ff_l1tol2_req_valid_in;
logic ff_l1tol2_req_valid_out;
logic ff_l1tol2_req_retry_in;
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
logic ff_l1tol2_req_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign l1tol2_req_valid = ff_l1tol2_req_valid_out;
assign ff_l1tol2_req_retry_in = l1tol2_req_retry;
 
// instantiate fluid flop
fflop #(.Size($bits(I_l1tol2_req_type))) ff_l1tol2_req (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tol2_req_current),
  .dinValid (ff_l1tol2_req_valid_in),
  .dinRetry (ff_l1tol2_req_retry_out),

  .q        (l1tol2_req),
  .qValid   (ff_l1tol2_req_valid_out),
  .qRetry   (ff_l1tol2_req_retry_in) 
);


// L2 to L1 (SNOOP OR ACK)-------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l2tol1_snack_type l2tol1_snack_current; // data coming in
logic ff_l2tol1_snack_valid_in;
logic ff_l2tol1_snack_valid_out;
logic ff_l2tol1_snack_retry_in;
logic ff_l2tol1_snack_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign ff_l2tol1_snack_valid_in = l2tol1_snack_valid;
assign l2tol1_snack_retry = ff_l2tol1_snack_retry_out;

//instantiate fluid flop
fflop #(.Size($bits(I_l2tol1_snack_type))) ff_l2tol1_snack (
  .clk      (clk),
  .reset    (reset),

  .din      (l2tol1_snack),
  .dinValid (ff_l2tol1_snack_valid_in),
  .dinRetry (ff_l2tol1_snack_retry_out),

  .q        (l2tol1_snack_current),
  .qValid   (ff_l2tol1_snack_valid_out),
  .qRetry   (ff_l2tol1_snack_retry_in) 
);


// L1 TO L2 SNOOP ACK------------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l2snoop_ack_type l1tol2_snoop_ack_current; // data going out
logic ff_l1tol2_snoop_ack_valid_in;
logic ff_l1tol2_snoop_ack_valid_out;
logic ff_l1tol2_snoop_ack_retry_in;
logic ff_l1tol2_snoop_ack_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign l1tol2_snoop_ack_valid = ff_l1tol2_snoop_ack_valid_out;
assign ff_l1tol2_snoop_ack_retry_in = l1tol2_snoop_ack_retry;
 
// instantiate fluid flop
fflop #(.Size($bits(I_l2snoop_ack_type))) ff_l1tol2_snoop_ack (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tol2_snoop_ack_current),
  .dinValid (ff_l1tol2_snoop_ack_valid_in),
  .dinRetry (ff_l1tol2_snoop_ack_retry_out),

  .q        (l1tol2_snoop_ack),
  .qValid   (ff_l1tol2_snoop_ack_valid_out),
  .qRetry   (ff_l1tol2_snoop_ack_retry_in) 
);


// L1 TO L2 DISPLACEMENT---------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l1tol2_disp_type l1tol2_disp_current; // data going out
logic ff_l1tol2_disp_valid_in;
logic ff_l1tol2_disp_valid_out;
logic ff_l1tol2_disp_retry_in;
logic ff_l1tol2_disp_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign l1tol2_disp_valid = ff_l1tol2_disp_valid_out;
assign ff_l1tol2_disp_retry_in = l1tol2_disp_retry;
 
// instantiate fluid flop
fflop #(.Size($bits(I_l1tol2_disp_type))) ff_l1tol2_disp (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tol2_disp_current),
  .dinValid (ff_l1tol2_disp_valid_in),
  .dinRetry (ff_l1tol2_disp_retry_out),

  .q        (l1tol2_disp),
  .qValid   (ff_l1tol2_disp_valid_out),
  .qRetry   (ff_l1tol2_disp_retry_in) 
);


// L2 to L1 (SNOOP OR ACK)-------------------------------------------
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
I_l2tol1_dack_type l2tol1_dack_current; // data coming in
logic ff_l2tol1_dack_valid_in;
logic ff_l2tol1_dack_valid_out;
logic ff_l2tol1_dack_retry_in;
logic ff_l2tol1_dack_retry_out;
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */

// hook up the wires
assign ff_l2tol1_dack_valid_in = l2tol1_dack_valid;
assign l2tol1_dack_retry = ff_l2tol1_dack_retry_out;

//instantiate fluid flop
fflop #(.Size($bits(I_l2tol1_dack_type))) ff_l2tol1_dack (
  .clk      (clk),
  .reset    (reset),

  .din      (l2tol1_dack),
  .dinValid (ff_l2tol1_dack_valid_in),
  .dinRetry (ff_l2tol1_dack_retry_out),

  .q        (l2tol1_dack_current),
  .qValid   (ff_l2tol1_dack_valid_out),
  .qRetry   (ff_l2tol1_dack_retry_in) 
);
`endif //FFLOP_HANDLE

`ifdef DC_PASSTHROUGH
// PASSTHROUGH #1
//                  ----------
//                  |        |
//  l2tol1_snack--->|        |---->dctocore_ld
//                  |   L1   |
// l1tol2snoop_ack<-|        |
//                  |        |
//                  ----------
// pass whatever comes from L2

// break down the signals from L2-snack and construct DC-to-core signal
always_comb begin
  dctocore_ld_current.coreid = 0;
  dctocore_ld_current.fault = 0;
  dctocore_ld_current.data = l2tol1_snack.line;

  l1tol2_snoop_ack_current.l2id = l2tol1_snack_current.l2id;
  l1tol2_snoop_ack_current.directory_id = 1;
end

// calculate valid and retry signals associated with the previous stage
always_comb begin
  ff_dctocore_ld_valid_in = ff_l2tol1_snack_valid_out;
  ff_l2tol1_snack_retry_in = ff_dctocore_ld_retry_out;
  //dctocore_ld_retry_out comes of the fflop module
end



// PASSTHROUGH #2
//                    ----------
//                    |        |
//   coretodc_ld----->|        |---->l1tol2_req
//   l1tlbtol1_fwd0-->|   L1   |---->l1tol2tlb_req
//                    |        |
//                    |        |
//                    ----------
// OUTPUT: core load--->L2
// pass core load request to L2

// break down the core request and TLB to construct L2 request
I_l1tol2_req_type l1tol2_req_ld_current;
always_comb begin
  l1tol2_req_ld_current.l1id = 5'b00000;
  l1tol2_req_ld_current.cmd = `SC_CMD_REQ_S;
  l1tol2_req_ld_current.pcsign = coretodc_ld.pcsign;
  l1tol2_req_ld_current.poffset = coretodc_ld.poffset;
  l1tol2_req_ld_current.ppaddr = l1tlbtol1_fwd0.ppaddr;
end

// construct L1 to L2 TLB store request
/* verilator lint_off UNDRIVEN */
I_l1tol2tlb_req_type l1tol2tlb_req_ld_current;
/* verilator lint_on UNDRIVEN */
always_comb begin
  l1tol2tlb_req_ld_current.l1id = 5'b00000;
  l1tol2tlb_req_ld_current.prefetch = 0;
  l1tol2tlb_req_ld_current.hpaddr = l1tlbtol1_fwd0_current.hpaddr;
end

// PASSTHROUGH #3
//                    ----------
//                    |        |
//  coretodc_std----->|        |---->l1tol2_req
//   l1tlbtol1_fwd1-->|   L1   |---->l1tol2tlb_req
// dctocore_std_ack<--|        |
//                    |        |
//                    ----------
// OUTPUT: core load--->L2
// pass miss request to L2 and send ack to core

// construct L1 to L2 store request
I_l1tol2_req_type l1tol2_req_std_current;
always_comb begin
  l1tol2_req_std_current.l1id     = 5'b00000;
  l1tol2_req_std_current.cmd      = `SC_CMD_REQ_S;
  l1tol2_req_std_current.pcsign   = coretodc_std.pcsign;
  l1tol2_req_std_current.poffset  = coretodc_std.poffset;
  l1tol2_req_std_current.ppaddr   = l1tlbtol1_fwd1.ppaddr;
end

// construct L1 to L2 TLB store request
I_l1tol2tlb_req_type l1tol2tlb_req_std_current;
always_comb begin
  l1tol2tlb_req_std_current.l1id = 5'b00000;
  l1tol2tlb_req_std_current.prefetch = 0;
  l1tol2tlb_req_std_current.hpaddr = l1tlbtol1_fwd1_current.hpaddr;
end

// construct L1 to CORE store ack
always_comb begin
  dctocore_std_ack_current.fault  = 0;
  dctocore_std_ack_current.coreid = 0;
end

// calculate valid and retry signals associated with the previous stage
always_comb begin
  ff_dctocore_std_ack_valid_in = 1;
end

// select between coretodc_ld and coretodc_std
// change every 4 cycles, later signals will be passed
// accorging to priority list. i.e. loads are #1 priority
// 
// also valid and retry signals calculated accordingly
//
//               |\
//               | \
//  coretodc_ld->|  |--->l1tol2tlb_req
//               |  |--->l1tol2_req
// coretodc_std->|  |
//               | /
//               |/
//
logic [2:0] counter;
always @(posedge clk) begin
  counter <= counter+1;
end

always_comb begin
  if (1 == 0) begin//(counter[2] == 1 && ff_coretodc_std_valid_out == 1) begin
    l1tol2_req_current = l1tol2_req_std_current;
    l1tol2tlb_req_current = l1tol2tlb_req_std_current;
    ff_l1tol2_req_valid_in = ff_coretodc_std_valid_out&ff_l1tlbtol1_fwd1_valid_out;
    ff_l1tol2tlb_req_valid_in = ff_l1tlbtol1_fwd1_valid_out;
    ff_coretodc_std_retry_in = ff_l1tol2_req_retry_out&ff_l1tol2tlb_req_retry_out;
    ff_coretodc_ld_retry_in = 1;
    ff_l1tlbtol1_fwd0_retry_in = 1;
    ff_l1tlbtol1_fwd1_retry_in = ff_l1tol2_req_retry_out&ff_l1tol2tlb_req_retry_out;
  end else begin
    l1tol2_req_current = l1tol2_req_ld_current;
    l1tol2tlb_req_current = l1tol2tlb_req_ld_current;
    ff_l1tol2_req_valid_in = ff_coretodc_ld_valid_out&ff_l1tlbtol1_fwd0_valid_out;
    ff_l1tol2tlb_req_valid_in = ff_l1tlbtol1_fwd0_valid_out;
    ff_coretodc_std_retry_in = 0;
    ff_coretodc_ld_retry_in = ff_l1tol2_req_retry_out&ff_l1tol2tlb_req_retry_out;
    ff_l1tlbtol1_fwd0_retry_in = ff_l1tol2_req_retry_out&ff_l1tol2tlb_req_retry_out;
    ff_l1tlbtol1_fwd1_retry_in = 0;
  end
end
`endif

`ifdef COMPLETE
///////////////////////////////////////////////////////////
// Values for control logic are assigned by the FSM
// FSM is implemented at the end of dcache_pipe.v file
///////////////////////////////////////////////////////////

//STAGE #1 (FIRST CLOCK CYCLE)
// This logic is governed by the state machine
logic stage1_input_valid;
logic stage1_common_retry;
// Check for coreid match from l1 tlb and core
always_comb begin
  if (current_state == LOAD_PROC) begin
    if (stage1_input_valid) begin
      if (coretodc_ld_current.coreid == l1tlbtol1_fwd0_current.coreid) begin
        ld_coreid_fault = 0;
      end else begin
        ld_coreid_fault = 1;
      end
    end
  end
end

// Access the tagbank
logic [12:0]      index = coretodc_ld.poffset+coretodc_ld.imm;

tagbank_data_type   tagbank_write_data;
logic               tagbank_write_data_valid;
logic               tagbank_write_data_retry;

tagbank_output_type tagbank_output;
logic               tagbank_output_valid_stage1;
logic               tagbank_output_retry_stage1;

logic               tagbank_en;
logic               tagbank_write;
logic               hit_retry_stage1;
logic               hit_valid;

dcache_tagbank tagbank1 (
  .clk                   (clk),
  .reset                 (reset),

  .enable                (tagbank_en) 
  .write                 (tagbank_write),
  .data_valid            (tagbank_write_data_valid),
  .data_retry            (tagbank_write_data_retry),
  .data                  (tagbank_write_data),

  .index                 (index[10:6]),

  .tagbank_output_valid  (tagbank_output_valid_stage1),
  .tagbank_output_retry  (tagbank_output_retry_stage1),
  .tagbank_output        (tagbank_output)
);

// Fluid-flop the output of the tag bank for the next stage
logic     tagbank_output_stage2;
logic     tagbank_output_retry_stage2;
logic     tagbank_output_valid_stage2;
fflop #(.Size($bits(tagbank_output_type))) ff_tagbank_output (
  .clk      (clk),
  .reset    (reset),

  .din      (tagbank_output),
  .dinValid (stage1_input_valid&tagbank_output_valid_stage1),
  .dinRetry (tagbank_output_retry_stage1),

  .q        (tagbank_output_stage2),
  .qValid   (tagbank_output_valid_stage2),
  .qRetry   (tagbank_output_retry_stage2)
);

// data bank activation logic (Way predictor)
// calculated data will be used during the next cycle
logic [7:0] databank_en;
logic       databank_en_retry;
logic       databank_en_valid;
always_comb begin
  if (coretodc_ld.lop == CORE_LOP_L64U && !databank_en_retry) begin
    case (index[7:5]) begin
      3'b000: databank_en = 8'b00000001;
      3'b001: databank_en = 8'b00000010;
      3'b010: databank_en = 8'b00000100;
      3'b011: databank_en = 8'b00001000;
      3'b100: databank_en = 8'b00010000;
      3'b101: databank_en = 8'b00100000;
      3'b110: databank_en = 8'b01000000;
      3'b111: databank_en = 8'b10000000;
    end
  end
end


// Fluid-flop the output of databank activator for the next stage
logic [7:0] databank_en_stage2;
logic       databank_en_valid_stage2;
logic       databank_en_retry_stage2;
fflop #(.Size(8)) ff_databank_en (
  .clk      (clk),
  .reset    (reset),

  .din      (databank_en),
  .dinValid (stage1_input_valid),
  .dinRetry (databank_en_retry),

  .q        (databank_en_stage2),
  .qValid   (databank_en_valid_stage2),
  .qRetry   (databank_en_retry_stage2)
);

// Fluid-flop the coretodc_ld for the next cycle
coretodc_ld_type      coretodc_ld_stage2;
logic                 coretodc_ld_valid_stage2;
logic                 coretodc_ld_retry_stage2;
logic                 coretodc_ld_retry_stage1;
fflop #($bits(coretodc_ld_type)) ff_coretodc_ld_stage2 (
  .clk      (clk),
  .reset    (reset),

  .din      (coretodc_ld_current),
  .dinValid (stage1_input_valid),
  .dinRetry (coretodc_ld_retry_stage1) ,

  .q        (coretodc_ld_stage2),
  .qValid   (coretodc_ld_valid_stage2),
  .qRetry   (coretodc_ld_retry_stage2)
);

// Fluid-flop the l1tlbtol1_fwd0 for the next cycle
l1tlbtol1_fwd_type      l1tlbtol1_fwd0_stage2;
logic                   l1tlbtol1_fwd0_valid_stage2;
logic                   l1tlbtol1_fwd0_retry_stage2;
logic                   l1tlbtol1_fwd0_retry_stage1;
fflop #($bits(l1tlbtol1_fwd_type)) ff_l1tlbtol1_fwd0_stage2 (
  .clk      (clk),
  .reset    (reset),

  .din      (l1tlbtol1_fwd0_current),
  .dinValid (stage1_input_valid),
  .dinRetry (l1tlbtol1_fwd0_retry_stage1) ,

  .q        (l1tlbtol1_fwd0_stage2),
  .qValid   (l1tlbtol1_fwd0_valid_stage2),
  .qRetry   (l1tlbtol1_fwd0_retry_stage2)
);
// STAGE 2 (SECOND CLOCK CYCLE) ACCESS DATABANK
// miss scenario:
//  1) generate l1tol2_req and l1tol2tlb_req
//  2) place the request into the queues
//  3) save the l1id of the request for future processing

//L1 request memory to save coreid and imm
typedef struct packet {
  CORE_reqid_type       coreid;
  SC_imm_type           imm;
} l1_req_buffer_data_type;

// 1) generate requests
l1tol2_req_type           l1tol2_req_next;
l1tlbtol2_req_type        l1tlbtol2_req_next;
logic                     stage2_input_valid;
logic                     stage2_common_retry;
logic [L1_REQIDBITS-1:0]  available_l1id;
l1_req_buffer_data_type   l1_req_buffer_data_write;
l1_req_buffer_data_type   l1_req_buffer_data_read;
logic                     l1_req_buffer_data_read_valid;
logic                     l1_req_buffer_data_read_retry;
//L1REQIDS
always_comb begin
  if (stage2_input_valid) begin
    if (!tagbank_hit_stage2) begin
      case (coretodc_ld_stage2.lop)
      `CORE_LOP_L32U: begin
        l1tol2_req_next.cmd = `SC_CMD_REQ_S;
      end
      endcase
      l1tol2_req_next.l1id = available_l1id;
      l1tol2_req_next.pcsign = coretodc_ld_stage2.pcsign;
      l1tol2_req_next.poffset = coretodc_ld_stage2.poffset;
      l1tol2_req_next.ppaddr = l1tlbtol1_fwd0_stage2.ppaddr;
      l1_req_buffer_data_write.coreid = coretodc_ld_stage2.coreid;
      l1_req_buffer_data_write.imm = coretodc_ld_stage2.imm;
    end
  end
end


// control signal for l1_req_buffer
// signals are assigned by FSM
logic l1_req_buffer_write;
logic l1_req_buffer_retry;
// instantiate l1_req_buffer
ram_1port_fast #(.Width($bits(l1_req_buffer_data_type)), .Size(L1_REQIDS))
l1_req_buffer (
  .clk        (clk),
  .reset      (reset),

  .req_valid  (stage2_input_valid),
  .req_retry  (l1_req_buffer_retry),
  .req_we     (l1_req_buffer_write),
  .pos        (l1_req_buffer_pos),
  .req_data   (l1_req_buffer_data_write),

  .ack_valid  (l1_req_buffer_data_read_valid),
  .ack_retry  (l1_req_buffer_data_read_retry),
  .ack_data   (l1_req_buffer_data_read)
);

// define a bitmap to keep track of available spots in the buffer
logic [`L1_REQIDS-1:0]       bitmap;
logic [`L1_REQIDBITS-1:0]    c[`L1_REQIDS-2:0];

always_comb begin
  
end

always_comb begin
  if (!bitmap[0]) begin
    available_l1id = 0;
  end else begin
    available_l1id = c[0];
  end
end

genvar i;
generate
  for (i=1;i<`L1_REQIDS; i=i+1) begin
    mux #(.Value(i), .Width(`L1_REQIDBITS)) muxes (
      .a      (c[i]),
      .sel    (bitmap[i]),
      .b      (c[i-1])
    );
  end
endgenerate
///////////////////////////////////////////////////////////
// DCTOCORE INTERFACE
///////////////////////////////////////////////////////////
logic                     dctocore_ld_buffer_write_en;
dctocore_ld_type          dctocore_ld_buffer_data_in;
logic                     dctocore_ld_buffer_data_in_valid;
logic                     dctocore_ld_buffer_data_in_retry;

logic                     dctocore_ld_buffer_read_en;
dctocore_ld_type          dctocore_ld_buffer_data_out;
logic                     dctocore_ld_buffer_data_out_valid;
logic                     dctocore_ld_buffer_data_out_retry;

fifo_buffer 
  #(.DATA_WIDTH($bits(dctocore_ld_type)), .ENTRIES(4))
dctocore_ld_buffer (
  .clk              (clk),
  .reset            (reset),

  .write_en         (dctocore_ld_buffer_write_en),
  .data_in          (dctocore_ld_buffer_data_in),
  .data_in_valid    (dctocore_ld_buffer_data_in_valid),
  .data_in_retry    (dctocore_ld_buffer_data_in_retry),

  .read_en          (dctocore_ld_buffer_read_en),
  .data_out         (dctocore_ld_buffer_data_out),
  .data_out_valid   (dctocore_ld_buffer_data_out_valid),
  .data_out_retry   (dctocore_ld_buffer_data_out_retry) 
);



///////////////////////////////////////////////////////////
// GRANT STATE MACHIE
// Description:
//  This state machine determines the control logic
//  for L1 cache
///////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////
// Synchronization block
//
// DESCRIPTION
// This is the syncronization process. In this process 
// the next state is assigned to the current state.
///////////////////////////////////////////////////////////
always @(posedge clk) begin
  if (reset) begin
    stage1_current_state <= `IDLE;
    stage2_current_state <= `IDLE;
    stage3_current_state <= `IDLE;
  end else begin
    stage1_current_state <= stage1_next_state;
    stage2_current_state <= stage2_next_state;
    stage3_current_state <= stage3_next_state;
  end
end

///////////////////////////////////////////////////////////
// Next state decoder block
//
// DESCRIPTION
// Depending on the input signals, and actrions to be 
// performed this process decodes the next state.
///////////////////////////////////////////////////////////
// first stage FSM decoder
always_comb begin
  case (stage1_current_state) 
    `IDLE: begin
      stage1_next_state = LOAD_PROC;
    end
    `LOAD_PROC: begin
      // TODO
    end
  endcase
end

// second stage FSM next state decoder
always_comb begin
  case (stage1_current_state)
    `IDLE: begin
      if (hit_valid) begin
        if (ld_coreid_fault) begin
          stage2_next_state = `LOAD_COREID_FAULT;
        end else if (tagbank_hit) begin
          stage2_next_state = `LOAD_HIT;
        end else begin
          stage2_next_state = `LOAD_MISS;
        end
      end else begin
        stage2_next_state = `IDLE; 
      end
    end
    `LOAD_PROC: begin
      if (hit_valid) begin
        if (ld_coreid_fault) begin
          stage2_next_state = `LOAD_COREID_FAULT;
        end else if (tagbank_hit) begin
          stage2_next_state = `LOAD_HIT;
        end else begin
          stage2_next_state = `LOAD_MISS;
        end
      end else begin
        stage2_next_state = `IDLE; 
      end
    end
    `SNOOP_PROC: begin
      //TODO
    end
    `STORE_PROC: begin
      //TODO
    end
  endcase
end
///////////////////////////////////////////////////////////
// Assigner block
//
// DESCRIPTION
// Depending on the current state, this block will 
// assign required value for all of the
// required control signals at this state
///////////////////////////////////////////////////////////

// first stage assigner blocks
// this block assign retry signals for previous stages
always_comb begin
  case (current_state) 
    `IDLE: begin
      //TODO
    end
    `LOAD_PROC: begin
      ff_coretodc_ld_retry_in = (!stage1_input_valid) || (stage1_common_retry);
      ff_l1tlbtol1_fwd0_retry_in = (!stage1_input_valid) || (stage1_common_retry);
    end
    `SNOOP_PROC: begin
      //TODO
    end
    `STORE_PROC: begin
      //TODO
    end
  endcase
end

always_comb begin
  case (current_state) 
    `IDLE: begin
      //TODO
    end
    `LOAD_PROC: begin
      // First stage Valid and Retry signal handling:
      // The inputs should go when all sources are ready.
      stage1_input_valid = ff_coretodc_ld_valid_out&&ff_l1tlbtol1_fwd0_valid_out;
      stage1_common_retry = (tagbank_output_retry_stage1) || (databank_en_retry) || (coretodc_ld_retry_stage1) || (l1tlbtol1_fwd0_retry_stage1) || tagbank_write_data_retry;

      //
      ff_coretodc_ld_retry_in = 0;
      ff_l1tlbtol1_fwd0_retry_in = 0;
      tagbank_valid_in = ff_coretodc_ld_valid_out&ff_l1tlbtol1_fwd0_valid_out;
      tagbank_en = 1;
      tagbank_write = 0;
      // state of the FSM in second stage is the output of the first FSM
      if (hit_valid) begin
        if (ld_coreid_fault) begin
          stage2_next_state = LOAD_COREID_FAULT;
        end else if (tagbank_hit) begin
          stage2_next_state = LOAD_HIT;
        end else begin
          stage2_next_state = LOAD_MISS;
        end
      end else begin
        stage2_next_state = IDLE;
      end
    end
    `SNOOP_PROC: begin
      //TODO
    end
    `STORE_PROC: begin
      //TODO
    end
  endcase
end

// second stage assigner block
// this block assign retry signals for previous stages
always_comb begin
  case (stage2_current_state)
    `IDLE: begin
      //TODO
    end
    `LOAD_MISS: begin
      tagbank_output_retry_stage2 = (!stage2_input_valid) || (stage2_common_retry);
      databank_en_retry_stage2    = (!stage2_input_valid) || (stage2_common_retry);
      coretodc_ld_retry_stage2    = (!stage2_input_valid) || (stage2_common_retry);
      l1tlbtol1_fwd0_retry_stage2 = (!stage2_input_valid) || (stage2_common_retry);
    end
    `LOAD_HIT: begin

    end
    `LOAD_COREID_FAULT: begin

    end
  endcase
end

always_comb begin
  case (stage2_current_state)
    `IDLE: begin
      //TODO
    end
    `LOAD_MISS: begin
      stage2_input_valid = (hit_valid_stage2)&&(databank_en_valid_stage2);
      stage2_common_retry = (missq_retry) || (l1_req_buffer_retry);
      if (available_l1id == (`L1_REQIDS-1) && bitmap[`L1_REQIDS]) begin
        l1_req_buffer_retry = 1; // buffer is full, send retry
      end else begin
        l1_req_buffer_retry = 0; // buffer is full, send retry
        
      end
    end
    `LOAD_HIT: begin

    end
    `LOAD_COREID_FAULT: begin

    end
  endcase
end
`endif
endmodule


