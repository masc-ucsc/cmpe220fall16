`include "scmemc.vh"

module DC_top_tag_index_even_odd  #(parameter Width = 24, Size =512, Forward=0, REQ_BITS=7)
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
//,input                            tag_sel
 ,input [Width-1:0]                req_value
// 
              //Search Only for 18 bit tags
//Tomorrow should work for states and the tag value and the counter as well tomorrow

 ,output                           ack_valid
 ,output                           req_retry
 ,output [2:0]                     ack_req
 //,output [Width-1:0]               ack_data
 ,output			   miss
 ,output			   hit
 ,output[2:0]			   way	
 ,output [REQ_BITS-1:0]		   ack_req_type
 //,output			   	   read_cnt
 //,output			   	   write_cnt


);
DC_2_tagbanks
  #(.Width(Width), .Size(Size))
 tag_even (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_type   (req_type)
  ,.write      (write)//we=0 for read
  //,.tag_sel      (tag_sel_0a)
 ,.ack_retry   (ack_retry)
 ,.req_data	(req_data)

 ,.tag_sel (tag_sel_even)
 ,.req_value	(req_value)//search for Tag only while reading 
  ,.ack_valid   (ack_valid)
 ,.ack_req (ack_req)
 ,.req_retry   (req_retry)
  ,.miss    (miss_a)
  ,.hit    (hit_a)
 ,.way    (way_a)
 ,.ack_req_type(ack_req_type)
); 

DC_2_tagbanks
  #(.Width(Width), .Size(Size))
 tag_odd (
   .clk      	(clk)
  ,.reset   	(reset)
  ,.req_valid	(req_valid)
  ,.req_type   (req_type)
  ,.write      (write)//we=0 for read
  //,.tag_sel      (tag_sel_0a)
  ,.ack_retry   (ack_retry)
  ,.req_data	(req_data)
 ,.tag_sel (tag_sel_odd)
 ,.req_value	(req_value)
 ,.ack_req (ack_req)
//search for Tag only while reading 
  ,.ack_valid   (ack_valid)
 ,.req_retry   (req_retry)
  ,.miss    (miss_a)
  ,.hit    (hit_a)
 ,.way    (way_a)
,.ack_req_type(ack_req_type)
);


logic[4:0] index_sel_even,index_sel_odd; //last bit of index tells ifindex is odd/even
assign index_last_bit=req_data[10];

always@(index_last_bit) begin
if(index_last_bit==0) begin index_sel_even=1;index_sel_odd=0; end
else begin index_sel_even=0;index_sel_odd=1; end
end



endmodule

