`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// ALU operation encodings
`define ALU_CTRL_ADD  4'b0000
`define ALU_CTRL_SUB  4'b0001
`define ALU_CTRL_OR   4'b0010
`define ALU_CTRL_AND  4'b0011
`define ALU_CTRL_PASS 4'b0100

// Register numbers
`define REG_RA        5'd31

// Destination register mux select
`define REG_DST_RT    2'b00
`define REG_DST_RD    2'b01
`define REG_DST_RA    2'b10

// Write-back data mux select
`define WRITE_SRC_ALU 2'b00
`define WRITE_SRC_MEM 2'b01
`define WRITE_SRC_PC8 2'b10
`define WRITE_SRC_LUI 2'b11

`endif
