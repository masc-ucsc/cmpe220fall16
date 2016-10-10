`include "logfunc.h"

// FAST 2 port SRAM: 
//
// Fast means 1 cycle read/write
//
// Max total bits is 1Kbytes (Size*Width)
//
// Size must be between 8 and 64
// (anything smaller is not worth it in SRAM, but OK)
//
module ram_2port_fast #(parameter Width = 64, Size=128, Forward=0) (
  input                            clk
 ,input                            reset

 ,input                            req_wr_valid
 ,output                           req_wr_retry
 ,input [`log2(Size)-1:0]          req_wr_addr
 ,input [Width-1:0]                req_wr_data

 ,input                            req_rd_valid
 ,output                           req_rd_retry
 ,input [`log2(Size)-1:0]          req_rd_addr

 ,output                           ack_rd_valid
 ,input                            ack_rd_retry
 ,output [Width-1:0]               ack_rd_data
 );

 logic [Width-1:0]                 ack_rd_data_next;

 async_ram_2port 
  #(.Width(Width), .Size(Size))
 ram (
  // 1st port: write
   .p0_pos      (req_wr_pos)
  ,.p0_enable   (req_wr_valid)
  ,.p0_in_data  (req_wr_data)
  ,.p0_out_data (ack_wr_data_next)
  // 2nd port: Read
  ,.p1_pos      (req_rd_addr)
  ,.p1_enable   (1'b0) // Never WR
  ,.p1_in_data  ('b0)
  ,.p1_out_data (ack_rd_data_next)
  );

  logic req_retry_next;
  always_comb begin
    // If it is a write, the retry has no effect. We can write one per cycle
    // (token consumed)
    req_retry = req_retry_next & !req_we;
  end

  fflop #(.Size(Width)) f1 (
    .clk      (clk),
    .reset    (reset),

    .din      (ack_rd_data_next),
    .dinValid (req_rd_valid),
    .dinRetry (ack_rd_retry),

    .q        (ack_rd_data),
    .qValid   (ack_rd_valid),
    .qRetry   (ack_rd_retry)
  );

endmodule

