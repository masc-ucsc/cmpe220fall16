
module fflop_understand (
   input                           clk,
   input    reset,

   input    [15:0]    in1,
   input    in1_valid,
   output    in1_retry,

   output [15:0]    out1,
   output   out1_valid,
   input    out1_retry
);

logic   [15:0]  in1_r1_next;
logic   in1_r1_next_valid;
logic   in1_r1_next_retry;

logic   [15:0]  in1_r1;
logic   in1_r1_valid;
logic   in1_r1_retry;

assign  in1_r1_next = in1;
assign  in1_r1_next_valid = in1_valid;
assign  in1_retry = in1_r1_next_retry;

logic   [15:0]  in1_r2_next;
logic   in1_r2_next_valid;
logic   in1_r2_next_retry;

logic   [15:0]  in1_r2;
logic   in1_r2_valid;
logic   in1_r2_retry;

assign  in1_r2_next = in1_r1;
assign  in1_r2_next_valid = in1_r1_valid;
assign  in1_r1_retry = in1_r2_next_retry;

logic   [15:0]  in1_r3_next;
logic   in1_r3_next_valid;
logic   in1_r3_next_retry;

logic   [15:0]  in1_r3;
logic   in1_r3_valid;
logic   in1_r3_retry;

assign  in1_r3_next = in1_r2;
assign  in1_r3_next_valid = in1_r2_valid;
assign  in1_r2_retry = in1_r3_next_retry;


logic   [15:0] out1_next;
logic   out1_next_valid;
logic   out1_next_retry;
assign  out1_next = in1_r3;
assign   out1_next_valid = in1_r3_valid;
assign    in1_r3_retry = out1_next_retry;

fflop #(.Size($bits(in1))) f_in1_r1 (
    .clk      (clk),
    .reset    (reset),

    .din      (in1_r1_next),
    .dinValid (in1_r1_next_valid),
    .dinRetry (in1_r1_next_retry),

    .q        (in1_r1),
    .qValid   (in1_r1_valid),
    .qRetry   (in1_r1_retry)
    );

fflop #(.Size($bits(in1))) f_in1_r2 (
    .clk      (clk),
    .reset    (reset),

    .din      (in1_r2_next),
    .dinValid (in1_r2_next_valid),
    .dinRetry (in1_r2_next_retry),

    .q        (in1_r2),
    .qValid   (in1_r2_valid),
    .qRetry   (in1_r2_retry)
    );

fflop #(.Size($bits(in1))) f_in1_r3 (
    .clk      (clk),
    .reset    (reset),

    .din      (in1_r3_next),
    .dinValid (in1_r3_next_valid),
    .dinRetry (in1_r3_next_retry),

    .q        (in1_r3),
    .qValid   (in1_r3_valid),
    .qRetry   (in1_r3_retry)
    );

fflop #(.Size($bits(in1))) f_out1 (
    .clk      (clk),
    .reset    (reset),

    .din      (out1_next),
    .dinValid (out1_next_valid),
    .dinRetry (out1_next_retry),

    .q        (out1),
    .qValid   (out1_valid),
    .qRetry   (out1_retry)
    );


endmodule
