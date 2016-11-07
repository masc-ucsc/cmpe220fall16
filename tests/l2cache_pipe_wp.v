
`include "scmem.vh"


module l2cache_pipe_wp(
    input                                 clk,
    input                                 reset,

    //---------------------------
    // L1 (icache or dcache)<->l2cache_pipe interface
    
    // input  I_l1tol2_req_type             l1tol2_req,
    input                                 l1tol2_req_valid,
    output                                l1tol2_req_retry,
      // Dispatching
    input   L1_reqid_type                 l1tol2_req_l1id, // 5 bit
    input   SC_cmd_type                   l1tol2_req_cmd, // 3 bit
    input   SC_pcsign_type                l1tol2_req_pcsign, // 13 bit
    input   SC_ppaddr_type                l1tol2_req_ppaddr, // 3 bit
    input   SC_poffset_type               l1tol2_req_poffset, // 12 bit
    
    // output I_l2tol1_snack_type           l2tol1_snack,
    output                                l2tol1_snack_valid,
    input                                 l2tol1_snack_retry,
      // Dispatching
    output  L1_reqid_type                 l2tol1_snack_l1id, // 5
    output  L2_reqid_type                 l2tol1_snack_l2id, // 6
    output  SC_snack_type                 l2tol1_snack_snack, // 5
        // output  SC_line_type             l2tol1_snack_line,
    output  logic [63:0]                  l2tol1_snack_line7, // 64
    output  logic [63:0]                  l2tol1_snack_line6,
    output  logic [63:0]                  l2tol1_snack_line5,
    output  logic [63:0]                  l2tol1_snack_line4,
    output  logic [63:0]                  l2tol1_snack_line3,
    output  logic [63:0]                  l2tol1_snack_line2,
    output  logic [63:0]                  l2tol1_snack_line1,
    output  logic [63:0]                  l2tol1_snack_line0, 
    output  SC_poffset_type               l2tol1_snack_poffset, // 12
    output  TLB_hpaddr_type               l2tol1_snack_hpaddr, // 11
    
    // input I_l2snoop_ack_type             l2snoop_ack,
    input                                 l1tol2_snoop_ack_valid,
    output                                l1tol2_snoop_ack_retry,
      // Dispatching
    input   L2_reqid_type                 l1tol2_snoop_ack_l2id, // 6
    input   DR_ndirs_type                 l1tol2_snoop_ack_directory_id, // 2

    // input I_l1tol2_disp_type             l1tol2_disp,
    input                                 l1tol2_disp_valid,
    output                                l1tol2_disp_retry,
      // Dispatching
    input   L1_reqid_type                 l1tol2_disp_l1id, // 5
    input   L2_reqid_type                 l1tol2_disp_l2id, // 6
    input   SC_disp_mask_type             l1tol2_disp_mask, // 64
    input   SC_dcmd_type                  l1tol2_disp_dcmd, // 3
         // input   SC_line_type            l1tol2_disp_line,
    input   logic [63:0]                  l1tol2_disp_line7,
    input   logic [63:0]                  l1tol2_disp_line6,
    input   logic [63:0]                  l1tol2_disp_line5,
    input   logic [63:0]                  l1tol2_disp_line4,
    input   logic [63:0]                  l1tol2_disp_line3,
    input   logic [63:0]                  l1tol2_disp_line2,
    input   logic [63:0]                  l1tol2_disp_line1,
    input   logic [63:0]                  l1tol2_disp_line0,
    input   SC_ppaddr_type                l1tol2_disp_ppaddr, // 3
    
    // output I_l2tol1_dack_type            l2tol1_dack,
    output                                l2tol1_dack_valid,
    input                                 l2tol1_dack_retry,
      // Dispatching
    output  L1_reqid_type                 l2tol1_dack_l1id, // 5
    
    // --------------------------------
    // L2TLB interface

    // input  I_l2tlbtol2_fwd_type          pftol2_pfreq,
    input                                 l2tlbtol2_fwd_valid,
    output                                l2tlbtol2_fwd_retry,
      // Dispatching
    input   L1_reqid_type                 l2tlbtol2_fwd_l1id, // 5
    input   logic                         l2tlbtol2_fwd_prefetch, // 1
    input   SC_fault_type                 l2tlbtol2_fwd_fault, // 3
    input   TLB_hpaddr_type               l2tlbtol2_fwd_hpaddr, // 11
    input   SC_paddr_type                 l2tlbtol2_fwd_paddr, // 50
        
    // output  PF_cache_stats_type          cachetopf_stats,
    output  logic [6:0]                   cachetopf_stats_nhitmissd,
    output  logic [6:0]                   cachetopf_stats_nhitmissp,
    output  logic [6:0]                   cachetopf_stats_nhithit,
    output  logic [6:0]                   cachetopf_stats_nmiss,
    output  logic [6:0]                   cachetopf_stats_ndrop,
    output  logic [6:0]                   cachetopf_stats_nreqs,
    output  logic [6:0]                   cachetopf_stats_nsnoops,
    output  logic [6:0]                   cachetopf_stats_ndisp,
    
    // ---------------------------------
    // Directory interface

    // output  I_l2todr_req_type            l2todr_req,
    output                                l2todr_req_valid,
    input                                 l2todr_req_retry,
      // Dispatching
    output  SC_nodeid_type                l2todr_req_nid, // 5 bit
    output  L2_reqid_type                 l2todr_req_l2id, // 6 bit
    output  SC_cmd_type                   l2todr_req_cmd, // 3 bit
    output  SC_paddr_type                 l2todr_req_paddr, // 50 bit

    // input  I_drtol2_snack_type           drtol2_snack,
    input                                 drtol2_snack_valid,
    output                                drtol2_snack_retry,
      // Dispatching
    input   SC_nodeid_type                drtol2_snack_nid, // 5
    input   L2_reqid_type                 drtol2_snack_l2id, // 6
    input   DR_reqid_type                 drtol2_snack_drid, // 6
	input   DR_ndirs_type                 drtol2_snack_directory_id, // 2
    input   SC_snack_type                 drtol2_snack_snack, // 5
        // input  SC_line_type              drtol2_snack_line,
    input   logic [63:0]                  drtol2_snack_line7, // 64
    input   logic [63:0]                  drtol2_snack_line6,
    input   logic [63:0]                  drtol2_snack_line5,
    input   logic [63:0]                  drtol2_snack_line4,
    input   logic [63:0]                  drtol2_snack_line3,
    input   logic [63:0]                  drtol2_snack_line2,
    input   logic [63:0]                  drtol2_snack_line1,
    input   logic [63:0]                  drtol2_snack_line0,
    input   SC_paddr_type                 drtol2_snack_paddr, // 50

    // output I_l2snoop_ack_type            l2todr_snoop_ack,
    output                                l2todr_snoop_ack_valid,
    input                                 l2todr_snoop_ack_retry,
    output  L2_reqid_type                 l2todr_snoop_ack_l2id, // 6
	output  DR_ndirs_type                  l2todr_snoop_ack_directory_id, // 2   

    // output I_l2todr_disp_type            l2todr_disp,
    output                                l2todr_disp_valid,
    input                                 l2todr_disp_retry,
      // Dispatching
    output  SC_nodeid_type                l2todr_disp_nid, // 5
    output  L2_reqid_type                 l2todr_disp_l2id, // 6
    output  DR_reqid_type                 l2todr_disp_drid, // 6
    output  SC_disp_mask_type             l2todr_disp_mask, // 64
    output  SC_dcmd_type                  l2todr_disp_dcmd, // 3
        // SC_line_type                     l2todr_disp_line,
    output  logic [63:0]                  l2todr_disp_line7,
    output  logic [63:0]                  l2todr_disp_line6,
    output  logic [63:0]                  l2todr_disp_line5,
    output  logic [63:0]                  l2todr_disp_line4,
    output  logic [63:0]                  l2todr_disp_line3,
    output  logic [63:0]                  l2todr_disp_line2,
    output  logic [63:0]                  l2todr_disp_line1,
    output  logic [63:0]                  l2todr_disp_line0,
    output  SC_paddr_type                 l2todr_disp_paddr,

    // input  I_drtol2_dack_type            drtol2_dack,
    input                                 drtol2_dack_valid,
    output                                drtol2_dack_retry,
      // Dispatching
    input   SC_nodeid_type                drtol2_dack_nid, // 5
    input   L2_reqid_type                 drtol2_dack_l2id, // 6

    // output I_l2todr_pfreq_type          l2todr_pfreq,
    output                                l2todr_pfreq_valid,
    input                                 l2todr_pfreq_retry,
      // Dispatching
    output  SC_paddr_type                 l2todr_pfreq_nid, // 5
    output  SC_nodeid_type                l2todr_pfreq_paddr // 50

);

    l2cache_pipe
    l2(
      .clk(clk),
      .reset(reset),

    // L2s interface
      .l1tol2_req_valid(l1tol2_req_valid),
      .l1tol2_req_retry(l1tol2_req_retry),
      .l1tol2_req({     l1tol2_req_l1id,
                        l1tol2_req_cmd,
                        l1tol2_req_pcsign,
                        l1tol2_req_poffset,
                        l1tol2_req_ppaddr}),
      
      .l2tol1_snack_valid(l2tol1_snack_valid),
      .l2tol1_snack_retry(l2tol1_snack_retry),
      .l2tol1_snack({     l2tol1_snack_l1id,
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
                          l2tol1_snack_poffset,
                          l2tol1_snack_hpaddr}),

       .l1tol2_snoop_ack_valid(l1tol2_snoop_ack_valid),
       .l1tol2_snoop_ack_retry(l1tol2_snoop_ack_retry),
       .l1tol2_snoop_ack( {     l1tol2_snoop_ack_l2id,
                                l1tol2_snoop_ack_directory_id}),

       .l1tol2_disp_valid(l1tol2_disp_valid),
       .l1tol2_disp_retry(l1tol2_disp_retry),
       .l1tol2_disp({     l1tol2_disp_l1id,
                          l1tol2_disp_l2id,
                          l1tol2_disp_mask,
                          l1tol2_disp_dcmd,
                          l1tol2_disp_line7,
                          l1tol2_disp_line6,
                          l1tol2_disp_line5,
                          l1tol2_disp_line4,
                          l1tol2_disp_line3,
                          l1tol2_disp_line2,
                          l1tol2_disp_line1,
                          l1tol2_disp_line0,
                          l1tol2_disp_ppaddr}),

        .l2tol1_dack_valid(l2tol1_dack_valid),
        .l2tol1_dack_retry(l2tol1_dack_retry),
        .l2tol1_dack(      l2tol1_dack_l1id),

        .l2tlbtol2_fwd_valid(l2tlbtol2_fwd_valid),
        .l2tlbtol2_fwd_retry(l2tlbtol2_fwd_retry),
        .l2tlbtol2_fwd({     l2tlbtol2_fwd_l1id,
                             l2tlbtol2_fwd_prefetch,
                             l2tlbtol2_fwd_fault,
                             l2tlbtol2_fwd_hpaddr,
                             l2tlbtol2_fwd_paddr}),

        .cachetopf_stats({  cachetopf_stats_nhitmissd,
                            cachetopf_stats_nhitmissp,
                            cachetopf_stats_nhithit,
                            cachetopf_stats_nmiss,
                            cachetopf_stats_ndrop,
                            cachetopf_stats_nreqs,
                            cachetopf_stats_nsnoops,
                            cachetopf_stats_ndisp}),

        .l2todr_req_valid(l2todr_req_valid),
        .l2todr_req_retry(l2todr_req_retry),
        .l2todr_req({     l2todr_req_nid, 
                          l2todr_req_l2id,
                          l2todr_req_cmd,
                          l2todr_req_paddr}),

        .drtol2_snack_valid(drtol2_snack_valid),
        .drtol2_snack_retry(drtol2_snack_retry),
        .drtol2_snack({     drtol2_snack_nid, 
                            drtol2_snack_l2id,
                            drtol2_snack_drid,
                            drtol2_snack_directory_id,
                            drtol2_snack_snack,
                            drtol2_snack_line7,
                            drtol2_snack_line6,
                            drtol2_snack_line5,
                            drtol2_snack_line4,
                            drtol2_snack_line3,
                            drtol2_snack_line2,
                            drtol2_snack_line1,
                            drtol2_snack_line0,
                            drtol2_snack_paddr}),

        .l2todr_snoop_ack_valid(l2todr_snoop_ack_valid),
        .l2todr_snoop_ack_retry(l2todr_snoop_ack_retry),
        .l2todr_snoop_ack(      {l2todr_snoop_ack_l2id, l2todr_snoop_ack_directory_id}),

        .l2todr_disp_valid(l2todr_disp_valid),
        .l2todr_disp_retry(l2todr_disp_retry),
        .l2todr_disp({     l2todr_disp_nid, 
                           l2todr_disp_l2id,
                           l2todr_disp_drid,
                           l2todr_disp_mask,
                           l2todr_disp_dcmd,
                           l2todr_disp_line7,
                           l2todr_disp_line6,
                           l2todr_disp_line5,
                           l2todr_disp_line4,
                           l2todr_disp_line3,
                           l2todr_disp_line2,
                           l2todr_disp_line1,
                           l2todr_disp_line0,
                           l2todr_disp_paddr}),

         .drtol2_dack_valid(drtol2_dack_valid),
         .drtol2_dack_retry(drtol2_dack_retry),
         .drtol2_dack({     drtol2_dack_nid, 
                            drtol2_dack_l2id}),

         .l2todr_pfreq_valid(l2todr_pfreq_valid),
         .l2todr_pfreq_retry(l2todr_pfreq_retry),
         .l2todr_pfreq( {    l2todr_pfreq_nid,
                             l2todr_pfreq_paddr})

      );

endmodule
