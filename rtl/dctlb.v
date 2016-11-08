
// DCTLB runs parallel to the Dcache. It gets the same requests as the dcache,
// and sends the translation a bit after. It also has a command channel to
// notify for when checkpoints are finished from the TLB point of view.
//
// The DCTLB has to track at least 4 SPBTRs at once, but no need to have
// unlimited. This means that just 4 flops translating SBPTR to valid indexes
// are enough. If a new SBPTR checkpoint create arrives, the TLB can
// invalidate all the associated TLB entries (and notify the L1 accordingly)
//
//
// The hpaddr is a way to identify a L2TLB entry. It is also a pseudo-hah of
// the paddr. When a L2TLB entry is displaced, the dctlb gets a snoop.
// This means that when a hpaddr gets removed, it has to disappear from
// the L1 cache

`define L1DT_PASSTHROUGH

module dctlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // ld core interface
  ,input                           coretodctlb_ld_valid
  ,output                          coretodctlb_ld_retry
  ,input  I_coretodctlb_ld_type    coretodctlb_ld

  // st core interface
  ,input                           coretodctlb_st_valid
  ,output                          coretodctlb_st_retry
  ,input  I_coretodctlb_st_type    coretodctlb_st

  // prefetch request (uses the st/ld fwd port opportunistically)
  ,input                           pfetol1tlb_req_valid
  ,output                          pfetol1tlb_req_retry
  ,input  I_pfetol1tlb_req_type    pfetol1tlb_req

  // forward ld core interface
  ,output                          l1tlbtol1_fwd0_valid
  ,input                           l1tlbtol1_fwd0_retry
  ,output I_l1tlbtol1_fwd_type     l1tlbtol1_fwd0

  // forward st core interface
  ,output                          l1tlbtol1_fwd1_valid
  ,input                           l1tlbtol1_fwd1_retry
  ,output I_l1tlbtol1_fwd_type     l1tlbtol1_fwd1

  // Notify the L1 that the index of the TLB is gone
  /* verilator lint_off UNDRIVEN */
  ,output                          l1tlbtol1_cmd_valid
  ,input                           l1tlbtol1_cmd_retry
  ,output I_l1tlbtol1_cmd_type     l1tlbtol1_cmd

  // Interface with the L2 TLB
  ,input                           l2tlbtol1tlb_snoop_valid
  ,output                          l2tlbtol1tlb_snoop_retry
  ,input I_l2tlbtol1tlb_snoop_type l2tlbtol1tlb_snoop

  ,input                           l2tlbtol1tlb_ack_valid
  ,output                          l2tlbtol1tlb_ack_retry
  ,input I_l2tlbtol1tlb_ack_type   l2tlbtol1tlb_ack

  ,output                          l1tlbtol2tlb_req_valid
  ,input                           l1tlbtol2tlb_req_retry
  ,output I_l1tlbtol2tlb_req_type  l1tlbtol2tlb_req

  ,output                          l1tlbtol2tlb_sack_valid
  ,input                           l1tlbtol2tlb_sack_retry
  ,output I_l1tlbtol2tlb_sack_type l1tlbtol2tlb_sack
  /* verilator lint_on UNDRIVEN */
  /* verilator lint_on UNUSED */
);

`ifdef L1DT_PASSTHROUGH

  assign l1tlbtol1_cmd_valid     = 1'b0;
  assign l1tlbtol2tlb_req_valid  = 1'b0;
  assign l1tlbtol2tlb_sack_valid = 1'b0;

  // LOAD REQUESTS to FWD PORT

  I_l1tlbtol1_fwd_type l1tlbtol1_fwd0_next;
  logic l1tlbtol1_fwd0_retry_next, l1tlbtol1_fwd0_valid_next;

  always_comb begin
    if(coretodctlb_ld_valid) begin
      l1tlbtol1_fwd0_next.coreid = coretodctlb_ld.coreid;
      l1tlbtol1_fwd0_next.prefetch = 1'b0;
      l1tlbtol1_fwd0_next.l2_prefetch = 1'b0;

      l1tlbtol1_fwd0_next.fault = 3'b000; 
      l1tlbtol1_fwd0_next.hpaddr = coretodctlb_ld.laddr[22:12];
      l1tlbtol1_fwd0_next.ppaddr = coretodctlb_ld.laddr[14:12];

      l1tlbtol1_fwd0_valid_next = coretodctlb_ld_valid;
      coretodctlb_ld_retry = l1tlbtol1_fwd0_retry_next;
      pfetol1tlb_req_retry = 1'b0;
    end else if(~pfetol1tlb_req.l2) begin
      l1tlbtol1_fwd0_next.coreid = 'b0;
      l1tlbtol1_fwd0_next.prefetch = 1'b1;
      l1tlbtol1_fwd0_next.l2_prefetch = 1'b1;

      l1tlbtol1_fwd0_next.fault = 3'b000;
      l1tlbtol1_fwd0_next.hpaddr = pfetol1tlb_req.laddr[22:12];
      l1tlbtol1_fwd0_next.ppaddr = pfetol1tlb_req.laddr[14:12];

      l1tlbtol1_fwd0_valid_next = pfetol1tlb_req_valid;
      pfetol1tlb_req_retry = l1tlbtol1_fwd0_retry_next & pfetol1tlb_req_valid;
      coretodctlb_ld_retry = 1'b0;
    end
  end


  fflop #(.Size($bits(I_l1tlbtol1_fwd_type))) ld_req_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l1tlbtol1_fwd0_valid_next)
   ,.dinRetry(l1tlbtol1_fwd0_retry_next)
   ,.din(l1tlbtol1_fwd0_next)
   
   ,.qValid(l1tlbtol1_fwd0_valid)
   ,.qRetry(l1tlbtol1_fwd0_retry)
   ,.q(l1tlbtol1_fwd0)
   );

  // STORE REQUESTS to FWD PORT

  I_l1tlbtol1_fwd_type l1tlbtol1_fwd1_next;
  logic l1tlbtol1_fwd1_retry_next, l1tlbtol1_fwd1_valid_next;

  always_comb begin
    if(coretodctlb_st_valid) begin
      l1tlbtol1_fwd1_next.coreid = coretodctlb_st.coreid;
      l1tlbtol1_fwd1_next.prefetch = 1'b0;
      l1tlbtol1_fwd1_next.l2_prefetch = 1'b0;

      l1tlbtol1_fwd1_next.fault = 3'b000;
      l1tlbtol1_fwd1_next.hpaddr = coretodctlb_st.laddr[22:12];
      l1tlbtol1_fwd1_next.ppaddr = coretodctlb_st.laddr[14:12];

      l1tlbtol1_fwd1_valid_next = coretodctlb_st_valid;
      coretodctlb_st_retry = l1tlbtol1_fwd1_retry_next;
      pfetol1tlb_req_retry = 1'b0;
    end else if(coretodctlb_ld_valid & ~pfetol1tlb_req.l2) begin
      l1tlbtol1_fwd1_next.coreid = 'b0;
      l1tlbtol1_fwd1_next.prefetch = 1'b1;
      l1tlbtol1_fwd1_next.l2_prefetch = 1'b1;

      l1tlbtol1_fwd1_next.fault = 3'b000; 
      l1tlbtol1_fwd1_next.hpaddr = pfetol1tlb_req.laddr[22:12];
      l1tlbtol1_fwd1_next.ppaddr = pfetol1tlb_req.laddr[14:12];

      l1tlbtol1_fwd1_valid_next = pfetol1tlb_req_valid;
      pfetol1tlb_req_retry = l1tlbtol1_fwd1_retry_next & pfetol1tlb_req_valid;
      coretodctlb_st_retry = 1'b0;
    end
  end


  fflop #(.Size($bits(I_l1tlbtol1_fwd_type))) st_req_pt(
    .clk(clk)
   ,.reset(reset)

   ,.dinValid(l1tlbtol1_fwd1_valid_next)
   ,.dinRetry(l1tlbtol1_fwd1_retry_next)
   ,.din(l1tlbtol1_fwd1_next)
   
   ,.qValid(l1tlbtol1_fwd1_valid)
   ,.qRetry(l1tlbtol1_fwd1_retry)
   ,.q(l1tlbtol1_fwd1)
   );

`endif

endmodule

