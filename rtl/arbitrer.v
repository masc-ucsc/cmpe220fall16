
// Arbitrer aggregates the traffict from one core data to have a single
// interface.
//
// WHen a request comes to the L2, the arbitrer broadcast the message to all
// the TLBs, or when it goes to the cache it sends it only to the approviate
// cache looking at the address.

`include "scmem.vh"

module arbitrer(
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
   input                           clk
  ,input                           reset

  // L2D_0
  ,input  logic                    l2d_0todr_req_valid
  ,output logic                    l2d_0todr_req_retry
  ,input  I_l2todr_req_type        l2d_0todr_req

  ,output logic                    drtol2d_0_snack_valid
  ,input  logic                    drtol2d_0_snack_retry
  ,output I_drtol2_snack_type      drtol2d_0_snack

  ,output                          l2d_0todr_snoop_ack_valid
  ,input                           l2d_0todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       l2d_0todr_snoop_ack

  ,input  logic                    l2d_0todr_disp_valid
  ,output logic                    l2d_0todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_0todr_disp

  ,input  logic                    drtol2d_0_dack_valid
  ,output logic                    drtol2d_0_dack_retry
  ,input  I_drtol2_dack_type       drtol2d_0_dack

  ,input  logic                    l2d_0todr_pfreq_valid
  ,output logic                    l2d_0todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2d_0todr_pfreq

  // L2D_1
  ,input  logic                    l2d_1todr_req_valid
  ,output logic                    l2d_1todr_req_retry
  ,input  I_l2todr_req_type        l2d_1todr_req

  ,output logic                    drtol2d_1_snack_valid
  ,input  logic                    drtol2d_1_snack_retry
  ,output I_drtol2_snack_type      drtol2d_1_snack

  ,output                          l2d_1todr_snoop_ack_valid
  ,input                           l2d_1todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       l2d_1todr_snoop_ack

  ,input  logic                    l2d_1todr_disp_valid
  ,output logic                    l2d_1todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_1todr_disp

  ,input  logic                    drtol2d_1_dack_valid
  ,output logic                    drtol2d_1_dack_retry
  ,input  I_drtol2_dack_type       drtol2d_1_dack

  ,input  logic                    l2d_1todr_pfreq_valid
  ,output logic                    l2d_1todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2d_1todr_pfreq

`ifdef SC_4PIPE
  // l2d_2
  ,input  logic                    l2d_2todr_req_valid
  ,output logic                    l2d_2todr_req_retry
  ,input  I_l2todr_req_type        l2d_2todr_req

  ,output logic                    drtol2d_2_snack_valid
  ,input  logic                    drtol2d_2_snack_retry
  ,output I_drtol2_snack_type      drtol2d_2_snack

  ,output                          l2d_2todr_snoop_ack_valid
  ,input                           l2d_2todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       l2d_2todr_snoop_ack

  ,input  logic                    l2d_2todr_disp_valid
  ,output logic                    l2d_2todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_2todr_disp

  ,input  logic                    drtol2d_2_dack_valid
  ,output logic                    drtol2d_2_dack_retry
  ,input  I_drtol2_dack_type       drtol2d_2_dack

  ,input  logic                    l2d_2todr_pfreq_valid
  ,output logic                    l2d_2todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2d_2todr_pfreq

  // l2d_3
  ,input  logic                    l2d_3todr_req_valid
  ,output logic                    l2d_3todr_req_retry
  ,input  I_l2todr_req_type        l2d_3todr_req

  ,output logic                    drtol2d_3_snack_valid
  ,input  logic                    drtol2d_3_snack_retry
  ,output I_drtol2_snack_type      drtol2d_3_snack

  ,output                          l2d_3todr_snoop_ack_valid
  ,input                           l2d_3todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       l2d_3todr_snoop_ack

  ,input  logic                    l2d_3todr_disp_valid
  ,output logic                    l2d_3todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_3todr_disp

  ,input  logic                    drtol2d_3_dack_valid
  ,output logic                    drtol2d_3_dack_retry
  ,input  I_drtol2_dack_type       drtol2d_3_dack

  ,input  logic                    c0_l2d_3todr_pfreq_valid
  ,output logic                    l2d_3todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2d_3todr_pfreq
`endif

   // directory aggregator
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

  ,output logic                    l2todr_pfreq_valid
  ,input  logic                    l2todr_pfreq_retry
  ,output I_l2todr_pfreq_type      l2todr_pfreq

  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
  );


endmodule

