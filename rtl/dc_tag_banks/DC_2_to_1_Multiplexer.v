module DC_2_to_1_Multiplexer( 
input tag0
,input tag1

,input sel
,output mux_out
);

always@(sel)begin 
assign tag0=0;
assign tag1=0;

case(sel)

  0: begin tag0=1;assign mux_out=tag0;end
 1:  begin tag1=1;assign mux_out=tag1;end

endcase

end

endmodule
