`include "DC_define.v"
`include "logfunc.h"
`include "scmemc.vh"

module DC_top_bank_tag 
//#(parameter Width=36, Size =256, Forward=0, REQ_BITS=7)
//tag 10+counter 2+states 3 =15//29 bits virtual adress
(   
 input                            	clk
 ,input                            	reset
 ,input                            	req_valid
 ,input                            	write
 ,input                           	ack_retry
 ,input [35:0]                    	req_data
 ,input [14:0]                           req_tag
 ,input[4:0]			   	index
 ,input[2:0]				bank_sel
 ,input                                row_even_odd
 ,output                                 ack_valid
 ,output                                req_retry_from_top
 ,output [35:0]                         ack_data_from_top
 //****************************************,output [2:0]                     ack_req_to_L2 //3 bit ack req to L2
 ,output			               miss
 ,output			                hit
 ,output[2:0]			        way
 ,output [14:0]                       output_data_tag
 ,output                               tag_retry	
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

logic [2:0]  way_no, way_from_tag;
logic hit_tag, miss_tag,ack_valid;
logic  write_musk_reset,req_retry_to_1_tagcheck,req_retry;
logic [35:0] ack_data;
logic [14:0] ack_data_to_1_tagcheck;


DC_1_tagcheck 
#(.Width(15), .Size(256))
 tagcheck0 (
 .clk      	(clk)
 ,.reset   	(reset)
 ,.req_valid	(req_valid)
 ,.write      (write)//we=0 for read
 ,.ack_retry   (ack_retry)
 ,.req_tag	(req_tag)
 ,.index        (index)
 ,.ack_valid   (ack_valid)
 ,. req_retry_to_1_tagcheck (req_retry_to_1_tagcheck)
 ,.ack_data_to_1_tagcheck( ack_data_to_1_tagcheck)
 ,.miss( miss_tag)			              
 ,.hit(hit_tag)
 ,.way (way_from_tag)
 ,.coretodc_ld_valid  (coretodc_ld_valid)
 ,.coretodc_ld_retry  (coretodc_ld_retry)
 ,.coretodc_ld_req  (coretodc_ld_req)
 ,.coretodc_std_valid  (coretodc_std_valid)
 ,.coretodc_std_retry  (coretodc_std_retry)
 ,.coretodc_std    (coretodc_std)
 ,.l1tol2_req_valid(l1tol2_req_valid)
 ,.l1tol2_req_retry(l1tol2_req_retry)
 ,.l1tol2_req(l1tol2_req)
 ,.l2tol1_snack_valid  (l2tol1_snack_valid)
 ,.l2tol1_snack  (l2tol1_snack)
 ,.l1tol2_disp_valid   (l1tol2_disp_valid)
 ,.l1tol2_disp (l1tol2_disp)

);


 DC_8_databanks #(.Width(36),.Size(512))
databanks_8
(   
  .clk(clk)
 ,.reset(reset)
 ,.req_valid(req_valid)
 ,.write(write)
 ,.bank_sel(bank_sel)
 ,.ack_retry(ack_retry)
 ,.way(way_no)
 ,.row_even_odd(row_even_odd)
 ,.req_Index(index)
 ,.req_data(req_data)//32 bit data+4 bit valid bit
 ,.Load_req(coretodc_ld_req)
 ,.Load_req_valid(coretodc_ld_valid)
 ,.Load_req_retry(coretodc_ld_retry)
 ,.STD_req(coretodc_std)
 ,.STD_req_valid(coretodc_std_valid)
 ,.STD_req_retry(coretodc_std_retry)
 ,.write_musk_reset(write_musk_reset) //when Invalidate
 ,.ack_valid(ack_valid)
 ,.req_retry(req_retry)
 ,.ack_data(ack_data) //36 bit
);


always_comb begin
   if(hit_tag) begin
 way_no=way_from_tag;
 hit=hit_tag;
 way=way_no;
 ack_data_from_top=ack_data;
 req_retry_from_top=req_retry;
 output_data_tag=ack_data_to_1_tagcheck;
 end
end


always_comb begin
 if(miss_tag) begin
 miss=miss_tag;
 end 
end

always_comb begin
  if(reset) begin
write_musk_reset=0;
  end
end


always_comb begin
 tag_retry=req_retry_to_1_tagcheck;
end
endmodule

