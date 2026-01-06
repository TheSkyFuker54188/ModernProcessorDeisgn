`timescale 1ns/1ps
`include "cpu_defs.vh"

module Controller (
    input wire [5:0] opcode,
    input wire [5:0] funct,
    input wire [4:0] rt,
    output reg [1:0] reg_dst_sel,
    output reg [1:0] reg_write_data_sel,
    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg branch,
    output reg [2:0] branch_op,
    output reg jump,
    output reg jump_reg,
    output reg use_zero_extend,
    output reg is_syscall,
    output reg uses_rs,
    output reg uses_rt,
    output reg [3:0] alu_control,
    output reg [2:0] mdu_op,
    output reg mdu_start,
    output reg mdu_read,
    output reg [2:0] mem_size
);
    // Opcodes
    localparam OPC_RTYPE = 6'b000000;
    localparam OPC_REGIMM= 6'b000001;
    localparam OPC_J     = 6'b000010;
    localparam OPC_JAL   = 6'b000011;
    localparam OPC_BEQ   = 6'b000100;
    localparam OPC_BNE   = 6'b000101;
    localparam OPC_BLEZ  = 6'b000110;
    localparam OPC_BGTZ  = 6'b000111;
    localparam OPC_ADDI  = 6'b001000;
    localparam OPC_ADDIU = 6'b001001;
    localparam OPC_SLTI  = 6'b001010;
    localparam OPC_SLTIU = 6'b001011;
    localparam OPC_ANDI  = 6'b001100;
    localparam OPC_ORI   = 6'b001101;
    localparam OPC_XORI  = 6'b001110;
    localparam OPC_LUI   = 6'b001111;
    localparam OPC_LB    = 6'b100000;
    localparam OPC_LH    = 6'b100001;
    localparam OPC_LW    = 6'b100011;
    localparam OPC_LBU   = 6'b100100;
    localparam OPC_LHU   = 6'b100101;
    localparam OPC_SB    = 6'b101000;
    localparam OPC_SH    = 6'b101001;
    localparam OPC_SW    = 6'b101011;

    // Functs
    localparam FUNCT_SLL     = 6'h00;
    localparam FUNCT_SRA     = 6'h03;
    localparam FUNCT_SLLV    = 6'h04;
    localparam FUNCT_SRAV    = 6'h07;
    localparam FUNCT_JR      = 6'h08;
    localparam FUNCT_JALR    = 6'h09;
    localparam FUNCT_SYSCALL = 6'h0c;
    localparam FUNCT_MFHI    = 6'h10;
    localparam FUNCT_MTHI    = 6'h11;
    localparam FUNCT_MFLO    = 6'h12;
    localparam FUNCT_MTLO    = 6'h13;
    localparam FUNCT_MULT    = 6'h18;
    localparam FUNCT_MULTU   = 6'h19;
    localparam FUNCT_DIV     = 6'h1a;
    localparam FUNCT_DIVU    = 6'h1b;
    localparam FUNCT_ADD     = 6'h20;
    localparam FUNCT_ADDU    = 6'h21;
    localparam FUNCT_SUB     = 6'h22;
    localparam FUNCT_SUBU    = 6'h23;
    localparam FUNCT_AND     = 6'h24;
    localparam FUNCT_OR      = 6'h25;
    localparam FUNCT_XOR     = 6'h26;
    localparam FUNCT_NOR     = 6'h27;
    localparam FUNCT_SLT     = 6'h2a;
    localparam FUNCT_SLTU    = 6'h2b;

    // REGIMM rt
    localparam RT_BLTZ = 5'b00000;
    localparam RT_BGEZ = 5'b00001;

    // Mem Size
    localparam MEM_WORD  = 3'd0;
    localparam MEM_BYTE  = 3'd1;
    localparam MEM_HALF  = 3'd2;
    localparam MEM_UBYTE = 3'd3;
    localparam MEM_UHALF = 3'd4;

    always @(*) begin
        // Defaults
        reg_dst_sel = `REG_DST_RT;
        reg_write_data_sel = `WRITE_SRC_ALU;
        reg_write = 1'b0;
        alu_src = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        branch_op = `BRANCH_NONE;
        jump = 1'b0;
        jump_reg = 1'b0;
        use_zero_extend = 1'b0;
        is_syscall = 1'b0;
        uses_rs = 1'b0;
        uses_rt = 1'b0;
        alu_control = `ALU_CTRL_ADD;
        mdu_op = `MDU_READ_HI; // Default
        mdu_start = 1'b0;
        mdu_read = 1'b0;
        mem_size = MEM_WORD;

        case (opcode)
            OPC_RTYPE: begin
                case (funct)
                    FUNCT_ADD, FUNCT_ADDU: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_ADD;
                    end
                    FUNCT_SUB, FUNCT_SUBU: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SUB;
                    end
                    FUNCT_AND: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_AND;
                    end
                    FUNCT_OR: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_OR;
                    end
                    FUNCT_XOR: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_XOR;
                    end
                    FUNCT_NOR: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_NOR;
                    end
                    FUNCT_SLT: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SLT;
                    end
                    FUNCT_SLTU: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SLTU;
                    end
                    FUNCT_SLL: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SLL;
                    end
                    FUNCT_SRA: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SRA;
                    end
                    FUNCT_SLLV: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SLLV;
                    end
                    FUNCT_SRAV: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        alu_control = `ALU_CTRL_SRAV;
                    end
                    FUNCT_JR: begin
                        uses_rs = 1'b1;
                        jump_reg = 1'b1;
                    end
                    FUNCT_JALR: begin
                        uses_rs = 1'b1;
                        jump_reg = 1'b1;
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        reg_write_data_sel = `WRITE_SRC_PC8;
                    end
                    FUNCT_SYSCALL: begin
                        is_syscall = 1'b1;
                    end
                    FUNCT_MULT: begin
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        mdu_start = 1'b1;
                        mdu_op = `MDU_START_SIGNED_MUL;
                    end
                    FUNCT_MULTU: begin
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        mdu_start = 1'b1;
                        mdu_op = `MDU_START_UNSIGNED_MUL;
                    end
                    FUNCT_DIV: begin
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        mdu_start = 1'b1;
                        mdu_op = `MDU_START_SIGNED_DIV;
                    end
                    FUNCT_DIVU: begin
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                        mdu_start = 1'b1;
                        mdu_op = `MDU_START_UNSIGNED_DIV;
                    end
                    FUNCT_MFHI: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        mdu_read = 1'b1;
                        mdu_op = `MDU_READ_HI;
                    end
                    FUNCT_MFLO: begin
                        reg_dst_sel = `REG_DST_RD;
                        reg_write = 1'b1;
                        mdu_read = 1'b1;
                        mdu_op = `MDU_READ_LO;
                    end
                    FUNCT_MTHI: begin
                        uses_rs = 1'b1;
                        mdu_start = 1'b1;
                        mdu_op = `MDU_WRITE_HI;
                    end
                    FUNCT_MTLO: begin
                        uses_rs = 1'b1;
                        mdu_start = 1'b1;
                        mdu_op = `MDU_WRITE_LO;
                    end
                endcase
            end
            OPC_REGIMM: begin
                uses_rs = 1'b1;
                branch = 1'b1;
                case (rt)
                    RT_BLTZ: branch_op = `BRANCH_BLTZ;
                    RT_BGEZ: branch_op = `BRANCH_BGEZ;
                endcase
            end
            OPC_J: begin
                jump = 1'b1;
            end
            OPC_JAL: begin
                jump = 1'b1;
                reg_dst_sel = `REG_DST_RA;
                reg_write = 1'b1;
                reg_write_data_sel = `WRITE_SRC_PC8;
            end
            OPC_BEQ: begin
                uses_rs = 1'b1;
                uses_rt = 1'b1;
                branch = 1'b1;
                branch_op = `BRANCH_BEQ;
            end
            OPC_BNE: begin
                uses_rs = 1'b1;
                uses_rt = 1'b1;
                branch = 1'b1;
                branch_op = `BRANCH_BNE;
            end
            OPC_BLEZ: begin
                uses_rs = 1'b1;
                branch = 1'b1;
                branch_op = `BRANCH_BLEZ;
            end
            OPC_BGTZ: begin
                uses_rs = 1'b1;
                branch = 1'b1;
                branch_op = `BRANCH_BGTZ;
            end
            OPC_ADDI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
            end
            OPC_ADDIU: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
            end
            OPC_SLTI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_SLT;
            end
            OPC_SLTIU: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_SLTU;
            end
            OPC_ANDI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                use_zero_extend = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_AND;
            end
            OPC_ORI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                use_zero_extend = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_OR;
            end
            OPC_XORI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                use_zero_extend = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_XOR;
            end
            OPC_LUI: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = `ALU_CTRL_LUI;
            end
            OPC_LB: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_BYTE;
            end
            OPC_LH: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_HALF;
            end
            OPC_LW: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_WORD;
            end
            OPC_LBU: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_UBYTE;
            end
            OPC_LHU: begin
                reg_dst_sel = `REG_DST_RT;
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                uses_rs = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_UHALF;
            end
            OPC_SB: begin
                alu_src = 1'b1;
                mem_write = 1'b1;
                uses_rs = 1'b1;
                uses_rt = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_BYTE;
            end
            OPC_SH: begin
                alu_src = 1'b1;
                mem_write = 1'b1;
                uses_rs = 1'b1;
                uses_rt = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_HALF;
            end
            OPC_SW: begin
                alu_src = 1'b1;
                mem_write = 1'b1;
                uses_rs = 1'b1;
                uses_rt = 1'b1;
                alu_control = `ALU_CTRL_ADD;
                mem_size = MEM_WORD;
            end
        endcase
    end
endmodule
