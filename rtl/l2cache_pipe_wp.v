
module l2cache_pipe_wp(
    input                                 clk,
    input                                 reset,

    //---------------------------
    // L1 (icache or dcache)<->l2cache_pipe interface
    
    // input  I_l1tol2_req_type             l1tol2_req,
    input                                 l1tol2_req_valid,
    output                                l1tol2_req_retry,
      // Dispatching
    input   L1_reqid_type                 l1tol2_req_dcid,
    input   SC_cmd_type                   l1tol2_req_cmd,
    input   SC_pcsign_type                l1tol2_req_pcsign,
    input   SC_laddr_type                 l1tol2_req_laddr,
    input   SC_sptbr_type                 l1tol2_req_sptbr,
    
    // output I_l2tol1_snack_type           l2tol1_snack,
    output                                l2tol1_snack_valid,
    input                                 l2tol1_snack_retry,
      // Dispatching
    output  L1_reqid_type                 l2tol1_snack_dcid,
    output  L2_reqid_type                 l2tol1_snack_l2id,
    output  SC_snack_type                 l2tol1_snack_snack,
        // output  SC_line_type                 l2tol1_snack_line,
    output  logic [63:0]        l2tol1_snack_line7,
    output  logic [63:0]         l2tol1_snack_line6,
    output  logic [63:0]         l2tol1_snack_line5,
    output  logic [63:0]         l2tol1_snack_line4,
    output  logic [63:0]         l2tol1_snack_line3,
    output  logic [63:0]         l2tol1_snack_line2,
    output  logic [63:0]         l2tol1_snack_line1,
    output  logic [63:0]         l2tol1_snack_line0,
    output  SC_paddr_type                 l2tol1_snack_paddr,
    output  SC_dctlbe_type                l2tol1_snack_dctlbe,
    
    // input I_l2snoop_ack_type             l2snoop_ack,
    input                                 l1tol2_snoop_ack_valid,
    output                                l1tol2_snoop_ack_retry,
      // Dispatching
    input   L2_reqid_type                 l1tol2_snoop_ack_l2id,
    
    // input I_l1tol2_disp_type             l1tol2_disp,
    input                                 l1tol2_disp_valid,
    output                                l1tol2_diso_retry,
      // Dispatching
    input   L1_reqid_type                 l1tol2_disp_l1id,
    input   L2_reqid_type                 l1tol2_disp_l2id,
    input   SC_disp_mask_type            l1tol2_disp_mask,
    input   SC_dcmd_type                  l1tol2_disp_dcmd,
    input   SC_line_type                  l1tol2_disp_line,
    input   SC_paddr_type                 l1tol2_disp_paddr,
    
    // output I_l2tol1_dack_type            l2tol1_dack,
    output                                l2tol1_dack_valid,
    input                                 l2tol1_dack_retry,
    output  L1_reqid_type                 l2tol1_dack_l1id,
    
    // input  I_pftocache_req_type          pftocache_req,
    input                                 l1tol2_pfreq valid,
    output                                l1tol2_pfreq_retry,
    input   SC_laddr_type                 l1tol2_pfreq_laddr,
    input   SC_sptbr_type                 l1tol2_pfreq_sptbr

);

    l2cache_pipe
    l2(
      .clk(clk),
      .reset(reset),

    // L2s interface
      .l1tol2_req_valid(l1tol2_req_valid),
      .l1tol2_req_retry(l1tol2_req_retry),
      .l1tol2_req({     l1tol2_req_dcid,
                        l1tol2_req_cmd,
                        l1tol2_req_pcsign,
                        l1tol2_req_laddr,
                        l1tol2_req_sptbr}),
      
      .l2tol1_snack_valid(l2tol1_snack_valid),
      .l2tol1_snack_retry(l2tol1_snack_retry),
      .l2tol1_snack({     l2tol1_snack_dcid,
                          l2tol1_snack_l2id,
                          l2tol1_snack_snack,
                          l2tol1_snack_line7,
                          l2tol1_snack_line6,
                          l2tol1_snack_line5,
                          l2tol1_snack_line4,
                          l2tol1_snack_line3,
                          l2tol1_snack_line2,
                          l2tol1_snack_line1,
                          l2tol1_snack_line0,
                          l2tol1_snack_paddr,
                          l2tol1_snack_dctlbe}),

       .l1tol2_snoop_ack_valid(l1tol2_snoop_ack_valid),
       .l1tol2_snoop_ack_retry(l1tol2_snoop_ack_retry),
       .l1tol2_snoop_ack(      l1tol2_snoop_ack_l2id),

       .l1tol2_disp_valid(l1tol2_disp_valid),
       .l1tol2_disp_retry(l1tol2_disp_retry),
       .l1tol2_disp({     l1tol2_disp_l1id,
                          l1tol2_disp_l2id,
                          l1tol2_disp_mask,
                          l1tol2_disp_dcmd,
                          l1tol2_disp_line,
                          l1tol2_disp_paddr}),

        .l2tol1_dack_valid(l2tol1_dack_valid),
        .l2tol1_dack_retry(l2tol1_dack_retry),
        .l2tol1_dack(      l2tol1_dack_l1id),

        .l1tol2_pfreq_valid(l1tol2_pfreq_valid),
        .l1tol2_pfreq_retry(l1tol2_pfreq_retry),
        .l1tol2_pfreq({     l1tol2_pfreq_laddr,
                            l1tol2_pfreq_sptbr})
      );

endmodule
