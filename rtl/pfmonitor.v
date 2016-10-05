
// Collects data from pfl1monitor and pfl2monitor and generated prefeches
// accordingly
//

module pfmonitor(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  ,input SC_robid_type             rrid // Retire ROBid

`ifdef NOT_CLEAN_ENOUGH
  ,input SC_core_decode_type       cdec // Decode
  ,input SC_core_exec_type         agen0 // address gen
  ,input SC_core_exec_type         agen1 // address gen
`endif
  /* verilator lint_on UNUSED */
);

endmodule

