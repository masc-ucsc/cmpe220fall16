// This module is instantiated inside the l2cache
//
// The l1TLB has to track at least 4 SPBTRs at once, but no need to have
// unlimited. This means that just 4 flops translating SBPTR to valid indexes
// are enough. If a new SBPTR checkpoint create arrives, the TLB can
// invalidate all the associated TLB entries (and notify the L1 accordingly)
//

module l2tlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // L2TLB listens the same L1 request (but no ack). Response sent to L2
  ,input                           l1tol2tlb_req_valid
  ,output                          l1tol2tlb_req_retry
  ,input  I_l1tol2tlb_req_type     l1tol2tlb_req

  ,output                          l2tlbtol2_fwd_valid
  ,input                           l2tlbtol2_fwd_retry
  ,output I_l2tlbtol2_fwd_type     l2tlbtol2_fwd

  // l1TLB and L2TLB interface
  ,output                          l2tlbtol1tlb_snoop_valid
  ,input                           l2tlbtol1tlb_snoop_retry
  ,output I_l2tlbtol1tlb_snoop_type l2tlbtol1tlb_snoop

  ,output                          l2tlbtol1tlb_ack_valid
  ,input                           l2tlbtol1tlb_ack_retry
  ,output I_l2tlbtol1tlb_ack_type  l2tlbtol1tlb_ack

  ,input                           l1tlbtol2tlb_req_valid
  ,output                          l1tlbtol2tlb_req_retry
  ,input  I_l1tlbtol2tlb_req_type  l1tlbtol2tlb_req

  ,input                           l1tlbtol2tlb_sack_valid
  ,output                          l1tlbtol2tlb_sack_retry
  ,input  I_l1tlbtol2tlb_sack_type l1tlbtol2tlb_sack
  
  //---------------------------
  // Directory interface (l2 has to arbitrate between L2 and L2TLB
  // messages based on nodeid. Even nodeid is L2, odd is L2TLB)
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
  /* verilator lint_on UNUSED */
);


  // l2tlb -> l2 fwd
  I_l2tlbtol2_fwd_type l2tlbtol2_fwd_next;
  logic l2tlbtol2_fwd_valid_next, l2tlbtol2_fwd_retry_next;

  fflop #(.Size($bits(I_l2tlbtol2_fwd_type))) ff_l2tlbtol2_fwd_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l2tlbtol2_fwd_valid_next)
   ,.dinRetry(l2tlbtol2_fwd_retry_next)
   ,.din(l2tlbtol2_fwd_next)
   
   ,.qValid(l2tlbtol2_fwd_valid)
   ,.qRetry(l2tlbtol2_fwd_retry)
   ,.q(l2tlbtol2_fwd)
   );
   
	l2tlbtol2_fwd_next.1lid = l1tol2tlb_req.l1id;
	l2tlbtol2_fwd_next.prefetch = l1tol2tlb_req.prefetch;
	l2tlbtol2_fwd_next.fault = l1tol2tlb_req.1b'0;
	l2tlbtol2_fwd_next.hpaddr = l1tol2tlb_req.hpaddr;
	l2tlbtol2_fwd_next.paddr[11:0] = l1tol2tlb_req.poffset;
	l2tlbtol2_fwd_next.paddr[22:12] = l1tol2tlb_req.hpaddr;

	
  // l2tlb -> l1tlb snoop
  I_l2tlbtol1tlb_snoop_type l2tlbtol1tlb_snoop_next;
  logic l2tlbtol1tlb_snoop_valid_next, l2tlbtol1tlb_snoop_retry_next;

  fflop #(.Size($bits(I_l2tlbtol1tlb_snoop_type))) ff_l2tlbtol1tlb_snoop_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l2tlbtol1tlb_snoop_valid_next)
   ,.dinRetry(l2tlbtol1tlb_snoop_retry_next)
   ,.din(l2tlbtol1tlb_snoop_next)
   
   ,.qValid(l2tlbtol1tlb_snoop_valid)
   ,.qRetry(l2tlbtol1tlb_snoop_retry)
   ,.q(l2tlbtol1tlb_snoop)
   );
   
	l2tlbtol1tlb_snoop_next.rid = l1tlbtol2tlb_sack.rid;
	l2tlbtol1tlb_snoop_next.hpaddr = l1tlbtol2tlb_req.hpaddr;


  // l2tlb -> l1tlb ack
  I_l2tlbtol1tlb_ack_type l2tlbtol1tlb_ack_next;
  logic l2tlbtol1tlb_ack_valid_next, l2tlbtol1tlb_ack_retry_next;

  fflop #(.Size($bits(I_l2tlbtol1tlb_ack_type))) ff_l2tlbtol1tlb_ack_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l2tlbtol1tlb_ack_valid_next)
   ,.dinRetry(l2tlbtol1tlb_ack_retry_next)
   ,.din(l2tlbtol1tlb_ack_next)
   
   ,.qValid(l2tlbtol1tlb_ack_valid)
   ,.qRetry(l2tlbtol1tlb_ack_retry)
   ,.q(l2tlbtol1tlb_ack)
   );

	l2tlbtol1tlb_ack_next.rid = l1tlbtol2tlb_req.rid;
	l2tlbtol1tlb_ack_next.hpaddr = l1tlbtol2tlb_req.hpaddr;
	l2tlbtol1tlb_ack_next.ppaddr = l1tlbtol2tlb_req.hpaddr[2:0];
	l2tlbtol1tlb_ack_next.dctlbe = 


  // l2 -> dr req
  I_l2todr_req_type l2todr_req_next;
  logic l2todr_req_valid_next, l2todr_req_retry_next;

  fflop #(.Size($bits(I_l2todr_req_type))) ff_l2todr_req_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l2todr_req_valid_next)
   ,.dinRetry(l2todr_req_retry_next)
   ,.din(l2todr_req_next)
   
   ,.qValid(l2todr_req_valid)
   ,.qRetry(l2todr_req_retry)
   ,.q(l2todr_req)
   );

	l2todr_req_next.nid = drtol2_snack. nid;
	l2todr_req_next.l2id = drtol2_snack.l2id;
	l2todr_req_next.cmd = 
	l2todr_req_next.paddr = drtol2_snack.paddr;


  // l2 -> dr ack
  I_l2snoop_ack_type l2todr_snoop_ack_next;
  logic l2todr_snoop_ack_valid_next, l2todr_snoop_ack_retry_next;

  fflop #(.Size($bits(I_l2snoop_ack_type))) ff_l2snoop_ack_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l2todr_snoop_ack_valid_next)
   ,.dinRetry(l2todr_snoop_ack_retry_next)
   ,.din(l2todr_snoop_ack_next)
   
   ,.qValid(l2todr_snoop_ack_valid)
   ,.qRetry(l2todr_snoop_ack_retry)
   ,.q(l2todr_snoop_ack)
   );

	l2todr_snoop_ack_next.l2id = drtol2_snack.l2id;


  // l2 -> dr disp
  I_l2todr_disp_type l2todr_disp_next;
  logic l2todr_disp_valid_next, l2todr_disp_retry_next;

  fflop #(.Size($bits(I_l2todr_disp_type))) ff_l2todr_disp_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l2todr_disp_valid_next)
   ,.dinRetry(l2todr_disp_retry_next)
   ,.din(l2todr_disp_next)
   
   ,.qValid(l2todr_disp_valid)
   ,.qRetry(l2todr_disp_retry)
   ,.q(l2todr_disp)
   );

	l2todr_disp_next.nid = drtol2_snack.nid;
	l2todr_disp_next.l2id = drtol2_snack.l2id;
	l2todr_disp_next.drid = drtol2_snack.drid;
	l2todr_disp_next.mask = 
	l2todr_disp_next.dcmd = 
	l2todr_disp_next.line = drtol2_snack.line;
	l2todr_disp_next.paddr = drtol2_snack.paddr;

endmodule