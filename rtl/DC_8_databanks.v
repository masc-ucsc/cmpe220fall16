
module DC_8_databanks #(parameter Width = 36, Size =512, Forward=0, REQ_BITS=7)
// 36 bit data per data bank= 32 bit data+4 bit valid bits
//tag 10+counter 2[19,20]+states 3[21,22,23] =15 for tag bank
//data bank gets pos+ data to write or output data from read
(   
input                            clk
,input                            reset
,input                            req_valid
,input                            write
,input [2:0]                       bank_sel
,input                            ack_retry
,input 	[2:0]			   way
,input [21:0]                     req_addr//22 bit address:Search Only for 10 bit tags+5 bit index+1 bit slice L1( not pipe)
,input [35:0]                      req_data //32 bit data+4 bit valid bit
,input [4:0] 			   Load_req
,input 			           Load_req_valid
,output				   Load_req_retry
,input [6:0] 			   STD_req
,input 			           STD_req_valid
,output				   STD_req_retry
,input 				   write_musk_reset //when Invalidate
,output                           ack_valid
,output                           req_retry
,output [35:0]                    ack_data //64 bit data output for sign extension

);

logic  [4:0] req_Index_add_to_1_bank;
logic  [35:0] req_data_bank=req_data;
assign  req_Index_add_to_1_bank= req_addr[11:7];//index 5 bits
logic bank_sel0,write_bank;
logic bank_sel1,bank_sel2,bank_sel3,bank_sel4,bank_sel5,bank_sel6,bank_sel7;
logic [2:0] bank_sel_8bank;
assign bank_sel_8bank=bank_sel;
assign write_bank=write;
always@(req_addr) begin
bank_sel_8bank=req_addr[4:2];//3 bit select for 8 banks in a bank;VA[1:0] byte selection 
end 

logic row_even_odd =req_Index_add_to_1_bank[4];

always@(bank_sel_8bank) begin

case(bank_sel_8bank) 

 0: begin bank_sel0=1;bank_sel1=0;;bank_sel2=0;bank_sel3=0;bank_sel4=0;bank_sel5=0;bank_sel6=0;bank_sel7=0;end
 1: begin bank_sel0=0;bank_sel1=1;bank_sel2=0;bank_sel3=0;bank_sel4=0;bank_sel5=0;bank_sel6=0;bank_sel7=0;end
 2: begin bank_sel0=0;bank_sel1=0;bank_sel2=1;bank_sel3=0;bank_sel4=0;bank_sel5=0;bank_sel6=0;bank_sel7=0;end
 3: begin bank_sel0=0;bank_sel1=0;bank_sel2=0;bank_sel3=1;bank_sel4=0;bank_sel5=0;bank_sel6=0;bank_sel7=0;end
 4: begin bank_sel0=0;bank_sel1=0;bank_sel2=0;bank_sel3=0;bank_sel4=1;bank_sel5=0;bank_sel6=0;bank_sel7=0;end
 5: begin bank_sel0=0;bank_sel1=0;bank_sel2=0;bank_sel3=0;bank_sel4=0;bank_sel5=1;bank_sel6=0;bank_sel7=0;end
 6: begin bank_sel0=0;bank_sel1=0;bank_sel2=0;bank_sel3=0;bank_sel4=0;bank_sel5=0;bank_sel6=1;bank_sel7=0;end
 7:begin bank_sel0=0;bank_sel1=0;bank_sel2=0;bank_sel3=0;bank_sel4=0;bank_sel5=0;bank_sel6=0;bank_sel7=1;end
endcase
end

DC_1_databank #(.Width(Width), .Size(Size))
  databank0 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
  ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
  ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
  ,.write_musk_reset(write_musk_reset)
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
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
  ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
  ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
  ,.write_musk_reset(write_musk_reset)
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
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
 ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
  ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
 ,.write_musk_reset(write_musk_reset)
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
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
  ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
   ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
  ,.write_musk_reset(write_musk_reset)
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel3)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );
DC_1_databank #(.Width(Width), .Size(Size))
  databank4 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
  ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
  ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
 ,.write_musk_reset(write_musk_reset)
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel4)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );

DC_1_databank #(.Width(Width), .Size(Size))
  databank5(
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
  ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
  ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
  ,.write_musk_reset(write_musk_reset)
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel5)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );

DC_1_databank #(.Width(Width), .Size(Size))
  databank6 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
  ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
  ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
  ,.write_musk_reset(write_musk_reset)
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel6)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );DC_1_databank #(.Width(Width), .Size(Size))
  databank7 (
   .clk      	 (clk)
  ,.reset   	 (reset)
  ,.req_valid	 (req_valid)
  ,.req_retry    (req_retry)
  ,.write        (write_bank)//we=0 for read
  ,.way_no       (way)
  ,.row_even_odd (row_even_odd) 
  ,.req_Index	 (req_Index_add_to_1_bank)//search for Tag only while reading 
  ,.req_data     (req_data_bank)//data+4 bit valid
  ,.Load_req (Load_req)
  ,.Load_req_valid(Load_req_valid)
  ,.Load_req_retry(Load_req_retry)
  ,.STD_req(STD_req)
  ,.STD_req_valid(STD_req_valid)
  ,.STD_req_retry(STD_req_retry)
  ,.write_musk_reset(write_musk_reset)
  ,.ack_valid    (ack_valid)
  ,.bank_sel    (bank_sel7)//bank0 is the signal connected to enable bank0
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );
endmodule
