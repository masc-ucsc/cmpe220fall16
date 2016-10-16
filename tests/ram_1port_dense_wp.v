
`include "logfunc.h"

module ram_1port_dense_wp (
  input                            clk
 ,input                            reset

 ,input                            req_valid
 ,output                           req_retry
 ,input                            req_we
 ,input [8-1:0]                    req_addr
 ,input [16-1:0]                   req_data

 ,output                           ack_valid
 ,input                            ack_retry
 ,output [16-1:0]                  ack_data
 );

 ram_1port_dense 
  #(.Width(16), .Size(256), .Forward(1))
 ram (
   .clk         (clk)
  ,.reset       (reset)

  ,.req_valid   (req_valid)
  ,.req_retry   (req_retry)
  ,.req_we      (req_we)
  ,.req_pos     (req_addr)
  ,.req_data    (req_data)

  ,.ack_valid   (ack_valid)
  ,.ack_retry   (ack_retry)
  ,.ack_data    (ack_data)
  );

endmodule

