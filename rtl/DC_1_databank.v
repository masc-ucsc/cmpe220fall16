
`include "DC_define.v"
`include "logfunc.h"
`include "scmemc.vh"
module DC_1_databank  #(parameter Width = 36, Size =512, Forward=0)
(   //I adress 22 bits
//36=>4 bit valid bits+ 4 byte/32 bit data=36 bit in total per entry 1 databank
input                            clk
,input                            reset
,input 				   bank_sel
,input                            req_valid
,output                           req_retry
,input                            write
,input[2:0]  	                    way_no
,input		                   row_even_odd
,input [4:0]                      req_Index//I adress 23 bits
// 
,input [35:0]                      req_data//req data 32bit data+4 bit valid bit/write musk
,input [4:0] 			   Load_req
,input 			           Load_req_valid
,output				   Load_req_retry
,input [6:0] 			   STD_req
,input 			           STD_req_valid
,output				   STD_req_retry
,input 				   write_musk_reset
,output                           ack_valid
,input                            ack_retry
,output [35:0]                    ack_data
 );

//if( bank_sel==1) begin

logic [8:0]  	req_pos_bank;
logic [4:0] 	set_index;//5bits VA[10:6]
logic write_bank;
logic [8:0] index_ext,index_;
assign write_bank=write;
logic[35:0] req_data_for_bank,ack_data_ram;
logic [8:0] way_ext, odd_even_ext;//9 bits forr 512 entries as req_pos_bank 
parameter sixteen=5'b10000;
assign way_ext ={{6{1'b0}}, way_no};//make 9 bit
assign req_data_for_bank=req_data;

always@(bank_sel or req_Index or row_even_odd or way_no)//***********************************
begin 
if(bank_sel) begin
 set_index=req_Index;
index_ = {{4{1'b0}}, set_index};//make 5 bit index as 9 bits
index_ext=index_*sixteen ;//index*16=512 which is 9 bits
odd_even_ext={{8{1'b00000000}},row_even_odd};//9 bits
//odd_even_=row_even_odd;
 req_pos_bank = (index_ext*16)+(way_ext*2)+odd_even_ext;//way_no starts at 0
end
end
 
ram_1port_fast
  #(.Width(Width), .Size(Size))
 bank (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_we      (write_bank)
  ,.req_data	(req_data_for_bank)
  ,.ack_retry   (ack_retry)//input
  ,.req_pos     (req_pos_bank)
  ,.req_retry (req_retry)//output
  ,. ack_valid ( ack_valid)
  ,.ack_data   (ack_data_ram)
  );

always@( req_data_for_bank or bank_sel ) begin//********************************************************888
if((STD_req==`CORE_MOP_XS32)&& STD_req_valid)//|`CORE_MOP_XS00|`CORE_MOP_XS08|`CORE_MOP_XS16|`CORE_MOP_XS32|`CORE_MOP_XS64|`CORE_MOP_XS128|`CORE_MOP_XS256|`CORE_MOP_XS512) begin //
begin 
 write_bank=1'b1; 
end
 STD_req_retry=0;//32 bit data+4 bit valid bit per entry 1 data bank
end

always@( req_data_for_bank or bank_sel ) begin//********************************************************888
if(Load_req==`CORE_LOP_L32U) // READ if valid bits==4'b111
begin 
 if ((ack_data_ram[35:32]==4'b1111)&& Load_req_valid)begin 
    ack_valid=1;
    ack_data=ack_data_ram;  
    end
end
 Load_req_retry=0;
end



always_comb 
begin//********************************************************888
if(write_musk_reset)begin  //Invalidates make valid bits=0000begin 
write_bank=1'b1; 
req_data_for_bank[35:32]=4'b0000;  
end
end
endmodule 

