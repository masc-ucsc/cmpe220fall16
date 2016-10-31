`include "scmemc.vh"
`include "DC_define.v"

module DC_2_tagbanks  #(parameter Width = 24, Size =512, Forward=0, REQ_BITS=7)
//tag 18+counter 2[19,20]+states 3[21,22,23] =15
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
 ,input                            tag_sel
 ,input [Width-1:0]                req_value
 // 
              //Search Only for 18 bit tags
//Tomorrow should work for states and the tag value and the counter as well tomorrow

 ,output                           ack_valid
 ,output                           req_retry
 ,output [2:0]               ack_req
 ,output			   miss
 ,output			   hit
 ,output[2:0]			   way	
 ,output [REQ_BITS-1:0]		   ack_req_type
 //,output			   	   read_cnt
 //,output			   	   write_cnt


);

if(tag_sel==1) begin //tagbank enable

logic miss_total,miss_a,miss_b, hit_total,hit_a,hit_b,way_total,way_a,way_b,req_retry,req_retry_a,req_retry_b,ack_valid,ack_valid_a, ack_valid_b;;


logic index,sel_tag_a,sel_tag_b;


assign index=req_data[10:6];
always@(index)begin
if( index<=14) begin sel_tag_a=1;sel_tag_b=0;end
 else if( index>14) begin sel_tag_a=0;sel_tag_b=1;end
end

DC_1_tagcheck
  #(.Width(Width), .Size(Size))
 tag_a (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_type   (req_type)
  ,.write      (write)//we=0 for read
  //,.tag_sel      (tag_sel_0a)
 ,.req_data	(req_data)
 ,.req_value	(req_value)//search for Tag only while reading 
 ,.tag_sel_a_b(sel_tag_a)
 ,.ack_retry   (ack_retry)
 ,.req_retry   (req_retry)
 ,.ack_data    (ack_data)
 ,.ack_req (ack_req)
  ,.ack_valid   (ack_valid)
  ,.hit    (hit_a)
 ,.way    (way_a)
 ,.miss    (miss_a)
  );


DC_1_tagcheck
  #(.Width(Width), .Size(Size))
 tag_b (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_type   (req_type)
  ,.write      (write)//we=0 for read
 // ,.tag_sel      (tag_sel_0b)
  ,.req_data	(req_data)//search for Tag only while reading 
  ,.req_value	(req_value)
 ,.tag_sel_a_b(sel_tag_b)
 ,.ack_retry   (ack_retry)
 ,.req_retry   (req_retry)
 ,.ack_data    (ack_data)
 ,.ack_req (ack_req)
  ,.ack_valid   (ack_valid)
  ,.hit    (hit_b)
 ,.way    (way_a)
 ,.miss    (miss_b)
  );





/*
always@(req_tag)
begin assign hit=hit_a + hit_b;//any hit=1 is total hit
assign miss=hit_a + hit_b;
assign hit=miss_a + miss_b;
assign req_retry=req_retry_a + req_retry_b;
 assign ack_valid=_ack_valid_a + ack_valid_b;
assign way=way_a+way_b;
*/
/*if (miss==1) 
begin 
   if(req_type==`CORE_LOP_L08S|`CORE_LOP_L08U|`CORE_LOP_L16S|`CORE_LOP_L16U|`CORE_LOP_L32S|`CORE_LOP_L32U|`CORE_LOP_L64U|`CORE_LOP_L128U|`CORE_LOP_L256U|`CORE_LOP_L512U)
         ack_req_type=`SC_CMD_REQ_M;
   else  if(req_type==`CORE_MOP_S08|`CORE_MOP_XS00|`CORE_MOP_XS08|`CORE_MOP_XS16|`CORE_MOP_XS32|`CORE_MOP_XS64|`CORE_MOP_XS128|`CORE_MOP_XS256|CORE_MOP_XS512)
  ack_req_type=`SC_CMD_REQ_S; 
end
*/

       
  logic [2:0] current_state;
logic[17:0] req_tag;
assign current_state= ack_data[23:21];
assign req_tag= req_data[17:0];
logic I_state_found=0,cnt_val;
logic RRIP_found=0;
logic [2:0]  RRIP_way;


always@(set_index) begin //****************************************

if(miss)//#######
 begin  

for(way_no=0;way_no<8;way_no++) //after looking in 8 cache lines now is checking if any cache line in `I state.
  begin
    assign req_pos = (set_index*way_no);
   if (current_state==`I)
        begin 
	assign req_data[21:20]=2'b11; 
        write=1;
        if(req_type==`CORE_MOP_S08|`CORE_MOP_XS00|`CORE_MOP_XS08|`CORE_MOP_XS16|`CORE_MOP_XS32|`CORE_MOP_XS64|`CORE_MOP_XS128|`CORE_MOP_XS256|CORE_MOP_XS512)
        begin  assign req_data[22:24]=`S;//current_state=`S
               assign  ack_req=`SC_CMD_REQ_S; 
	end
          
       else if(req_type==`CORE_LOP_L08S|`CORE_LOP_L08U|`CORE_LOP_L16S|`CORE_LOP_L16U|`CORE_LOP_L32S|`CORE_LOP_L32U|`CORE_LOP_L64U|`CORE_LOP_L128U|`CORE_LOP_L256U|`CORE_LOP_L512U)
         begin assign req_data[22:24]=`M;//current_state=`M
  	assign	ack_req=`SC_CMD_REQ_M;
          end  // re_type   

    end //if current_state  
    
    assign I_state_found=1;

end //for loop : I state found and write the data there in Tag and send a Miss request to L2


 for(way_no=0;way_no<8;way_no++) //after looking in 8 cache lines now is checking if any cache line in RRIP=3
 begin
    assign req_pos = (set_index*way_no);
   if(req_data[21:20]==3) begin 
   assign RRIP_found=1;
    assign RRIP_way=way_no;end //if 
   end//for
 


while(I_state_found!=1)
begin
  for(way_no=0;way_no<8;way_no++) 
    begin
     assign req_pos = (set_index*way_no);
     assign      write=1;
     assign  cnt_val=req_data[21:20];
      cnt_val++;
     assign req_data[21:20]=cnt_val;
  end //for
 end //while




//***********************************
 ack_req_type=`SC_DCMDBITS; //issue ack_reqt to L2 for write back as dispalcement for way=RRIP;


end//if miss #########
end// @always****************************




end//tag_sel
endmodule








 

