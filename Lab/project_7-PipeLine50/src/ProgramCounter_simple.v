`timescale 1us/1us
module ProgramCounter (
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [31:0] next_pc,
    output reg [31:0] current_pc
);
    parameter RESET_PC = 32'h00003000;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_pc <= RESET_PC;
        end else if (enable) begin
            current_pc <= next_pc;
        end
    end
endmodule
