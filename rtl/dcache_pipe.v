
`include "scmem.vh"

//
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


// PASSTHROUGH #1
//                  ----------
//                  |        |
//  l2tol1_snack--->|        |---->dctocore_ld
//                  |   L1   |
//                  |        |
//                  |        |
//                  ----------
// OUTPUT: L2--->core load
// pass whatever comes from L2

// break down the signals from L2-snack and construct DC-to-core signal
always_comb begin
  dctocore_ld_current.coreid = l2tol1_snack.l2id;
  dctocore_ld_current.fault = 0;
  dctocore_ld_current.data = l2tol1_snack.line;
end

// calculate valid and retry signals associated with the previous stage
always_comb begin
  ff_dctocore_ld_valid_in = 1;
  //dctocore_ld_retry_out comes of the fflop module
end



// PASSTHROUGH #2
//                    ----------
//                    |        |
//   coretodc_ld----->|        |---->l1tol2_req
//   l1tlbtol2_fwd0-->|   L1   |
//                    |        |
//                    |        |
//                    ----------
// OUTPUT: core load--->L2
// pass core load request to L2

// break down the core request and TLB to construct L2 request
I_l1tol2_req_type l1tol2_req_ld_current;
always_comb begin
  l1tol2_req_ld_current.l1id = coretodc_ld.coreid[4:0];
  l1tol2_req_ld_current.cmd = `SC_CMD_REQ_S;
  l1tol2_req_ld_current.pcsign = coretodc_ld.pcsign;
  l1tol2_req_ld_current.poffset = coretodc_ld.poffset;
  l1tol2_req_ld_current.ppaddr = l1tlbtol1_fwd0.ppaddr;
end

// calculate valid and retry signals associated with the previous stage
always_comb begin
  ff_l1tol2_req_valid_in = 1;
end


// PASSTHROUGH #3
//                    ----------
//                    |        |
//  coretodc_std----->|        |---->l1tol2_req
//   l1tlbtol2_fwd0-->|   L1   |
// dctocore_std_ack<--|        |
//                    |        |
//                    ----------
// OUTPUT: core load--->L2
// pass miss request to L2 and send ack to core

// break down the core request and TLB to construct L2 request
I_l1tol2_req_type l1tol2_req_std_current;
always_comb begin
  l1tol2_req_std_current.l1id     = coretodc_std.coreid[4:0];
  l1tol2_req_std_current.cmd      = `SC_CMD_REQ_S;
  l1tol2_req_std_current.pcsign   = coretodc_std.pcsign;
  l1tol2_req_std_current.poffset  = coretodc_std.poffset;
  l1tol2_req_std_current.ppaddr   = l1tlbtol1_fwd0.ppaddr;
  
  dctocore_std_ack_current.fault  = 0;
  dctocore_std_ack_current.coreid = 0;
end

// calculate valid and retry signals associated with the previous stage
always_comb begin
  ff_l1tol2_req_valid_in = 1;
end

// select between coretodc_ld and coretodc_std
// change every 4 cycles, later signals will be passed
// accorging to priority list. i.e. loads are #1 priority
//
//               |\
//               | \
//  coretodc_ld->|  |
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
  if (counter[2] == 1)
    l1tol2_req_current = l1tol2_req_std_current;
  else
    l1tol2_req_current = l1tol2_req_ld_current;
end


endmodule

