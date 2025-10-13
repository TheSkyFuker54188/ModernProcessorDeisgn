`timescale 1ns / 1ps

// 4 KiB word-addressed data memory with synchronous write
module data_memory (
    input  wire        reset,
    input  wire        clock,
    input  wire [31:0] address,
    input  wire        writeEnabled,
    input  wire [31:0] writeInput,
    output wire [31:0] readResult
);
    reg [31:0] mem [0:1023];

    integer i;
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < 1024; i = i + 1) begin
                mem[i] <= 32'd0;
            end
            $display("[%0t] Reset asserted, clearing memory", $time);
        end else if (writeEnabled) begin
            mem[address[11:2]] <= writeInput;
            $display("[%0t] Write @ %h = %h", $time, address, writeInput);
        end
    end

    assign readResult = mem[address[11:2]];
endmodule
