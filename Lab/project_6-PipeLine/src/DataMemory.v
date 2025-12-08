`timescale 1ns/1ps
`include "cpu_defs.vh"

module DataMemory #(
    parameter MEM_DEPTH = 1024
) (
    input wire clock,
    input wire reset,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [31:0] debug_pc,
    output reg [31:0] read_data
);
    reg [31:0] memory [0:MEM_DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            memory[i] = 32'b0;
        end
    end

    always @(*) begin
        if (mem_read) begin
            if ((address[1:0] == 2'b00) && (address[31:12] == 20'b0)) begin
                read_data = memory[address[11:2]];
            end else begin
                read_data = 32'b0;
            end
        end else begin
            read_data = 32'b0;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                memory[i] <= 32'b0;
            end
        end else if (mem_write) begin
            if ((address[1:0] == 2'b00) && (address[31:12] == 20'b0)) begin
                memory[address[11:2]] <= write_data;
                $display("@%h: *%h <= %h", debug_pc, address, write_data);
            end
        end
    end
endmodule
