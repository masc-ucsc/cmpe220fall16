
module DC_4_databanks #(parameter Width = 24, Size =512, Forward=0, REQ_BITS=7)
//tag 18+counter 2[19,20]+states 3[21,22,23] =15
(   
  input                            clk
 ,input                            reset
 ,input                            req_valid
 ,input [REQ_BITS-1:0]		   req_type	
 ,input                            write
,input[6:0]			   req_type
,input [2:0]                       bank_sel
 ,input                            ack_retry
,input 	[2:0]			   way
 ,input [38:0]                     req_logical_addr//Search Only for 18 bit tags
,input [35:0]                      req_data
//,input [35:0]                     req_
 ,output                           ack_valid
 ,output                           req_retry
 ,output [63:0]                    ack_data //64 bit data output for sign extension

 //,output			   miss
 //,output			   hit



);

always@(req_logical_addr[4:3]) 
begin
assign bank_sel=req_addr[4:3];//2 bit select for 4 banks in a level
end 

logic [1:0] row_even_odd =req_logical_addr[6:5];

always@(bank_sel) begin

case(bank_sel) 

 0: bank_sel0=1;
 1:bank_sel1=1;
 2:bank_sel2=1;
 3:bank_sel3=1;
 


endcase
end

DC_1_databank #(.Width(Width), .Size(Size))
  databank0 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write)//we=0 for read
  ,.req_type     (req_type)
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_addr	 (req_logical_addr)//search for Tag only while reading 
  ,.req_data     (req_data)//data+4 bit valid
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel0)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );
DC_1_databank #(.Width(Width), .Size(Size))
  databank1 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write)//we=0 for read
  ,.req_type     (req_type)
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_addr	 (req_logical_addr)//search for Tag only while reading 
  ,.req_data     (req_data)//data+4 bit valid
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel1)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );
DC_1_databank #(.Width(Width), .Size(Size))
  databank2 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write)//we=0 for read
  ,.req_type     (req_type)
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_addr	 (req_logical_addr)//search for Tag only while reading 
  ,.req_data     (req_data)//data+4 bit valid
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel2)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );
DC_1_databank #(.Width(Width), .Size(Size))
  databank3 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write)//we=0 for read
  ,.req_type     (req_type)
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_addr	 (req_logical_addr)//search for Tag only while reading 
  ,.req_data     (req_data)//data+4 bit valid
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel3)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );





endmodule
