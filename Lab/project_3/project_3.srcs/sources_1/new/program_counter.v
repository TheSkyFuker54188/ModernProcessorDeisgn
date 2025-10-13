`timescale 1ns / 1ps

// Program counter with synchronous reset and jump support
module program_counter (
    input  wire        reset,
    input  wire        clock,
    input  wire        jumpEnabled,
    input  wire [31:0] jumpInput,
    output reg  [31:0] pcValue
);
    localparam [31:0] RESET_VECTOR = 32'h0000_3000;

    always @(posedge clock) begin
        if (reset) begin
            pcValue <= RESET_VECTOR;
        end else if (jumpEnabled) begin
            pcValue <= jumpInput;
        end else begin
            pcValue <= pcValue + 32'd4;
        end
    end
endmodule
