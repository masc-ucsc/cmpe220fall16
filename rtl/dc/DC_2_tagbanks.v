
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
,input [Width-1:0]                req_tag
,input                      tag_sel
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

if(tag_sel==1) begin //tagbank enable

logic miss_total,miss_a,miss_b, hit_total,hit_a,hit_b,way_total,way_a,way_b,req_retry,req_retry_a,req_retry_b,ack_valid,ack_valid_a, ack_valid_b;;

DC_tagcheck
  #(.Width(Width), .Size(Size))
 tag_a (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_type   (req_type)
  ,.write      (write)//we=0 for read
  //,.tag_sel      (tag_sel_0a)
 ,.req_data	(req_tag)//search for Tag only while reading 
  ,.ack_retry   (ack_retry)
 ,.req_retry   (req_retry)
  ,.ack_valid   (ack_valid)
  ,.hit    (hit_a)
 ,.way    (way_a)
 ,.miss    (miss_a)
  );


DC_tagcheck
  #(.Width(Width), .Size(Size))
 tag_b (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_type   (req_type)
  ,.write      (write)//we=0 for read
 // ,.tag_sel      (tag_sel_0b)
  ,.req_data	(req_tag)//search for Tag only while reading 
  ,.ack_retry   (ack_retry)
 ,.req_retry   (req_retry)
  ,.ack_valid   (ack_valid)
  ,.hit    (hit_b)
 ,.way    (way_a)
 ,.miss    (miss_b)
  );

always@(req_tag)
begin assign hit=hit_a + hit_b;//any hit=1 is total hit
assign miss=hit_a + hit_b;
assign hit=miss_a + miss_b;
assign req_retry=req_retry_a + req_retry_b;
 assign ack_valid=_ack_valid_a + ack_valid_b;
assign way=way_a+way_b;
end


end//tag_sel
endmodule








 

