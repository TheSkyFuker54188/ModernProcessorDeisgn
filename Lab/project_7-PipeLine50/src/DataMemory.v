`timescale 1ns/1ps
`include "cpu_defs.vh"

module DataMemory #(
    parameter MEM_DEPTH = 1024
) (
    input wire clock,
    input wire reset,
    input wire mem_read,
    input wire mem_write,
    input wire [2:0] size,
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [31:0] debug_pc,
    output reg [31:0] read_data
);
    reg [31:0] memory [0:MEM_DEPTH-1];
    integer i;

    // Helper for byte/half extraction
    wire [31:0] word_data = memory[address[11:2]];
    wire [1:0] offset = address[1:0];

    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            memory[i] = 32'b0;
        end
    end

    always @(*) begin
        read_data = 32'b0;
        if (mem_read) begin
            // Assuming address is within range
            case (size)
                3'd0: read_data = word_data; // LW
                3'd1: begin // LB
                    case (offset)
                        2'b00: read_data = {{24{word_data[7]}}, word_data[7:0]};
                        2'b01: read_data = {{24{word_data[15]}}, word_data[15:8]};
                        2'b10: read_data = {{24{word_data[23]}}, word_data[23:16]};
                        2'b11: read_data = {{24{word_data[31]}}, word_data[31:24]};
                    endcase
                end
                3'd2: begin // LH
                    case (offset[1])
                        1'b0: read_data = {{16{word_data[15]}}, word_data[15:0]};
                        1'b1: read_data = {{16{word_data[31]}}, word_data[31:16]};
                    endcase
                end
                3'd3: begin // LBU
                    case (offset)
                        2'b00: read_data = {24'b0, word_data[7:0]};
                        2'b01: read_data = {24'b0, word_data[15:8]};
                        2'b10: read_data = {24'b0, word_data[23:16]};
                        2'b11: read_data = {24'b0, word_data[31:24]};
                    endcase
                end
                3'd4: begin // LHU
                    case (offset[1])
                        1'b0: read_data = {16'b0, word_data[15:0]};
                        1'b1: read_data = {16'b0, word_data[31:16]};
                    endcase
                end
            endcase
        end
    end

    reg [31:0] new_word;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                memory[i] <= 32'b0;
            end
        end else if (mem_write) begin
            new_word = memory[address[11:2]]; // Current value
            case (size)
                3'd0: new_word = write_data;
                3'd1: begin
                    case (offset)
                        2'b00: new_word[7:0] = write_data[7:0];
                        2'b01: new_word[15:8] = write_data[7:0];
                        2'b10: new_word[23:16] = write_data[7:0];
                        2'b11: new_word[31:24] = write_data[7:0];
                    endcase
                end
                3'd2: begin
                    case (offset[1])
                        1'b0: new_word[15:0] = write_data[15:0];
                        1'b1: new_word[31:16] = write_data[15:0];
                    endcase
                end
            endcase
            memory[address[11:2]] <= new_word;
            $display("@%h: *%h <= %h", debug_pc, {address[31:2], 2'b00}, new_word);
        end
    end
endmodule
