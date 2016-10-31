module DC_4_to_1_Multiplexer( 
input bank0
,input bank1
,input bank2
,input bank3
,input[1:0] sel
,output mux_out
);

always@(sel)begin 
assign bank0=0;
assign bank1=0;
assign bank2=0;
assign bank3=0;
case(sel)

  0: begin bank0=1;assign mux_out=bank0;end
 1:  begin bank1=1;assign mux_out=bank1;end
 2:  begin bank2=1;assign mux_out=bank2;end
 3:  begin bank3=1;assign mux_out=bank3;end
endcase

end

endmodule
