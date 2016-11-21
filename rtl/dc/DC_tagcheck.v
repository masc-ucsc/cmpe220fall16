//BISMILLAH HIR RAHMAN NIR RAHIM
`include "DC_define.v"
`include "logfunc.h"
`include "scmem.vh"

module DC_tagcheck  #(parameter Width = 24, Size =512, Forward=0, REQ_BITS=7)
//tag 18+counter 2[19,20]+states 3[21,22,23] =15//29 bits virtual adress
(   
  input                            clk
 ,input                            reset
 ,input                            req_valid
 ,input [REQ_BITS-1:0]		   req_type	
 ,input                            write
 //,input [`log2(Size)-1:0]          req_pos
 //,input[`SET_INDEX_BITS-1:0]	   set_index //Tag only get the index
 //,output[`WAY_BITS-1:0]  	   way
 //,input				   even_odd
 ,input                           ack_retry
,input [Width-1:0]                req_data
// 
              //Search Only for 18 bit tags
//Tomorrow should work for states and the tag value and the counter as well tomorrow

 ,output                           ack_valid
 ,output                           req_retry
 //,output [Width-1:0]               ack_data
 ,output			   miss
 ,output			   hit
 ,output[2:0]			   way	
 //,output			   	   read_cnt
 //,output			   	   write_cnt


);


 
 logic [`log2(Size)-1:0]  	req_pos;
 logic 				counter,req_tag_search;
 logic 				set_index;
 
 assign set_index=req_data[10:6];
 assign counter=req_data[20:21];
  assign req_tag_search=req_data[28:11];
 assign req_pos = (set_index*4);


always@(req_data) begin// all works at time=0 counter-- for RRIP
 if( req_valid) 
 begin
 write=1;
 assign counter=counter-1;
 assign req_data[20:21]=counter;
 end
end	
 

 //logic 				req_we;
 //assign req_we=1'b0;//write enable=0;

DC_1_tagbank
  #(.Width(Width), .Size(Size))
 tagbank (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_type (req_type)
  ,.write      (write)//we=0 for read
  ,.req_data	(req_tag_search)//search for Tag only while reading 
  ,.ack_retry   (ack_retry)
  ,.req_pos_tag (req_pos)//search the set index position 
  ,.req_retry   (req_retry)
  ,.ack_valid   (ack_valid)
  ,.ack_data    (ack_data_tag)
  );


logic                   way_no;


 
always@(req_data) begin
 for(way_no=0;way_no<=4;way_no++)
 begin

   if (ack_data[17:0]!=ack_data_tag[`TAGBITS-1:0])
   begin 
      set_index++;
      way_no++; 
   end
  else way=way_no;//hit here//gives the way from the tag


 end

 //miss_cnt++;
assign miss=1'b1;
assign hit=1'b0;
end












endmodule





























































/*//Stores
`CORE_MOP_S512:begin if (state_bits==`UM) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
			end
          

 `CORE_MOP_S256:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_MOP_S128:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_MOP_S64:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_MOP_S32:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_MOP_S32:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
			end
          

 `CORE_MOP_S16:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_MOP_S16:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_MOP_S08:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_MOP_S08:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end


*/
 

