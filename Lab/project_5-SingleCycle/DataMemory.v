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
    output reg [31:0] read_data
);
    reg [31:0] memory [0:MEM_DEPTH-1];
    // 调试打印控制：仅低地址且限条数，避免输出过长（提交默认关闭，仅在定义 SIM_DEBUG 时有效）
    localparam integer DEBUG_DM_LOW_MAX_WORD = 5;  // 仅关注 DM[0..4]
    localparam integer DEBUG_DM_PRINT_MAX    = 12; // 最多打印条数
    integer dbg_dm_prints;
    integer i;

    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            memory[i] = 32'b0;
        end
    end

    always @(*) begin
        if (mem_read) begin
            // 仅允许对齐且在 0x0000_0000..0x0000_0FFF 范围内的读
            if ((address[1:0] == 2'b00) && (address[31:12] == 20'b0)) begin
                read_data = memory[address[11:2]];
            end else begin
                read_data = 32'b0; // 越界或未对齐，返回 0（仿真策略）
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
            dbg_dm_prints <= 0;
        end else if (mem_write) begin
            // 仅允许对齐且在 0x0000_0000..0x0000_0FFF 范围内的写
            if ((address[1:0] == 2'b00) && (address[31:12] == 20'b0)) begin
                memory[address[11:2]] <= write_data;
                // 调试：仅打印低地址的写入，且限条数
                `ifdef SIM_DEBUG
                if ((address[11:2] < DEBUG_DM_LOW_MAX_WORD) && (dbg_dm_prints < DEBUG_DM_PRINT_MAX)) begin
                    $display("[DM-WRITE] addr=%0d (0x%08h), data=0x%08h", address[11:2], address, write_data);
                    dbg_dm_prints <= dbg_dm_prints + 1;
                end
                `endif
            end else begin
                // 越界或未对齐写入，忽略（仿真策略）；如需可提示：
                `ifdef SIM_DEBUG
                if (dbg_dm_prints < DEBUG_DM_PRINT_MAX) begin
                    $display("[DM-WRITE-IGNORED] OOB/unaligned addr=0x%08h data=0x%08h", address, write_data);
                    dbg_dm_prints <= dbg_dm_prints + 1;
                end
                `endif
            end
        end
    end
endmodule
