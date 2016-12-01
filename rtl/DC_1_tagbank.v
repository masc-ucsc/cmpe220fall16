`include "scmem.vh"
`include "DC_define.v"
`include "logfunc.h"
module DC_1_tagbank  #(parameter Width = 15, Size =256, Forward=0)
//tag 10+counter 2 bits [11:10]+states 3 bits[14:12] =>15
(   
 input                            clk
,input                            reset
,input                            req_valid
 //request byte is also important ld 8 byte or store 512assign set_index=req_data[10:6];
,input                            ack_retry
,input                            write_1_tagbank //if write enable then no read and outdata=0
,input [7:0]          req_pos_tag 
,input [Width-1:0]                req_data
,output                           req_retry
,output                           ack_valid
,output [14:0]                    ack_data                                                                                          
 /////////////////////////////////////////////////////////////
//5bit loadReq  
,input                             coretodc_ld_valid
,output                          coretodc_ld_retry
,input [4:0]                     coretodc_ld_req
// 7 bit store Req,atomic,checkpoint
,input                           coretodc_std_valid
,output                          coretodc_std_retry
,input  [6:0]    		   coretodc_std
//5 bit L2 -> DC ACK 
,input                           l2tol1_snack_valid
 // ,output                          l2tol1_snack_retry
,input  [4:0]                    l2tol1_snack
// 3 bit Displacement 
,output                          l1tol2_disp_valid//
//,input                           l1tol2_disp_retry//
,output [2:0]                    l1tol2_disp//
,output[2:0]			   state_cache

);

logic[14:0] ack_data_from_ram;
logic write = write_1_tagbank;


logic [14:0]                req_data_1_tagbank; //15 bits=10+2+3
assign req_data_1_tagbank= req_data;
ram_1port_fast
  #(.Width(Width), .Size(Size))
 tagbank (
  .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_we      (write)//we=0 for read
  ,.req_data	(req_data_1_tagbank)//search for Tag only while reading 
  ,.ack_retry   (ack_retry)
  ,.req_pos     (req_pos_tag)//search the set index position 
  ,.req_retry   (req_retry)
  ,.ack_valid   (ack_valid)
  ,.ack_data    (ack_data_from_ram)
  );

logic [2:0]     		state_bits;
assign state_bits=ack_data_from_ram[14:12];
logic [2:0]     		next_state_bits;
assign ack_data=ack_data_from_ram;

always@(coretodc_ld_valid or coretodc_ld_req)begin 
if ($bits(coretodc_ld_req)==5) begin 
     coretodc_ld_retry=0;
case(coretodc_ld_req)//look***********************************************
  //Loads Req that changes cache state   

 `CORE_LOP_L32U:begin if (state_bits==`US)  next_state_bits=`US;
                            else if (state_bits==`UM) next_state_bits=`UM; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		    end

default:next_state_bits =  state_bits; 

endcase

write =1'b1;//write enable
req_data_1_tagbank[14:12]=next_state_bits;
end //if end

state_cache=next_state_bits;
end //always


always@( l2tol1_snack or l2tol1_snack_valid )begin 
if ($bits(l2tol1_snack)==5) begin 
 case(l2tol1_snack)//look***********************************************
  //Loads Req that changes cache state   

 `SC_SCMD_ACK_S :begin if (state_bits==`US)  next_state_bits=`US;
                          else if (state_bits==`UM) next_state_bits=`UM; 
		               else if (state_bits==`M) begin next_state_bits=`S; l1tol2_disp=`SC_DCMD_WS;l1tol2_disp_valid=1;end
				   else if (state_bits==`E) next_state_bits=`S; 
					  else if (state_bits==`S) next_state_bits=`S; 
						 else next_state_bits	=  state_bits;  
			    
		 end


 `SC_SCMD_ACK_E :begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`UM) next_state_bits=`UM; 
		                 else if (state_bits==`M) begin next_state_bits=`US; l1tol2_disp=`SC_DCMD_WS;end
					else if (state_bits==`E) next_state_bits=`US; 
						else if (state_bits==`S) next_state_bits=`US; 
							else 	next_state_bits	=  state_bits;   
			    
		end

 `SC_SCMD_ACK_M :begin if (state_bits==`I) next_state_bits=`E;
                            else if (state_bits==`I) next_state_bits=`S; 
			       else next_state_bits	=  state_bits;   
				    
		end

default:next_state_bits =  state_bits; 

endcase

write ='b1;//write enable
req_data_1_tagbank[14:12]=next_state_bits;
end //if end

state_cache=next_state_bits;

end //always


always@(coretodc_std)begin 
if ($bits(coretodc_std)==7 && coretodc_std_valid) begin 
coretodc_std_retry=0;

  case(coretodc_std)//look***********************************************
  //Loads Req that changes cache state   
 `CORE_MOP_S32: begin if (state_bits==`US) next_state_bits=`UM;
                            else if (state_bits==`S) next_state_bits=`UM; 
				else if (state_bits==`S) next_state_bits=`M; 
					else 	next_state_bits	=  `M;    
			end
 			
  default:next_state_bits =  state_bits; 
  endcase
end //if

state_cache=next_state_bits;

end //always
//logic [`CACHE_STATE-1:0]  	cache_state;
// assign cache_state=ack_data[21:23];
endmodule



