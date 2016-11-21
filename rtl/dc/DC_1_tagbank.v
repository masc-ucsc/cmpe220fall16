`include "scmem.vh"
`include "DC_define.v"
`include "logfunc.h"
module DC_1_tagbank  #(parameter Width = 24, Size =32, Forward=0)
//tag 18+counter 2[19,20]+states 3[21,22,23] =15
(   
  input                            clk
 ,input                            reset
 ,input                            req_valid
 ,input [REQ_BITS-1:0]		   req_type //request byte is also important ld 8 byte or store 512assign set_index=req_data[10:6];
 ,input                            ack_retry
 ,input                            write //if write enable then no read and outdata=0
 ,input [`log2(Size)-1:0]          req_pos_tag
 //,input[`SET_INDEX_BITS-1:0]	   set_index
 //,input[`WAY_BITS-1:0]  	   way_no
 //,input				   even_odd
 ,input [Width-1:0]                req_data

 ,output                           req_retry
 ,output                           ack_valid
 ,output [Width-1:0]               ack_data
 );

logic[17:0] req_tag;

assign req_tag=req_data[17:0];

//assign set_index=req_data[10:6];



ram_1port_fast
  #(.Width(Width), .Size(Size))
 tagbank (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_we      (write)//we=0 for read
  ,.req_data	(req_tag)//search for Tag only while reading 
  ,.ack_retry   (ack_retry)
  ,.req_pos     (req_pos_tag)//search the set index position 
  ,.req_retry   (req_retry)
  ,.ack_valid   (ack_valid)
  ,.ack_data    (ack_tag)
  );

 logic [2:0]     		state_bits;
 assign state_bits=ack_data_tag[23:21];
 logic [2:0]     		next_state_bits;

always@(state_bits)
 begin 
  case(req_type)//look***********************************************
  //Loads Req that changes cache state   
 `CORE_LOP_L512U:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
			end
          

 `CORE_LOP_L256U:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_LOP_L128U:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_LOP_L64U:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_LOP_L32U:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_LOP_L32S:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
			end
          

 `CORE_LOP_L16U:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_LOP_L16S:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_LOP_L08U:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 `CORE_LOP_L08S:begin if (state_bits==`US) next_state_bits=`US;
                            else if (state_bits==`E) next_state_bits=`E; 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
 
//COMMIT

 `CORE_MOP_BEGIN :begin if (state_bits==`US) next_state_bits=`US; 
                            else if (state_bits==`UM) next_state_bits=`US;
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end
`CORE_MOP_COMMIT :begin if (state_bits==`US) next_state_bits=`S;//issue gets req to L2 
                            else if (state_bits==`E) next_state_bits=`E; //issue wb to L2 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end

`CORE_MOP_CSYNC:begin if (state_bits==`US) next_state_bits=`S;//issue gets req to L2 
                            else if (state_bits==`E) next_state_bits=`E; //issue wb to L2 
				else if (state_bits==`S) next_state_bits=`S; 
					else 	next_state_bits	=  state_bits;    
		end

`CORE_MOP_KILL:begin  	next_state_bits	= `I;    
		end
 
`CORE_MOP_RESTART:begin  	next_state_bits	= `I;   
		end
			

 default:next_state_bits =  state_bits; 


endcase



//concatanate the new state bits to the datareq

assign req_we =1'b1;//write enable
assign req_data[23:21]=next_state_bits;	

//****************************************

end //End of Case and wrintting next state bit


//**********************************************
 



//logic [`CACHE_STATE-1:0]  	cache_state;
// assign cache_state=ack_data[21:23];











endmodule























/*
module DC_Tagbank(

	input enable, 
	input reset, 
	input [17:0] tag_addr, 
	input[4:0] set_index,
	

	output logic [2:0] line_in_set,
	output logic 	   hit


 );

//Tag bank Contains the tags of 8 cachelines per set, and there are 32 sets in the tag

logic [17:0] Tag_Bank [`SETS-1:0][`WAYS-1:0];
logic [17:0] curr_tag = tag_addr[17:0];
logic [4:0] curr_index = set_index[4:0];
integer set_cnt,way_cnt;
parameter TRUE	=1'b1;
parameter FALSE	=1'b0;

logic [63:0] Valid_Bytes_bank [`SETS-1:0][`WAYS-1:0];

if(reset==TRUE)
	begin
	    for(set_cnt=0; set_cnt<`SETS; set_cnt=set_cnt+1'b1)
	       begin	
	 	 for(way_cnt=0; way_cnt<`WAYS; way_cnt=way_cnt+1'b1)
		    begin  
			assign Tag_Bank[set_cnt][way_cnt]= 18'b0;
			//assign Valid_Bytes_bank[set_cnt][way_cnt]= 64'b0;
			//VAlid bits have to reset   $display("I = %d \n", i)
		    end
               end       

        end




else 

if(reset==FALSE)
begin 
	
	for(set_cnt=0; set_cnt<`SETS; set_cnt=set_cnt+1'b1)
	       begin	
	 	   for(way_cnt=0; way_cnt<`WAYS; way_cnt=way_cnt+1'b1)
		       begin 
			    if(Tag_Bank[set_cnt][way_cnt]==curr_index)
			        begin 
				 assign hit=TRUE;
				 assign line_in_set=curr_index; //giving the current cacheline number of the set
			        end
		       end
				

			//assign Tag_Bank[set_cnt][way_cnt]= 18'b0;
			//VAlid bits have to reset   $display("I = %d \n", i)
		end
 end  
	  

*/













