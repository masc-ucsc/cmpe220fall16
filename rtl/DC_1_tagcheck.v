
`include "DC_define.v"
`include "logfunc.h"
`include "scmemc.vh"

module DC_1_tagcheck  #(parameter Width = 15, Size =256, Forward=0, REQ_BITS=7)
//tag 10+counter 2+states 3 =15//29 bits virtual adress
(   
input                            	clk
,input                            	reset
,input                            	req_valid
,input                            	write
,input                           	ack_retry
,input [14:0]                    	req_tag
,input[4:0]			   	index
 //Search Only for 10 bit tags
,output                                 ack_valid
,output                                req_retry_to_1_tagcheck
,output [14:0]                         ack_data_to_1_tagcheck
 //****************************************,output [2:0]                     ack_req_to_L2 //3 bit ack req to L2
,output			               miss
,output			                hit
,output[2:0]			        way	
,input                           coretodc_ld_valid
,output                          coretodc_ld_retry
,input [4:0]                     coretodc_ld_req
  //---------------------------
  // 7 bit store Req,atomic,checkpoint
,input                           coretodc_std_valid
,output                          coretodc_std_retry
,input  [6:0]    		   coretodc_std
//3 bit DC->L2 Req
,output                          l1tol2_req_valid
,input                           l1tol2_req_retry
,output [2:0]		           l1tol2_req
//5 bit L2 -> DC ACK 
,input                           l2tol1_snack_valid
,input  [4:0]                    l2tol1_snack
// 3 bit Displacement 
,output                          l1tol2_disp_valid
,output [2:0]                    l1tol2_disp //command out displacement

);

 logic[2:0] state_line;
 logic [7:0]  	req_pos,req_pos_in_tag;
 reg [1:0] 				counter,counter_;
//,counter_RRIP;
 logic [9:0]				req_tag_search;
 logic [4:0] 					set_index;
 logic                                  write_1_tagcheck;
 logic [14:0] 				req_data_1_tagbank=req_tag;//req tag = 10 bit tag

 assign set_index=index;
 assign counter=req_tag[11:10];
 assign req_tag_search=req_tag[9:0];
 assign req_pos = (set_index*8);
 assign write_1_tagcheck=write;

always@(req_tag_search) 
 begin// all works at time=0 counter-- for RRIP
   write_1_tagcheck=1'b1;
   counter_=counter-1'b1;
  req_data_1_tagbank[11:10]=counter_;
end	

DC_1_tagbank
  #(.Width(Width), .Size(Size))
 tagbank (
 .clk      	(clk)
 ,.reset   	(reset)
 ,.req_valid	(req_valid)
 ,.write_1_tagbank      (write_1_tagcheck)//we=0 for read
 ,.req_data	(req_data_1_tagbank)
 ,.ack_retry   (ack_retry)
 ,.req_pos_tag (req_pos_in_tag )//search the set index position 
 ,.req_retry   (req_retry_to_1_tagcheck)
 ,.ack_valid   (ack_valid)
 ,.ack_data    (ack_data_to_1_tagcheck)
 ,.coretodc_ld_valid  (coretodc_ld_valid)
 ,.coretodc_ld_retry  (coretodc_ld_retry)
 ,.coretodc_ld_req  (coretodc_ld_req)
 ,.coretodc_std_valid  (coretodc_std_valid)
 ,.coretodc_std_retry  (coretodc_std_retry)
 ,.coretodc_std    (coretodc_std)
 ,.l2tol1_snack_valid  (l2tol1_snack_valid)
 ,.l2tol1_snack  (l2tol1_snack)
,.l1tol2_disp_valid   (l1tol2_disp_valid)
,.l1tol2_disp (l1tol2_disp)
,.state_cache(state_line)
);


 logic [2:0]                  way_no;
 logic  [7:0]  way_no_ext;//8 bits needed
 //logic NO_TAG_PRESENT=0;
 assign hit=1'b0;
 assign miss=1'b1;//miss is auto select but if hit then miss=0


 always @ (posedge clk) begin
   if(reset) begin
     way_no <= 0;
   end else begin
     if(way_no <= 7) begin
       way_no <= way_no + 1;
     end else begin
       way_no <= 0;
     end
   end
 end

 assign way_no_ext={{5{1'b0}},way_no};
 assign req_pos_in_tag = (req_pos+way_no_ext);

 always_comb begin 
   if (ack_data_to_1_tagcheck[9:0]== req_tag_search) begin 
     if(state_line!=`I)  begin//what happens if cacheline is hit but in I state?
       hit=1'b1; 
       miss=1'b0;
     end
     way = way_no;
   end else begin//if (ack_data_to_1_tagcheck[9:0]!= req_tag_search)
     hit=1'b0; 
     miss=1'b1;
   end
 end


 /*
always@(req_tag_search or set_index) begin
//if(tag_sel_a_b)begin
for(way_no=0;way_no<=7;way_no++) begin
    way_no_ext={{5{1'b0}},way_no};
    req_pos_in_tag = (req_pos+way_no_ext);
     if (ack_data_to_1_tagcheck[9:0]== req_tag_search) begin 
	 way=way_no;
         if(state_line!=`I)  begin//what happens if cacheline is hit but in I state?
         hit=1'b1; 
         miss=1'b0;
	 end
         end // req_tag_search
    	 else begin//if (ack_data_to_1_tagcheck[9:0]!= req_tag_search)
         hit=1'b0; 
         miss=1'b1;
	 end
end//for
end//always
*/

always_comb
begin 
if (miss|l1tol2_req_retry) 
begin 
if(coretodc_ld_valid) begin l1tol2_req_valid=1;l1tol2_req=`SC_CMD_REQ_S; end 
else if(coretodc_std_valid)  begin l1tol2_req_valid=1;l1tol2_req=`SC_CMD_REQ_M; end 
end//if miss
end//always_comb

/*
always_comb begin 
if (l2tol1_snack_valid) begin 
  if((l2tol1_snack==`SC_SCMD_ACK_S)||(l2tol1_snack==`SC_SCMD_ACK_M)||(l2tol1_snack==`SC_SCMD_ACK_S)) begin
for(way_no=0;way_no<=7;way_no++) begin
       way_no_ext={{5{1'b0}},way_no};
       req_pos_in_tag = (req_pos+way_no_ext);
      if (ack_data_to_1_tagcheck[9:0]== req_tag_search)  begin //data comming from ram : ack_data_to_1_tagcheck
         way=way_no;
         if(state_line==`I)  begin//what happens if cacheline  in I state?
         req_data_1_tagbank=req_tag;
         write_1_tagcheck=1;//write enable to ram the req data in this tag way
	 end
	end//]== req_tag_search

       NO_TAG_PRESENT=1;

  end //for 
 end
 end
 end*/
//if(state_line!=I) //no cache tag present

/*
always_comb begin 
if (l2tol1_snack_valid && NO_TAG_PRESENT) begin 
  if((l2tol1_snack==`SC_SCMD_ACK_S)||(l2tol1_snack==`SC_SCMD_ACK_M)||(l2tol1_snack==`SC_SCMD_ACK_S))begin
  for(way_no=0;way_no<=7;way_no++) begin
     way_no_ext={{5{1'b0}},way_no};
     req_pos_in_tag = (req_pos+way_no_ext);
      if(ack_data_to_1_tagcheck[11:10]==3)begin
         req_data_1_tagbank=req_tag;
         write_1_tagcheck=1;//write enable to ram the req data in this tag way
	 end
      else begin 
   counter_RRIP=counter+1;
   //req_data_1_tagbank[=ack_data_to_1_tagcheck;// increase the RRIP counters
   req_data_1_tagbank[11:10]=counter_RRIP;
   write_1_tagcheck=1;
   end
end//for
end //if (l2tol1_snack==`SC_SCMD_ACK_S)
end//if  valid
end//always_comb
//end//sel 
*/
endmodule

