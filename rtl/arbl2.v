
// Arbitrer aggregates the traffict from one core data to have a single
// interface.
//
// WHen a request comes to the L2, the arbitrer broadcast the message to all
// the TLBs, or when it goes to the cache it sends it only to the approviate
// cache looking at the address.
//
// For each core, there are two aggregators. One for TLBs and another for
// dcaches

`include "scmem.vh"
`define ARBL2_PASSTHROUGH

module arbl2(
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
   input                           clk
  ,input                           reset

  // L2D_0 DATA
  ,input  logic                    l2d_0todr_req_valid
  ,output logic                    l2d_0todr_req_retry
  ,input  I_l2todr_req_type        l2d_0todr_req

  ,output logic                    drtol2d_0_snack_valid
  ,input  logic                    drtol2d_0_snack_retry
  ,output I_drtol2_snack_type      drtol2d_0_snack

  ,input                           l2d_0todr_snoop_ack_valid
  ,output                          l2d_0todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       l2d_0todr_snoop_ack

  ,input  logic                    l2d_0todr_disp_valid
  ,output logic                    l2d_0todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_0todr_disp

  ,output logic                    drtol2d_0_dack_valid
  ,input  logic                    drtol2d_0_dack_retry
  ,output I_drtol2_dack_type       drtol2d_0_dack

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

  ,input                           l2d_1todr_snoop_ack_valid
  ,output                          l2d_1todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       l2d_1todr_snoop_ack

  ,input  logic                    l2d_1todr_disp_valid
  ,output logic                    l2d_1todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_1todr_disp

  ,output logic                    drtol2d_1_dack_valid
  ,input  logic                    drtol2d_1_dack_retry
  ,output I_drtol2_dack_type       drtol2d_1_dack

  ,input  logic                    l2d_1todr_pfreq_valid
  ,output logic                    l2d_1todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2d_1todr_pfreq

`ifdef SC_4PIPE
  // l2d_2 DATA
  ,input  logic                    l2d_2todr_req_valid
  ,output logic                    l2d_2todr_req_retry
  ,input  I_l2todr_req_type        l2d_2todr_req

  ,output logic                    drtol2d_2_snack_valid
  ,input  logic                    drtol2d_2_snack_retry
  ,output I_drtol2_snack_type      drtol2d_2_snack

  ,input                           l2d_2todr_snoop_ack_valid
  ,output                          l2d_2todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       l2d_2todr_snoop_ack

  ,input  logic                    l2d_2todr_disp_valid
  ,output logic                    l2d_2todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_2todr_disp

  ,output logic                    drtol2d_2_dack_valid
  ,input  logic                    drtol2d_2_dack_retry
  ,output I_drtol2_dack_type       drtol2d_2_dack

  ,input  logic                    l2d_2todr_pfreq_valid
  ,output logic                    l2d_2todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2d_2todr_pfreq

  // l2d_3 DATA

  ,input  logic                    l2d_3todr_req_valid
  ,output logic                    l2d_3todr_req_retry
  ,input  I_l2todr_req_type        l2d_3todr_req

  ,output logic                    drtol2d_3_snack_valid
  ,input  logic                    drtol2d_3_snack_retry
  ,output I_drtol2_snack_type      drtol2d_3_snack

  ,input                           l2d_3todr_snoop_ack_valid
  ,output                          l2d_3todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       l2d_3todr_snoop_ack

  ,input  logic                    l2d_3todr_disp_valid
  ,output logic                    l2d_3todr_disp_retry
  ,input  I_l2todr_disp_type       l2d_3todr_disp

  ,output logic                    drtol2d_3_dack_valid
  ,input  logic                    drtol2d_3_dack_retry
  ,output I_drtol2_dack_type       drtol2d_3_dack

  ,input  logic                    l2d_3todr_pfreq_valid
  ,output logic                    l2d_3todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      l2d_3todr_pfreq
`endif

   // directory aggregator
  ,output                          l2todr_req_valid
  ,input                           l2todr_req_retry
  ,output  I_l2todr_req_type       l2todr_req

  ,input                           drtol2_snack_valid
  ,output                          drtol2_snack_retry
  ,input I_drtol2_snack_type       drtol2_snack

  ,output                          l2todr_disp_valid
  ,input                           l2todr_disp_retry
  ,output I_l2todr_disp_type       l2todr_disp

  ,input                           drtol2_dack_valid
  ,output                          drtol2_dack_retry
  ,input  I_drtol2_dack_type       drtol2_dack

  ,output                          l2todr_snoop_ack_valid
  ,input                           l2todr_snoop_ack_retry
  ,output I_drsnoop_ack_type       l2todr_snoop_ack

  ,output logic                    l2todr_pfreq_valid
  ,input  logic                    l2todr_pfreq_retry
  ,output I_l2todr_pfreq_type      l2todr_pfreq

  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
  );

`ifdef ARBL2_PASSTHROUGH

    I_l2todr_req_type l2todr_req_next;
    logic l2todr_req_valid_next, l2todr_req_retry_next;

    always_comb begin
        if(l2d_0todr_req_valid) begin
            l2todr_req_next = l2d_0todr_req;
            l2todr_req_next.nid[4:3] = 2'b00;

            l2todr_req_valid_next = l2d_0todr_req_valid;
            l2d_0todr_req_retry = l2todr_req_retry_next;

            l2d_1todr_req_retry = l2d_1todr_req_valid;
`ifdef SC_4PIPE
            l2d_2todr_req_retry = l2d_2todr_req_valid;
            l2d_3todr_req_retry = l2d_3todr_req_valid;
`endif
        end else if (l2d_1todr_req_valid) begin
            l2todr_req_next = l2d_1todr_req;
            l2todr_req_next.nid[4:3] = 2'b01;

            l2todr_req_valid_next = l2d_1todr_req_valid;
            l2d_0todr_req_retry = 1'b0;
            l2d_1todr_req_retry = l2todr_req_retry_next;
`ifdef SC_4PIPE
            l2d_2todr_req_retry = l2d_2todr_req_valid;
            l2d_3todr_req_retry = l2d_3todr_req_valid;
        end else if (l2d_2todr_req_valid) begin
            l2todr_req_next = l2d_2todr_req;
            l2todr_req_next.nid[4:3] = 2'b10;

            l2todr_req_valid_next = l2d_2todr_req_valid;
            l2d_0todr_req_retry = 1'b0;
            l2d_1todr_req_retry = 1'b0;
            l2d_2todr_req_retry = l2todr_req_retry_next;
            l2d_3todr_req_retry = l2d_3todr_req_valid;
        end else if (l2d_3todr_req_valid) begin
            l2todr_req_next = l2d_3todr_req;
            l2todr_req_next.nid[4:3] = 2'b11;

            l2todr_req_valid_next = l2d_3todr_req_valid;
            l2d_0todr_req_retry = 1'b0;
            l2d_1todr_req_retry = 1'b0;
            l2d_2todr_req_retry = 1'b0;
            l2d_3todr_req_retry = l2todr_req_retry_next;
`endif
        end else begin
            l2todr_req_valid_next = 1'b0;
            l2d_0todr_req_retry = 1'b0;
            l2d_1todr_req_retry = 1'b0;
            l2d_2todr_req_retry = 1'b0;
            l2d_3todr_req_retry = 1'b0;
        end
    end

    fflop #(.Size($bits(I_l2todr_req_type))) l2todr_req_ff(
         .clk(clk)
        ,.reset(reset)
        
        ,.dinValid(l2todr_req_valid_next)
        ,.dinRetry(l2todr_req_retry_next)
        ,.din(l2todr_req_next)

        ,.qValid(l2todr_req_valid)
        ,.qRetry(l2todr_req_retry)
        ,.q(l2todr_req)
    );
            

    I_drtol2_snack_type drtol2d_0_snack_next, drtol2d_1_snack_next;
    logic drtol2d_0_snack_retry_next, drtol2d_0_snack_valid_next;
    logic drtol2d_1_snack_retry_next, drtol2d_1_snack_valid_next;

`ifdef SC_4PIPE
    I_drtol2_snack_type drtol2d_2_snack_next, drtol2d_3_snack_next;
    logic drtol2d_2_snack_retry_next, drtol2d_2_snack_valid_next;
    logic drtol2d_3_snack_retry_next, drtol2d_3_snack_valid_next;
`endif

    always_comb begin
      if (drtol2_snack_valid) begin
        if(drtol2_snack.nid[4:3] == 2'b00) begin
          drtol2d_0_snack_valid_next = drtol2_snack_valid;
          drtol2_snack_retry = drtol2d_0_snack_retry_next;
          drtol2d_0_snack_next = drtol2_snack;

          drtol2d_1_snack_valid_next = 1'b0;

          `ifdef SC_4PIPE
            drtol2d_2_snack_valid_next = 1'b0;
            drtol2d_3_snack_valid_next = 1'b0;
          `endif

        end else if (drtol2_snack.nid[4:3] == 2'b01) begin
          drtol2d_1_snack_valid_next = drtol2_snack_valid;
          drtol2_snack_retry = drtol2d_1_snack_retry_next;
          drtol2d_1_snack_next = drtol2_snack;

          drtol2d_1_snack_valid_next = 1'b0;
          `ifdef SC_4PIPE
            drtol2d_2_snack_valid_next = 1'b0;
            drtol2d_3_snack_valid_next = 1'b0;

          end else if (drtol2_snack.nid[4:3] == 2'b10) begin
            drtol2d_2_snack_valid_next = drtol2_snack_valid;
            drtol2_snack_retry = drtol2d_2_snack_retry_next;
            drtol2d_2_snack_next = drtol2_snack;

            drtol2d_0_snack_valid_next = 1'b0;
            drtol2d_1_snack_valid_next = 1'b0;
            drtol2d_3_snack_valid_next = 1'b0;
          end else if (drtol2_snack.nid[4:3] == 2'b11) begin
            drtol2d_3_snack_valid_next = drtol2_snack_valid;
            drtol2_snack_retry = drtol2d_3_snack_retry_next;
            drtol2d_3_snack_next = drtol2_snack;

            drtol2d_0_snack_valid_next = 1'b0;
            drtol2d_1_snack_valid_next = 1'b0;
            drtol2d_2_snack_valid_next = 1'b0;
          `endif
        end else begin
          drtol2d_0_snack_valid_next = 1'b0;
          drtol2d_1_snack_valid_next = 1'b0;
          `ifdef SC_4PIPE
            drtol2d_2_snack_valid_next = 1'b0;
            drtol2d_3_snack_valid_next = 1'b0;
          `endif
          drtol2_snack_retry = 1'b0;
        end

      end else begin
        drtol2d_0_snack_valid_next = 1'b0;
        drtol2d_1_snack_valid_next = 1'b0;
        `ifdef SC_4PIPE
          drtol2d_2_snack_valid_next = 1'b0;
          drtol2d_3_snack_valid_next = 1'b0;
        `endif
        drtol2_snack_retry = 1'b0;
      end

    end
    
    fflop #(.Size($bits(I_drtol2_snack_type))) drtol2_0_snack_ff(
         .clk(clk)
        ,.reset(reset)

        ,.dinValid(drtol2d_0_snack_valid_next)
        ,.dinRetry(drtol2d_0_snack_retry_next)
        ,.din(drtol2d_0_snack_next)

        ,.qValid(drtol2d_0_snack_valid)
        ,.qRetry(drtol2d_0_snack_retry)
        ,.q(drtol2d_0_snack)
    );

    fflop #(.Size($bits(I_drtol2_snack_type))) drtol2_1_snack_ff(
         .clk(clk)
        ,.reset(reset)

        ,.dinValid(drtol2d_1_snack_valid_next)
        ,.dinRetry(drtol2d_1_snack_retry_next)
        ,.din(drtol2d_1_snack_next)

        ,.qValid(drtol2d_1_snack_valid)
        ,.qRetry(drtol2d_1_snack_retry)
        ,.q(drtol2d_1_snack)
    );

`ifdef SC_4PIPE

    fflop #(.Size($bits(I_drtol2_snack_type))) drtol2_2_snack_ff(
         .clk(clk)
        ,.reset(reset)

        ,.dinValid(drtol2d_2_snack_valid_next)
        ,.dinRetry(drtol2d_2_snack_retry_next)
        ,.din(drtol2d_2_snack_next)

        ,.qValid(drtol2d_2_snack_valid)
        ,.qRetry(drtol2d_2_snack_retry)
        ,.q(drtol2d_2_snack)
    );


    fflop #(.Size($bits(I_drtol2_snack_type))) drtol2_3_snack_ff(
         .clk(clk)
        ,.reset(reset)

        ,.dinValid(drtol2d_3_snack_valid_next)
        ,.dinRetry(drtol2d_3_snack_retry_next)
        ,.din(drtol2d_3_snack_next)

        ,.qValid(drtol2d_3_snack_valid)
        ,.qRetry(drtol2d_3_snack_retry)
        ,.q(drtol2d_3_snack)
    );
`endif

`endif

endmodule

