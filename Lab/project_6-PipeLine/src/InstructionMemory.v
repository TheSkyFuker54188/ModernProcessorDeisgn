`timescale 1ns/1ps
`include "cpu_defs.vh"

module InstructionMemory #(
    parameter MEM_DEPTH = 1024,
    parameter INIT_FILE = "",
    parameter BASE_ADDR = 32'h00003000
) (
    input wire [31:0] address,
    output reg [31:0] instruction
);
    reg [31:0] memory [0:MEM_DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            memory[i] = 32'b0;
        end
        if (INIT_FILE != "") begin
            $display("Loading instruction memory from %s", INIT_FILE);
            $readmemh(INIT_FILE, memory);
        end
    end

    wire [31:0] addr_offset = address - BASE_ADDR;
    wire within_range = (address >= BASE_ADDR) && (addr_offset[31:12] == 20'b0);

    always @(*) begin
        if (within_range) begin
            instruction = memory[addr_offset[11:2]];
        end else begin
            instruction = 32'b0;
        end
    end
endmodule
