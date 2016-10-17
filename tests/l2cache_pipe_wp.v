
module l2cache_pipe_wp(
    input                           clk,
    input                           reset,

    //---------------------------
    // L1 (icache or dcache)<->l2cache_pipe interface
    input                           l1tol2_req_valid,
    output                          l1tol2_req_retry,
    // Dispatching
    // input  I_l1tol2_req_type        l1tol2_req,
    input   L1_reqid_type           l1tol2_req_dcid,
    input   SC_cmd_type             l1tol2_req_cmd,
    input   SC_pcsign_type          l1tol2_req_pcsign,
    input   SC_laddr_type           l1tol2_req_laddr,
    input   SC_sptbr_type           l1tol2_req_sptbr,

);

endmodule
