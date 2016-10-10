
`include "logfunc.h"

// dense 1 port SRAM: 
//
// dense means 2 cycle read/write
//
// Max total bits is 32Kbytes (Size*Width)
//
// Size must be between 32 and 1024

module ram_1port_dense #(parameter Width = 64, Size=128, Forward=0)( 
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

  logic last_busy;
  logic req_retry_next;
  always_comb begin
    // If it is a write, the retry has no effect. We can write one per cycle
    // (token consumed)
    req_retry = (req_retry_next & !req_we) | last_busy;
  end
  logic [Width-1:0]                 ack_n1_data;
  logic                             ack_n1_valid;
  logic                             ack_n1_retry;

  always @(posedge clk) begin
    if (reset) begin
      last_busy <= 0;
    end else begin
      if (last_busy) begin
        last_busy <= 0;
      end else begin
        last_busy <= req_valid;
      end
    end
  end

  fflop #(.Size(Width)) f1 (
    .clk      (clk),
    .reset    (reset),

    .din      (ack_data_next),
    .dinValid ((req_valid & ~req_we) & ~last_busy),
    .dinRetry (req_retry_next),

    .q        (ack_n1_data),
    .qValid   (ack_n1_valid),
    .qRetry   (ack_n1_retry)
  );

  fflop #(.Size(Width)) f2 (
    .clk      (clk),
    .reset    (reset),

    .din      (ack_n1_data),
    .dinValid (ack_n1_valid),
    .dinRetry (ack_n1_retry),

    .q        (ack_data),
    .qValid   (ack_valid),
    .qRetry   (ack_retry)
  );

endmodule

