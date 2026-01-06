`timescale 1us/1us
`include "cpu_defs.vh"

module RegisterFile (
    input wire clock,
    input wire reset,
    input wire reg_write,
    input wire [4:0] read_addr1,
    input wire [4:0] read_addr2,
    input wire [4:0] write_addr,
    input wire [31:0] write_data,
    input wire [31:0] debug_pc,
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
        end else if (reg_write) begin
            if (write_addr != 5'd0) begin
                registers[write_addr] <= write_data;
            end
            $display("@%h: $%0d <= %h", debug_pc, write_addr, write_data);
            // Additional focused debug for key registers to ease grep
            if (write_addr == 5'd1 || write_addr == 5'd17 || write_addr == 5'd23 || write_addr == 5'd31) begin
                $display("[REG_WR] time=%0t pc=%h write_reg=$%0d write_val=%h", $time, debug_pc, write_addr, write_data);
            end
        end
    end

    assign read_data1 = (read_addr1 == 5'd0) ? 32'b0 : 
                        ((read_addr1 == write_addr) && reg_write) ? write_data :
                        registers[read_addr1];
    assign read_data2 = (read_addr2 == 5'd0) ? 32'b0 : 
                        ((read_addr2 == write_addr) && reg_write) ? write_data :
                        registers[read_addr2];
endmodule
