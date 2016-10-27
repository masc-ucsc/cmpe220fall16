
module fork_fflop(
  input         clk,
  input         reset,
  input  [7:0]  inp,
  input         inp_Valid,
  output        inp_Retry,

  output [7:0]  out_a,
  output        out_aValid,
  input         out_aRetry,
  
  output [7:0]  out_b,
  output        out_bValid,
  input         out_bRetry
);


  logic   inp_abValid;
  logic   inp_aRetry;
  logic   inp_bRetry;

  always_comb begin
    inp_abValid = inp_Valid && !inp_Retry;
  end
  
  always_comb begin
    inp_Retry = inp_aRetry || inp_bRetry;
  end



  fflop #(.Size(8)) ff_a (
    .clk      (clk),
    .reset    (reset),

    .din      (inp),
    .dinValid (inp_abValid),
    .dinRetry (inp_aRetry),

    .q        (out_a),
    .qValid   (out_aValid),
    .qRetry   (out_aRetry)
  );
  
  fflop #(.Size(8)) ff_b (
    .clk      (clk),
    .reset    (reset),

    .din      (inp),
    .dinValid (inp_abValid),
    .dinRetry (inp_bRetry),

    .q        (out_b),
    .qValid   (out_bValid),
    .qRetry   (out_bRetry)
  );

endmodule

