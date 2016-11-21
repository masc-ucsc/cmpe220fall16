//BISMILLAH HIR RAHMAN NIR RAHIM
`include "DC_define.v"
`include "logfunc.h"
module DC_1_databank  #(parameter Width = 36, Size =512, Forward=0)
(   
  input                            clk
 ,input                            reset
,input 				   bank_sel
 ,input                            req_valid
 ,output                           req_retry
 ,input                            write
 //,input [`log2(Size)-1:0]          req_pos
 //,input[`SET_INDEX_BITS-1:0]	   set_index
 ,input[`WAY_BITS-1:0]  	   way_no
 ,input[1:0]			  row_even_odd
// 
,input [35:0]                      req_data//req data 32bit data+4 bit valid bit/write musk
,input [28:0]                      req_addr//logical address
 ,output                           ack_valid
 ,input                            ack_retry
 ,output [Width-1:0]               ack_data
 );

if( bank_sel==1) begin

logic [`log2(Size)-1:0]  	req_pos_bank;
logic [4:0] 	set_index;//5bits VA[10:6]

always_comb//***********************************
begin 
assign set_index=req_addr[10:6];
assign req_pos_bank = (set_index*15)+{(way_no*4)+row_even_odd};//way_no starts at 0

end

 
ram_1port_fast
  #(.Width(Width), .Size(Size))
 bank (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_we      (write)
  ,.req_data	(req_data)
  ,.ack_retry   (ack_retry)
  ,.req_pos     (req_pos_bank)
  ,.req_retry (req_retry)
  ,. ack_valid ( ack_valid)
  ,.ack_data   (ack_data)
  );

always@(ack_data) begin//********************************************************888
if(ack_valid) begin
assign write=1'b1; 
assign req_data[35:32]=4'b111;
end
 else req_data[35:32]=4'b000;
end












end





endmodule 

