
module top_2core2dr(
   input                           clk
  ,input                           reset

  ,input  logic                    pfgtopfe_op_valid
  ,output logic                    pfgtopfe_op_retry
  ,input  I_pfgtopfe_op_type       pfgtopfe_op

  ,output                          drtomem_req_valid
  ,input                           drtomem_req_retry
  ,output I_drtomem_req_type       drtomem_req

  ,input                           memtodr_ack_valid
  ,output                          memtodr_ack_retry
  ,input  I_memtodr_ack_type       memtodr_ack

  ,output                          drtomem_wb_valid
  ,input                           drtomem_wb_retry
  ,output I_drtomem_wb_type        drtomem_wb // Plain WB, no disp ack needed

  ,output logic                    drtomem_pfreq_valid
  ,input  logic                    drtomem_pfreq_retry
  ,output I_drtomem_pfreq_type     drtomem_pfreq

  // core interface LD
  ,input                           coretodc_ld_valid
  ,output                          coretodc_ld_retry
  ,input  I_coretodc_ld_type       coretodc_ld

  ,output                          dctocore_ld_valid
  ,input                           dctocore_ld_retry
  ,output I_coretodc_ld_type       dctocore_ld

  // core interface STD
  ,input                           coretodc_std_valid
  ,output                          coretodc_std_retry
  ,input  I_coretodc_std_type      coretodc_std

  ,output                          dctocore_std_ack_valid
  ,input                           dctocore_std_ack_retry
  ,output I_dctocore_std_ack_type  dctocore_std_ack

  // core Prefetch interface
  // 4 or 16 instruction fetch (4 or 8 way core)
  // core interface
  ,input                           coretoic_valid
  ,output                          coretoic_retry
  ,input  SC_laddr_type            coretoic_pc // Bit 0 is always zero

  ,output                          ictocore_valid
  ,input                           ictocore_retry
  ,output I_ictocore_type          ictocore
);

 // net_2core2dr
 // L1, L2, DR
 //
 // In/out: L1 interface, pfengine, directory_memory requests

endmodule

