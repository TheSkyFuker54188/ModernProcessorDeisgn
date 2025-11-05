`timescale 1ns/1ps
`include "cpu_defs.vh"

module InstructionMemory #(
    parameter MEM_DEPTH = 1024,
    parameter INIT_FILE = ""
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

    always @(*) begin
        instruction = memory[address[11:2]];
    end
endmodule
