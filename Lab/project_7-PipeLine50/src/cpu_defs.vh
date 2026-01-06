`timescale 1us/1us

`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// ALU operation encodings
`define ALU_CTRL_ADD  4'b0000
`define ALU_CTRL_SUB  4'b0001
`define ALU_CTRL_OR   4'b0010
`define ALU_CTRL_AND  4'b0011
`define ALU_CTRL_PASS 4'b0100
`define ALU_CTRL_XOR  4'b0101
`define ALU_CTRL_NOR  4'b0110
`define ALU_CTRL_SLT  4'b0111
`define ALU_CTRL_SLTU 4'b1000
`define ALU_CTRL_SLL  4'b1001
`define ALU_CTRL_SRA  4'b1010
`define ALU_CTRL_SLLV 4'b1011
`define ALU_CTRL_SRAV 4'b1100
`define ALU_CTRL_LUI  4'b1101

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

// Branch operations
`define BRANCH_NONE 3'd0
`define BRANCH_BEQ  3'd1
`define BRANCH_BNE  3'd2
`define BRANCH_BLEZ 3'd3
`define BRANCH_BGTZ 3'd4
`define BRANCH_BLTZ 3'd5
`define BRANCH_BGEZ 3'd6

// MDU operations
`define MDU_READ_HI            3'd0
`define MDU_READ_LO            3'd1
`define MDU_WRITE_HI           3'd2
`define MDU_WRITE_LO           3'd3
`define MDU_START_SIGNED_MUL   3'd4
`define MDU_START_UNSIGNED_MUL 3'd5
`define MDU_START_SIGNED_DIV   3'd6
`define MDU_START_UNSIGNED_DIV 3'd7

`endif
