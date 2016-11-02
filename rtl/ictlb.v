
`include "scmem.vh"

module ictlb(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // core interface
  ,input                           coretoictlb_pc_valid
  ,output                          coretoictlb_pc_retry
  ,input  I_coretoictlb_pc_type    coretoictlb_pc

  // prefetch request (uses the fwd port opportunistically)
  ,input                           pfetol1tlb_req_valid
  ,output                          pfetol1tlb_req_retry
  ,input  I_pfetol1tlb_req_type    pfetol1tlb_req

  // forward st core interface
  ,output                          l1tlbtol1_fwd_valid
  ,input                           l1tlbtol1_fwd_retry
  ,output I_l1tlbtol1_fwd_type     l1tlbtol1_fwd

  // Notify the L1 that the index of the TLB is gone
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
  /* verilator lint_on UNUSED */
);

`ifdef L1IT_PASSTHROUGH

  assign l1tlbtol1_cmd_valid     = 1'b0;
  assign l1tlbtol2tlb_req_valid  = 1'b0;
  assign l1tlbtol2tlb_sack_valid = 1'b0;


  // LOAD REQUESTS to FWD PORT

  I_l1tlbtol1_fwd_type l1tlbtol1_fwd1_next;
  logic l1tlbtol1_fwd1_retry_next, l1tlbtol1_fwd0_valid_next;

  always_comb begin
    if(coretoictlb_ld_valid) begin
      l1tlbtol1_fwd1_next.coreid = coretoictlb_ld.coreid;
      l1tlbtol1_fwd1_next.prefetch = 1'b0;
      l1tlbtol1_fwd1_next.fault = 1'b0; 
      l1tlbtol1_fwd1_next.hpaadr = coretoictlb_ld.laddr[22:12];
      l1tlbtol1_fwd1_next.ppaadr = coretoictlb_ld.laddr[14:12];

      l1tlbtol1_fwd1_valid_next = coretoictlb_ld_valid;
      coretoictlb_ld_retry = l1tlbtol1_fwd1_retry_next;

    end else if(~pfetol1tlb_req.l2) begin
      l1tlbtol1_fwd1_next.coreid = 'b0;
      l1tlbtol1_fwd1_next.prefetch = 1'b1;
      l1tlbtol1_fwd1_next.fault = 1'b0;
      l1tlbtol1_fwd1_next.hpaadr = pfetol1tlb_req.laddr[22:12];
      l1tlbtol1_fwd1_next.ppaadr = pfetol1tlb_req.laddr[14:12];

      l1tlbtol1_fwd1_valid_next = pfetol1tlb_req_valid;
      pfetol1tlb_req_retry = l1tlbtol1_fwd1_retry_next & pfetol1tlb_req_valid;
    end
  end


  fflop #(.Size($bits(I_l1tlbtol1_fwd_type))) ld_req_pt(
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
