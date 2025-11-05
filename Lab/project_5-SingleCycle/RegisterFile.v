`timescale 1ns/1ps
`include "cpu_defs.vh"

module RegisterFile (
    input wire clock,
    input wire reset,
    input wire reg_write,
    input wire [4:0] read_addr1,
    input wire [4:0] read_addr2,
    input wire [4:0] write_addr,
    input wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] registers [0:31];
    integer i;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write && (write_addr != 5'd0)) begin
            registers[write_addr] <= write_data;
        end
    end

    assign read_data1 = (read_addr1 == 5'd0) ? 32'b0 : registers[read_addr1];
    assign read_data2 = (read_addr2 == 5'd0) ? 32'b0 : registers[read_addr2];
endmodule
