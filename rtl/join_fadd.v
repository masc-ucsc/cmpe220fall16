
module join_fadd(
  input       clk,
  input       reset,
  input [7:0] inp_a,
  input       inp_aValid,
  output      inp_aRetry,

  input [7:0] inp_b,
  input       inp_bValid,
  output      inp_bRetry,

  output [7:0] sum,
  output       sumValid,
  input        sumRetry
);

  logic [7:0] sum_next;

  always_comb begin
    sum_next = inp_a + inp_b;
  end

  logic   inpValid;
  logic   inpRetry;

  always_comb begin
    inpValid = inp_aValid && inp_bValid;
  end

  always_comb begin
`ifdef LAZY_OPTION
    inp_bRetry = inpRetry || !inpValid;
    inp_aRetry = inpRetry || !inpValid;
`else
    inp_bRetry = inpRetry || (!inpValid && inp_bValid);
    inp_aRetry = inpRetry || (!inpValid && inp_aValid);

    //inp_bRetry = inpRetry || (!inpValid && inp_bValid) || (!inpValid && inp_aValid);
    //inp_aRetry = inpRetry || (!inpValid && (inp_bValid || inp_aValid));
`endif
  end

  logic [7:0] sum2;
  logic       sum2Valid;
  logic       sum2Retry;

  fflop #(.Size(8)) f1 (
    .clk      (clk),
    .reset    (reset),

    .din      (sum_next),
    .dinValid (inpValid),
    .dinRetry (inpRetry),

    .q        (sum2),
    .qValid   (sum2Valid),
    .qRetry   (sum2Retry)
  );

  fflop #(.Size(8)) f2 (
    .clk      (clk),
    .reset    (reset),

    .din      (sum2),
    .dinValid (sum2Valid),
    .dinRetry (sum2Retry),

    .q        (sum),
    .qValid   (sumValid),
    .qRetry   (sumRetry)
  );

endmodule

