// This module is instantiated inside the l2cache
//
// The l1TLB has to track at least 4 SPBTRs at once, but no need to have
// unlimited. This means that just 4 flops translating SBPTR to valid indexes
// are enough. If a new SBPTR checkpoint create arrives, the TLB can
// invalidate all the associated TLB entries (and notify the L1 accordingly)
//
`include "scmem.vh"
`define L2TLB_PASSTHROUGH

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

`ifdef L2TLB_PASSTHROUGH
  assign l2tlbtol1tlb_snoop_valid = 1'b0;
  assign l2todr_req_valid = 1'b0;
  assign l2todr_disp_valid = 1'b0;


  // l2tlb -> l2 fwd
  I_l2tlbtol2_fwd_type l2tlbtol2_fwd_next;
  logic l2tlbtol2_fwd_valid_next, l2tlbtol2_fwd_retry_next;
  
  always_comb begin
	if(l1tol2tlb_req_valid) begin
		l2tlbtol2_fwd_next.l1id = l1tol2tlb_req.l1id;
		l2tlbtol2_fwd_next.prefetch = l1tol2tlb_req.prefetch;
		l2tlbtol2_fwd_next.fault = 3'b000;
		l2tlbtol2_fwd_next.hpaddr = l1tol2tlb_req.hpaddr;
		l2tlbtol2_fwd_next.paddr = {27'b0, l1tol2tlb_req.hpaddr, 12'b0};

		l2tlbtol2_fwd_valid_next = l1tol2tlb_req_valid;
		l1tol2tlb_req_retry = l2tlbtol2_fwd_retry_next;
	end else begin
		l2tlbtol2_fwd_valid_next = 1'b0;
	end
  end

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

  // l2tlb -> l1tlb ack
  I_l2tlbtol1tlb_ack_type l2tlbtol1tlb_ack_next;
  logic l2tlbtol1tlb_ack_valid_next, l2tlbtol1tlb_ack_retry_next;

  always_comb begin
	if(l1tlbtol2tlb_req_valid) begin
		l2tlbtol1tlb_ack_next.rid = l1tlbtol2tlb_req.rid;
		l2tlbtol1tlb_ack_next.hpaddr = l1tlbtol2tlb_req.laddr[22:12];
		l2tlbtol1tlb_ack_next.ppaddr = l1tlbtol2tlb_req.laddr[14:12];
		l2tlbtol1tlb_ack_next.dctlbe = 13'b0_0000_0000_0000;

		l2tlbtol1tlb_ack_valid_next = l1tlbtol2tlb_req_valid;
		l1tlbtol2tlb_req_retry = l2tlbtol1tlb_ack_retry_next;
	end else begin
		l2tlbtol1tlb_ack_valid_next = 1'b0;
	end
  end

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

  // l2 -> dr snoop_ack
  I_l2snoop_ack_type l2todr_snoop_ack_next;
  logic l2todr_snoop_ack_valid_next, l2todr_snoop_ack_retry_next;

  always_comb begin
	if(drtol2_snack_valid) begin
		l2todr_snoop_ack_next.l2id = drtol2_snack.l2id;
		l2todr_snoop_ack_next.directory_id = drtol2_snack.directory_id;

		l2todr_snoop_ack_valid_next = drtol2_snack_valid;
		drtol2_snack_retry = l2todr_snoop_ack_retry_next;
	end else begin
		l2todr_snoop_ack_valid_next = 1'b0;
	end
  end

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


`endif

`ifdef L2TLB_ENTRIES
  
  logic			TLBT_valid;
  logic			TLBT_retry;
  logic			TLB_write[3:0];

  logic			TLBT_valid_next[3:0]
  logic  	        TLBT_valid_retry
  logic 		TLBE_valid_next[3:0];
  SC_dctlbe_type 	TLBE_dctlbe_next[3:0];
  logic[18:0] 		TLBE_tag_next[3:0];

  TLB_hpaddr_type 	TLBE_hpaddr;
  

  // 1024 entries, 4 way
  // 33 bits for each TLB entry:
  // 1  bit  for valid
  // 13 bits for dctlbe
  // 19 bits for tag
  ram_1port_dense #(33, 256) TLBE0(
     .clk(clk)
    ,.reset(reset)

    ,.req_valid(l1tlbtol2tlb_req_valid)
    ,.req_retry(l1tlbtol2tlb_req_retry)
    ,.req_we(TLBE_write[0])
    ,.req_pos(l1tlbtol2tlb_req.laddr[19:12])
    ,.req_data({1, 13'b0_0000_0000_0000, l1tlbtol2tlb_req.laddr[38:20]})

    ,.ack_valid(TLBT_valid_next[0])
    ,.ack_retry(TLBT_valid_retry)
    ,.ack_data({TLBE_valid_next[0], TLBE_dctlbe_next[0], TLBE_tag_next[0]})
  );

  ram_1port_dense #(33, 256) TLBE1(
     .clk(clk)
    ,.reset(reset)

    ,.req_valid(l1tlbtol2tlb_req_valid)
    ,.req_retry(l1tlbtol2tlb_req_retry)
    ,.req_we(TLBE_write[1])
    ,.req_pos(l1tlbtol2tlb_req.laddr[19:12])
    ,.req_data({1, 13'b0_0000_0000_0000, l1tlbtol2tlb_req.laddr[38:20]})

    ,.ack_valid(TLBT_valid_next[1])
    ,.ack_retry(TLBT_valid_retry)
    ,.ack_data({TLBE_valid_next[1], TLBE_dctlbe_next[1], TLBE_tag_next[1]})
  );

  ram_1port_dense #(33, 256) TLBE2(
     .clk(clk)
    ,.reset(reset)

    ,.req_valid(l1tlbtol2tlb_req_valid)
    ,.req_retry(l1tlbtol2tlb_req_retry)
    ,.req_we(TLBE_write[2])
    ,.req_pos(l1tlbtol2tlb_req.laddr[19:12])
    ,.req_data({1, 13'b0_0000_0000_0000, l1tlbtol2tlb_req.laddr[38:20]})

    ,.ack_valid(TLBT_valid_next[2])
    ,.ack_retry(TLBT_valid_retry)
    ,.ack_data({TLBE_valid_next[2], TLBE_dctlbe_next[2], TLBE_tag_next[2]})
  );

  ram_1port_dense #(33, 256) TLBE3(
     .clk(clk)
    ,.reset(reset)

    ,.req_valid(l1tlbtol2tlb_req_valid)
    ,.req_retry(l1tlbtol2tlb_req_retry)
    ,.req_we(TLBE_write[3])
    ,.req_pos(l1tlbtol2tlb_req.laddr[19:12])
    ,.req_data({1, 13'b0_0000_0000_0000, l1tlbtol2tlb_req.laddr[38:20]})

    ,.ack_valid(TLBT_valid_next[3])
    ,.ack_retry(TLBT_valid_retry)
    ,.ack_data({TLBE_valid_next[3], TLBE_dctlbe_next[3], TLBE_tag_next[3]})
  );

  always_comb begin
    if(l1tlbtol2tlb_req_valid = 1'b1) begin
	  l2tlbtol1tlb_ack.rid = l1tlbtol2tlb_req.rid;
      TLBT_valid = 1'b1;
      TLBT_retry = 1'b0;
      TLBE_write = {1'b0, 1'b0, 1'b0, 1'b0};
    
      if((TLBT_valid_next[0]) && (TLBE_valid_next[0] == 1) && (l1tlbtol2tlb_req.laddr[38:20] == TLBE_tag_next[0])) begin
        l2tlbtol1tlb_ack_valid = 1'b1;    
        l2tlbtol1tlb_ack.hpaddr = {3'b000, l1tlbtol2tlb_req.laddr[19:12]};
        l2tlbtol1tlb_ack.dctlbe = TLBE_dctlbe_next[0];
      end else if((TLBT_valid_next[1]) && (TLBE_valid_next[1] == 1) && (l1tlbtol2tlb_req.laddr[38:20] == TLBE_tag_next[1])) begin
        l2tlbtol1tlb_ack_valid = 1'b1;    
        l2tlbtol1tlb_ack.hpaddr = {3'b001, l1tlbtol2tlb_req.laddr[19:12]};
        l2tlbtol1tlb_ack.dctlbe = TLBE_dctlbe_next[1];
      end else if((TLBT_valid_next[2]) && (TLBE_valid_next[2] == 1) && (l1tlbtol2tlb_req.laddr[38:20] == TLBE_tag_next[2])) begin
        l2tlbtol1tlb_ack_valid = 1'b1;    
        l2tlbtol1tlb_ack.hpaddr = {3'b010, l1tlbtol2tlb_req.laddr[19:12]};
        l2tlbtol1tlb_ack.dctlbe = TLBE_dctlbe_next[2];
      end else if((TLBT_valid_next[3]) && (TLBE_valid_next[3] == 1) && (l1tlbtol2tlb_req.laddr[38:20] == TLBE_tag_next[3])) begin
        l2tlbtol1tlb_ack_valid = 1'b1;    
        l2tlbtol1tlb_ack.hpaddr = {3'b011, l1tlbtol2tlb_req.laddr[19:12]};
        l2tlbtol1tlb_ack.dctlbe = TLBE_dctlbe_next[3];
      end else begin
        l2tlbtol1tlb_ack_valid = 1'b0;
      end
    end     
  end

  logic HT_valid;
  logic HT_retry;
  logic HE_write;
  TLB_hpaddr_type HE_hpaddr;
  logic HE_valid;
  SC_paddr_type HE_paddr;

  logic HT_valid_next;
  logic HT_retry_next;
  logic HE_valid_next;
  SC_paddr_type HE_paddr_next;
  

  ram_1port_dense #(51, 2048) H0(
     .clk(clk)
    ,.reset(reset)

    ,.req_valid(HT_valid)
    ,.req_retry(HT_retry)
    ,.req_we(HE_write)
    ,.req_pos(HE_hpaddr)
    ,.req_data({HE_valid, HE_paddr})

    ,.ack_valid(HT_valid_next)
    ,.ack_retry(HT_retry_next)
    ,.ack_data({HE_valid_next, HE_paddr_next})
  );

  always_comb begin
    if(l1tol2tlb_req_valid) begin
      l2tlbtol2_fwd.lid = l1tol2tlb_req.lid;
      HT_valid = 1'b1;
      HT_retry = 1'b0;
      HE_write = 1'b0;
      HE_hpaddr = l1tol2tlb_req.hpaddr;
      if((HT_valid_next == 1'b1) && (HE_valid_next == 1'b1)) begin
        l2tlbtol2_fwd_valid = 1'b1;
        l2tlbtol2_fwd.paddr = l1tol2tlb_req.hpaddr;
        l2tlbtol2_fwd.paddr = HE_paddr_next;
      end else begin
        l2tlbtol2_fwd_valid = 1'b0;
      end
    end
  end

`endif 

endmodule
