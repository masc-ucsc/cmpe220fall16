
// FIXME:
//
// Any l2 cache pipe can go to any directory (and viceversa). The reason is to
// allow a per bank SMT option (dc_pipe and l2_pipe) and to handle the TLB
// misses that can go out of bank.
//
// Effectively, a 4 pipe dual core can switch to a 8 independent l2 coherent
// cores. No need to have a switch command as the DCs and L2s are coherent.

module net_2core2dr(
   input                           clk
  ,input                           reset

  // c0 core L2D and L2I
  ,input  logic                    c0_l2itodr_req_valid
  ,output logic                    c0_l2itodr_req_retry
  ,input  I_l2todr_req_type        c0_l2itodr_req

  ,output logic                    c0_drtol2i_snack_valid
  ,input  logic                    c0_drtol2i_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2i_snack

  ,output                          c0_drtol2i_snoop_ack_valid
  ,input                           c0_drtol2i_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_drtol2i_snoop_ack

  ,input  logic                    c0_l2itodr_disp_valid
  ,output logic                    c0_l2itodr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2itodr_disp

  ,input  logic                    c0_drtol2i_dack_valid
  ,output logic                    c0_drtol2i_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2i_dack

  // L2D_0
  ,input  logic                    c0_l2d_0todr_req_valid
  ,output logic                    c0_l2d_0todr_req_retry
  ,input  I_l2todr_req_type        c0_l2d_0todr_req

  ,output logic                    c0_drtol2d_0_snack_valid
  ,input  logic                    c0_drtol2d_0_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2d_0_snack

  ,output                          c0_drtol2d_0_snoop_ack_valid
  ,input                           c0_drtol2d_0_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_drtol2d_0_snoop_ack

  ,input  logic                    c0_l2d_0todr_disp_valid
  ,output logic                    c0_l2d_0todr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2d_0todr_disp

  ,input  logic                    c0_drtol2d_0_dack_valid
  ,output logic                    c0_drtol2d_0_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2d_0_dack

  // L2D_1
  ,input  logic                    c0_l2d_1todr_req_valid
  ,output logic                    c0_l2d_1todr_req_retry
  ,input  I_l2todr_req_type        c0_l2d_1todr_req

  ,output logic                    c0_drtol2d_1_snack_valid
  ,input  logic                    c0_drtol2d_1_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2d_1_snack

  ,output                          c0_drtol2d_1_snoop_ack_valid
  ,input                           c0_drtol2d_1_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_drtol2d_1_snoop_ack

  ,input  logic                    c0_l2d_1todr_disp_valid
  ,output logic                    c0_l2d_1todr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2d_1todr_disp

  ,input  logic                    c0_drtol2d_1_dack_valid
  ,output logic                    c0_drtol2d_1_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2d_1_dack

`ifdef SC_4PIPE
  // l2d_2
  ,input  logic                    c0_l2d_2todr_req_valid
  ,output logic                    c0_l2d_2todr_req_retry
  ,input  I_l2todr_req_type        c0_l2d_2todr_req

  ,output logic                    c0_drtol2d_2_snack_valid
  ,input  logic                    c0_drtol2d_2_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2d_2_snack

  ,output                          c0_drtol2d_2_snoop_ack_valid
  ,input                           c0_drtol2d_2_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_drtol2d_2_snoop_ack

  ,input  logic                    c0_l2d_2todr_disp_valid
  ,output logic                    c0_l2d_2todr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2d_2todr_disp

  ,input  logic                    c0_drtol2d_2_dack_valid
  ,output logic                    c0_drtol2d_2_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2d_2_dack

  // l2d_3
  ,input  logic                    c0_l2d_3todr_req_valid
  ,output logic                    c0_l2d_3todr_req_retry
  ,input  I_l2todr_req_type        c0_l2d_3todr_req

  ,output logic                    c0_drtol2d_3_snack_valid
  ,input  logic                    c0_drtol2d_3_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2d_3_snack

  ,output                          c0_drtol2d_3_snoop_ack_valid
  ,input                           c0_drtol2d_3_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_drtol2d_3_snoop_ack

  ,input  logic                    c0_l2d_3todr_disp_valid
  ,output logic                    c0_l2d_3todr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2d_3todr_disp

  ,input  logic                    c0_drtol2d_3_dack_valid
  ,output logic                    c0_drtol2d_3_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2d_3_dack
`endif

  // c0 core L2D and L2I
  ,input  logic                    c1_l2itodr_req_valid
  ,output logic                    c1_l2itodr_req_retry
  ,input  I_l2todr_req_type        c1_l2itodr_req

  ,output logic                    c1_drtol2i_snack_valid
  ,input  logic                    c1_drtol2i_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2i_snack

  ,output                          c1_drtol2i_snoop_ack_valid
  ,input                           c1_drtol2i_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_drtol2i_snoop_ack

  ,input  logic                    c1_l2itodr_disp_valid
  ,output logic                    c1_l2itodr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2itodr_disp

  ,input  logic                    c1_drtol2i_dack_valid
  ,output logic                    c1_drtol2i_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2i_dack

  // L2D_0
  ,input  logic                    c1_l2d_0todr_req_valid
  ,output logic                    c1_l2d_0todr_req_retry
  ,input  I_l2todr_req_type        c1_l2d_0todr_req

  ,output logic                    c1_drtol2d_0_snack_valid
  ,input  logic                    c1_drtol2d_0_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2d_0_snack

  ,output                          c1_drtol2d_0_snoop_ack_valid
  ,input                           c1_drtol2d_0_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_drtol2d_0_snoop_ack

  ,input  logic                    c1_l2d_0todr_disp_valid
  ,output logic                    c1_l2d_0todr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2d_0todr_disp

  ,input  logic                    c1_drtol2d_0_dack_valid
  ,output logic                    c1_drtol2d_0_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2d_0_dack

  // L2D_1
  ,input  logic                    c1_l2d_1todr_req_valid
  ,output logic                    c1_l2d_1todr_req_retry
  ,input  I_l2todr_req_type        c1_l2d_1todr_req

  ,output logic                    c1_drtol2d_1_snack_valid
  ,input  logic                    c1_drtol2d_1_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2d_1_snack

  ,output                          c1_drtol2d_1_snoop_ack_valid
  ,input                           c1_drtol2d_1_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_drtol2d_1_snoop_ack

  ,input  logic                    c1_l2d_1todr_disp_valid
  ,output logic                    c1_l2d_1todr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2d_1todr_disp

  ,input  logic                    c1_drtol2d_1_dack_valid
  ,output logic                    c1_drtol2d_1_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2d_1_dack

`ifdef SC_4PIPE
  // l2d_2
  ,input  logic                    c1_l2d_2todr_req_valid
  ,output logic                    c1_l2d_2todr_req_retry
  ,input  I_l2todr_req_type        c1_l2d_2todr_req

  ,output logic                    c1_drtol2d_2_snack_valid
  ,input  logic                    c1_drtol2d_2_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2d_2_snack

  ,output                          c1_drtol2d_2_snoop_ack_valid
  ,input                           c1_drtol2d_2_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_drtol2d_2_snoop_ack

  ,input  logic                    c1_l2d_2todr_disp_valid
  ,output logic                    c1_l2d_2todr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2d_2todr_disp

  ,input  logic                    c1_drtol2d_2_dack_valid
  ,output logic                    c1_drtol2d_2_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2d_2_dack

  // l2d_3
  ,input  logic                    c1_l2d_3todr_req_valid
  ,output logic                    c1_l2d_3todr_req_retry
  ,input  I_l2todr_req_type        c1_l2d_3todr_req

  ,output logic                    c1_drtol2d_3_snack_valid
  ,input  logic                    c1_drtol2d_3_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2d_3_snack

  ,output                          c1_drtol2d_3_snoop_ack_valid
  ,input                           c1_drtol2d_3_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_drtol2d_3_snoop_ack

  ,input  logic                    c1_l2d_3todr_disp_valid
  ,output logic                    c1_l2d_3todr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2d_3todr_disp

  ,input  logic                    c1_drtol2d_3_dack_valid
  ,output logic                    c1_drtol2d_3_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2d_3_dack
`endif

  ,input                           l2todr_req_valid
  ,output                          l2todr_req_retry
  ,input  I_l2todr_req_type        l2todr_req

  ,output                          drtol2_snack_valid
  ,input                           drtol2_snack_retry
  ,output I_drtol2_snack_type      drtol2_snack

  ,input                           l2todr_disp_valid
  ,output                          l2todr_disp_retry
  ,input  I_l2todr_disp_type       l2todr_disp

  ,output                          drtol2_dack_valid
  ,input                           drtol2_dack_retry
  ,output I_drtol2_dack_type       drtol2_dack

  ,output                          l2todr_snoop_ack_valid
  ,input                           l2todr_snoop_ack_retry
  ,output I_drsnoop_ack_type       l2todr_snoop_ack
  );

  // Connect L2s to directory using a ring or switch topology

endmodule

