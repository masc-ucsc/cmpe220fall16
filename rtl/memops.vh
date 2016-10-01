
// RISCV friendly memory opcodes for LDs, ST address, and ST data

`define RVMOP_BITS  3

// load
`define RVMOP_LB    3'b000
`define RVMOP_LH    3'b001
`define RVMOP_LW    3'b010
`define RVMOP_LBU   3'b100
`define RVMOP_LHU   3'b101
`define RVMOP_LWU   3'b110
`define RVMOP_LD    3'b011

// store address
`define RVMOP_SAB   3'b000
`define RVMOP_SAH   3'b001
`define RVMOP_SAW   3'b010
`define RVMOP_SAD   3'b011

// store data (address also provided)
`define RVMOP_SDB   3'b100
`define RVMOP_SDH   3'b101
`define RVMOP_SDW   3'b110
`define RVMOP_SDD   3'b111

// L2 commands to L1
`define L2_CMDBITS 2
`define L2_CMD_DATA_E  2'b00   // Data comming with exclusive state granted
`define L2_CMD_DATA_S  2'b01   // Data comming with shared state granted
`define L2_CMD_SNOOP_E 2'b10   // L2 request to get line in exlusive state (trigger uncoherent state if speculative)
`define L2_CMD_SNOOP_S 2'b11   // L2 request to get line in shared state (trigger uncoherenet state if speculative)


