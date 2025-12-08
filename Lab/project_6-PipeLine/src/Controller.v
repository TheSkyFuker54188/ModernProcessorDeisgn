`timescale 1ns/1ps
`include "cpu_defs.vh"

module Controller (
    input wire [5:0] opcode,
    input wire [5:0] funct,
    output reg [1:0] reg_dst_sel,
    output reg [1:0] reg_write_data_sel,
    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg branch,
    output reg jump,
    output reg jump_reg,
    output reg use_zero_extend,
    output reg is_syscall,
    output reg uses_rs,
    output reg uses_rt,
    output reg [3:0] alu_control
);
    localparam OPC_RTYPE = 6'b000000;
    localparam OPC_ORI   = 6'b001101;
    localparam OPC_LW    = 6'b100011;
    localparam OPC_SW    = 6'b101011;
    localparam OPC_BEQ   = 6'b000100;
    localparam OPC_LUI   = 6'b001111;
    localparam OPC_JAL   = 6'b000011;
    localparam OPC_J     = 6'b000010;

    localparam FUNCT_ADDU    = 6'h21;
    localparam FUNCT_SUBU    = 6'h23;
    localparam FUNCT_JR      = 6'h08;
    localparam FUNCT_SYSCALL = 6'h0c;

    always @(*) begin
        reg_dst_sel = `REG_DST_RT;
        reg_write_data_sel = `WRITE_SRC_ALU;
        reg_write = 1'b0;
        alu_src = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        jump_reg = 1'b0;
        use_zero_extend = 1'b0;
        is_syscall = 1'b0;
        uses_rs = 1'b0;
        uses_rt = 1'b0;
        alu_control = `ALU_CTRL_ADD;

        case (opcode)
            OPC_RTYPE: begin
                uses_rs = 1'b1;
                case (funct)
                    FUNCT_ADDU: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_ADD;
                    end
                    FUNCT_SUBU: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SUB;
                    end
                    FUNCT_JR: begin
                        jump_reg = 1'b1;
                    end
                    FUNCT_SYSCALL: begin
                        is_syscall = 1'b1;
                        uses_rs = 1'b0;
                    end
                    default: begin
                        uses_rs = 1'b0;
                    end
                endcase
            end
            OPC_ORI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                use_zero_extend = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_OR;
            end
            OPC_LW: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                reg_write_data_sel = `WRITE_SRC_MEM;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
            end
            OPC_SW: begin
                alu_src = 1'b1;
                mem_write = 1'b1;
                uses_rs = 1'b1;
                uses_rt = 1'b1;
                alu_control = `ALU_CTRL_ADD;
            end
            OPC_BEQ: begin
                branch = 1'b1;
                uses_rs = 1'b1;
                uses_rt = 1'b1;
                alu_control = `ALU_CTRL_SUB;
            end
            OPC_LUI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                reg_write_data_sel = `WRITE_SRC_LUI;
                use_zero_extend = 1'b1;
                alu_control = `ALU_CTRL_PASS;
            end
            OPC_JAL: begin
                reg_dst_sel = `REG_DST_RA;
                reg_write = 1'b1;
                reg_write_data_sel = `WRITE_SRC_PC8;
                jump = 1'b1;
            end
            OPC_J: begin
                jump = 1'b1;
            end
            default: begin
                // remain NOP
            end
        endcase
    end
endmodule
