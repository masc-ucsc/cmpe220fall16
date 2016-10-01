
module flop_r #(parameter Size=1, Reset_Value='b0)(
  input clk
  ,input reset
  ,input [Size-1:0] din
  ,output reg [Size-1:0] q
  );

  always @(posedge clk) begin
    if (reset)
      q <= Reset_Value;
    else
      q <= din;
  end

endmodule 

