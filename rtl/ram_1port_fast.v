
`include "logfunc.h"

// FAST 1 port SRAM: 
//
// Fast means 1 cycle read/write
//
// Max total bits is 2Kbytes (Size*Width)
//
// Size must be between 16 and 256
// (anything smaller is not worth it in SRAM, but OK)

module ram_1port_fast #(parameter Width = 64, Size=128, Forward=0)( 
  input                            clk
 ,input                            reset

 ,input                            req_valid
 ,output                           req_retry
 ,input                            req_we
 ,input [`log2(Size)-1:0]          req_pos
 ,input [Width-1:0]                req_data

 ,output                           ack_valid
 ,input                            ack_retry
 ,output [Width-1:0]               ack_data
 );

 logic [Width-1:0]                 ack_data_next;

 async_ram_1port 
  #(.Width(Width), .Size(Size))
 ram (
   .p0_pos      (req_pos)
  ,.p0_enable   (req_valid & req_we)
  ,.p0_in_data  (req_data)
  ,.p0_out_data (ack_data_next)
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

    .din      (ack_data_next),
    .dinValid (req_valid & ~req_we),
    .dinRetry (req_retry_next),

    .q        (ack_data),
    .qValid   (ack_valid),
    .qRetry   (ack_retry)
  );

endmodule

