// This module is instantiated inside the l2cache
//
// The l1TLB has to track at least 4 SPBTRs at once, but no need to have
// unlimited. This means that just 4 flops translating SBPTR to valid indexes
// are enough. If a new SBPTR checkpoint create arrives, the TLB can
// invalidate all the associated TLB entries (and notify the L1 accordingly)
//

module l2tlb(
  /* verilator lint_off UNUSED */
	/* verilator lint_off UNDRIVEN */
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
  /* verilator lint_on UNDRIVEN */
  /* verilator lint_on UNUSED */
);

//`ifdef THIS_DOES_NOT_LINT

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
  
  always_comb begin
	if(l1tol2tlb_req_valid) begin
		l2tlbtol2_fwd_next.l1id = l1tol2tlb_req.l1id;
		l2tlbtol2_fwd_next.prefetch = l1tol2tlb_req.prefetch;
		l2tlbtol2_fwd_next.fault = 3'b000;
		l2tlbtol2_fwd_next.hpaddr = l1tol2tlb_req.hpaddr;
		l2tlbtol2_fwd_next.paddr = {27'b0, l1tol2tlb_req.hpaddr, 12'b0};

		l2tlbtol2_fwd_valid_next = l1tol2tlb_req_valid;
		l1tol2tlb_req_retry = l2tlbtol2_fwd_retry_next;
	end
  end

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

  always_comb begin
	if(l1tlbtol2tlb_req_valid) begin
		l2tlbtol1tlb_ack_next.rid = l1tlbtol2tlb_req.rid;
		l2tlbtol1tlb_ack_next.hpaddr = l1tlbtol2tlb_req.laddr[22:12];
		l2tlbtol1tlb_ack_next.ppaddr = l1tlbtol2tlb_req.laddr[14:12];
		l2tlbtol1tlb_ack_next.dctlbe = 13'b0_0000_0000_0000;

		l2tlbtol1tlb_ack_valid_next = l1tlbtol2tlb_req_valid;
		l1tlbtol2tlb_req_retry = l2tlbtol1tlb_ack_retry_next;
	end
  end

  // l2 -> dr snoop_ack
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

  always_comb begin
	if(drtol2_snack_valid) begin
		l2todr_snoop_ack_next.l2id = drtol2_snack.l2id;
		l2todr_snoop_ack_next.directory_id = drtol2_snack.directory_id;

		l2todr_snoop_ack_valid_next = drtol2_snack_valid;
		drtol2_snack_retry = l2todr_snoop_ack_retry_next;
	end
  end


//`endif

endmodule
