`timescale 1ns/1ps
`include "cpu_defs.vh"

module PipelineTop (
    input wire reset,
    input wire clock,
    output reg halted
);
    localparam IMEM_INIT_FILE = "D:\\PROGRAMMING\\ModernProcessorDeisgn\\Lab\\project_6-PipeLine\\code.txt";

    // Program counter and IF stage --------------------------------------------------
    wire [31:0] pc_current;
    wire [31:0] pc_plus4 = pc_current + 32'd4;
    reg  [31:0] pc_next;

    wire stallF;
    wire stallD;
    wire flushE;
    wire pc_enable;

    ProgramCounter pc_reg (
        .clock(clock),
        .reset(reset),
        .enable(pc_enable),
        .next_pc(pc_next),
        .current_pc(pc_current)
    );

    wire [31:0] instructionF;
    InstructionMemory #(
        .INIT_FILE(IMEM_INIT_FILE),
        .BASE_ADDR(32'h00003000)
    ) instruction_memory (
        .address(pc_current),
        .instruction(instructionF)
    );

    // Debug: print fetched instruction for a small PC window to trace loop
    always @(posedge clock) begin
        if (!reset) begin
            if (pc_current >= 32'h00003060 && pc_current <= 32'h000030d0) begin
                $display("[FETCH] PC=%h INSTR=%h if_id_instr=%h if_id_pc=%h", pc_current, instructionF, if_id_instr, if_id_pc);
            end
        end
    end

    // IF/ID pipeline register ------------------------------------------------------
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc4;
    reg [31:0] if_id_instr;

    wire flush_if_id;
    reg if_id_write_enable;

    localparam [31:0] NOP_INSTR = 32'b0;

    // ID stage decode --------------------------------------------------------------
    wire [5:0] opcodeD = if_id_instr[31:26];
    wire [4:0] rsD = if_id_instr[25:21];
    wire [4:0] rtD = if_id_instr[20:16];
    wire [4:0] rdD = if_id_instr[15:11];
    wire [5:0] functD = if_id_instr[5:0];
    wire [15:0] immD = if_id_instr[15:0];

    wire [1:0] reg_dst_selD;
    wire [1:0] write_src_selD;
    wire reg_writeD;
    wire alu_srcD;
    wire mem_readD;
    wire mem_writeD;
    wire branchD;
    wire jumpD;
    wire jump_regD;
    wire use_zero_extendD;
    wire is_syscallD;
    wire uses_rsD;
    wire uses_rtD;
    wire [3:0] alu_controlD;

    Controller controller (
        .opcode(opcodeD),
        .funct(functD),
        .reg_dst_sel(reg_dst_selD),
        .reg_write_data_sel(write_src_selD),
        .reg_write(reg_writeD),
        .alu_src(alu_srcD),
        .mem_read(mem_readD),
        .mem_write(mem_writeD),
        .branch(branchD),
        .jump(jumpD),
        .jump_reg(jump_regD),
        .use_zero_extend(use_zero_extendD),
        .is_syscall(is_syscallD),
        .uses_rs(uses_rsD),
        .uses_rt(uses_rtD),
        .alu_control(alu_controlD)
    );

    wire [31:0] reg_data1D;
    wire [31:0] reg_data2D;

    reg [4:0] reg_write_addrW;
    reg [31:0] reg_write_dataW;
    reg reg_writeW;

    // MEM/WB pipeline register shadow (declared early for wiring convenience)
    reg mem_wb_reg_write;
    reg mem_wb_mem_to_reg;
    reg [1:0] mem_wb_write_src_sel;
    reg [4:0] mem_wb_dest;
    reg [31:0] mem_wb_pc;
    reg [31:0] mem_wb_pc8;
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_read_data;
    reg [31:0] mem_wb_lui_value;
    reg mem_wb_is_syscall;

    RegisterFile register_file (
        .clock(clock),
        .reset(reset),
        .reg_write(reg_writeW),
        .read_addr1(rsD),
        .read_addr2(rtD),
        .write_addr(reg_write_addrW),
        .write_data(reg_write_dataW),
        .debug_pc(mem_wb_pc),
        .read_data1(reg_data1D),
        .read_data2(reg_data2D)
    );

    wire [31:0] sign_ext_immD = {{16{immD[15]}}, immD};
    wire [31:0] zero_ext_immD = {16'b0, immD};
    wire [31:0] imm_extD = use_zero_extendD ? zero_ext_immD : sign_ext_immD;
    wire [31:0] lui_valueD = {immD, 16'b0};
    wire [31:0] pc_plus8D = if_id_pc4 + 32'd4;
    wire [31:0] jump_targetD = {if_id_pc4[31:28], if_id_instr[25:0], 2'b00};

    wire [4:0] reg_dstD = (reg_dst_selD == `REG_DST_RT) ? rtD :
                          (reg_dst_selD == `REG_DST_RD) ? rdD :
                          `REG_RA;
    wire id_mem_to_reg = (write_src_selD == `WRITE_SRC_MEM);

    // Halt handling (syscall) ------------------------------------------------------
    reg halt_fetch;

    // ID/EX pipeline register ------------------------------------------------------
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_pc4;
    reg [31:0] id_ex_pc8;
    reg [31:0] id_ex_reg_data1;
    reg [31:0] id_ex_reg_data2;
    reg [31:0] id_ex_imm;
    reg [31:0] id_ex_lui_value;
    reg [31:0] id_ex_jump_target;
    reg [4:0] id_ex_rs;
    reg [4:0] id_ex_rt;
    reg [4:0] id_ex_rd;
    reg [4:0] id_ex_dest;
    reg [1:0] id_ex_write_src_sel;
    reg id_ex_reg_write;
    reg id_ex_alu_src;
    reg id_ex_mem_read;
    reg id_ex_mem_write;
    reg id_ex_branch;
    reg id_ex_jump;
    reg id_ex_jump_reg;
    reg id_ex_is_syscall;
    reg [3:0] id_ex_alu_control;
    reg id_ex_mem_to_reg;

    // Hazard detection -------------------------------------------------------------
    HazardDetectionUnit hazard_unit (
        .id_use_rs(uses_rsD),
        .id_use_rt(uses_rtD),
        .if_id_rs(rsD),
        .if_id_rt(rtD),
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_dest(id_ex_dest),
        .stallF(stallF),
        .stallD(stallD),
        .flushE(flushE)
    );

    // EX stage ---------------------------------------------------------------------
    wire [1:0] forwardAE;
    wire [1:0] forwardBE;

    reg ex_mem_reg_write;
    reg ex_mem_mem_read;
    reg ex_mem_mem_write;
    reg ex_mem_mem_to_reg;
    reg [1:0] ex_mem_write_src_sel;
    reg [4:0] ex_mem_dest;
    reg [31:0] ex_mem_pc;
    reg [31:0] ex_mem_pc8;
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_write_data;
    reg [31:0] ex_mem_lui_value;
    reg ex_mem_is_syscall;

    ForwardingUnit forwarding_unit (
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_to_reg(ex_mem_mem_to_reg),
        .ex_mem_dest(ex_mem_dest),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_dest(mem_wb_dest),
        .id_ex_rs(id_ex_rs),
        .id_ex_rt(id_ex_rt),
        .forwardAE(forwardAE),
        .forwardBE(forwardBE)
    );

    wire [31:0] mem_wb_write_data;

    wire [31:0] forwardA_value = (forwardAE == 2'b10) ? ex_mem_alu_result :
                                 (forwardAE == 2'b01) ? mem_wb_write_data :
                                 id_ex_reg_data1;

    wire [31:0] forwardB_value = (forwardBE == 2'b10) ? ex_mem_alu_result :
                                 (forwardBE == 2'b01) ? mem_wb_write_data :
                                 id_ex_reg_data2;

    wire [31:0] alu_operand_b = id_ex_alu_src ? id_ex_imm : forwardB_value;
    wire [31:0] alu_resultE;
    wire alu_zeroE;

    ArithmeticLogicUnit alu (
        .operand_a(forwardA_value),
        .operand_b(alu_operand_b),
        .control(id_ex_alu_control),
        .result(alu_resultE),
        .zero(alu_zeroE)
    );

    // EX-stage debug: when executing instruction at PC 0x00003068 or writing to $23, print operands and forwarding
    always @(posedge clock) begin
        if (!reset) begin
            if (id_ex_pc == 32'h00003068 || id_ex_dest == 5'd23) begin
                $display("[EX_DBG] time=%0t id_ex_pc=%h id_ex_dest=%0d rs=%0d rt=%0d id_ex_reg_data1=%h id_ex_reg_data2=%h forwardA=%h forwardB=%h alu_operand_b=%h alu_result=%h id_ex_write_src_sel=%0d id_ex_reg_write=%0d", $time, id_ex_pc, id_ex_dest, id_ex_rs, id_ex_rt, id_ex_reg_data1, id_ex_reg_data2, forwardA_value, forwardB_value, alu_operand_b, alu_resultE, id_ex_write_src_sel, id_ex_reg_write);
            end
        end
    end

    wire [31:0] branch_targetE = id_ex_pc4 + (id_ex_imm << 2);
    wire branch_takenE = id_ex_branch && (forwardA_value == forwardB_value);
    wire jump_takenE = id_ex_jump;
    wire jump_reg_takenE = id_ex_jump_reg;
    wire redirect_validE = branch_takenE || jump_takenE || jump_reg_takenE;
    wire [31:0] redirect_targetE = jump_reg_takenE ? forwardA_value :
                                   jump_takenE     ? id_ex_jump_target :
                                                     branch_targetE;

    wire [31:0] store_dataE = forwardB_value;

    // Data memory ------------------------------------------------------------------
    wire [31:0] data_memory_read_data;

    DataMemory data_memory (
        .clock(clock),
        .reset(reset),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .address(ex_mem_alu_result),
        .write_data(ex_mem_write_data),
        .debug_pc(ex_mem_pc),
        .read_data(data_memory_read_data)
    );

    // Register write-back mux ------------------------------------------------------
    assign mem_wb_write_data = (mem_wb_write_src_sel == `WRITE_SRC_MEM) ? mem_wb_mem_read_data :
                               (mem_wb_write_src_sel == `WRITE_SRC_PC8) ? mem_wb_pc8 :
                               (mem_wb_write_src_sel == `WRITE_SRC_LUI) ? mem_wb_lui_value :
                               mem_wb_alu_result;

    // Control for PC enable --------------------------------------------------------
    always @(*) begin
        pc_next = pc_plus4;
        if (redirect_validE) begin
            pc_next = redirect_targetE;
        end
    end

    assign pc_enable = !(stallF || halt_fetch);

    always @(*) begin
        if_id_write_enable = (!stallD) && (!halt_fetch);
    end

    assign flush_if_id = redirect_validE || (is_syscallD && !halt_fetch && !stallD);

    // Pipeline register updates ----------------------------------------------------
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            if_id_pc <= 32'b0;
            if_id_pc4 <= 32'b0;
            if_id_instr <= NOP_INSTR;
        end else if (flush_if_id) begin
            if_id_pc <= 32'b0;
            if_id_pc4 <= 32'b0;
            if_id_instr <= NOP_INSTR;
        end else if (if_id_write_enable) begin
            if_id_pc <= pc_current;
            if_id_pc4 <= pc_plus4;
            if_id_instr <= instructionF;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            halt_fetch <= 1'b0;
        end else if (!halt_fetch && is_syscallD && !stallD) begin
            halt_fetch <= 1'b1;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            id_ex_pc <= 32'b0;
            id_ex_pc4 <= 32'b0;
            id_ex_pc8 <= 32'b0;
            id_ex_reg_data1 <= 32'b0;
            id_ex_reg_data2 <= 32'b0;
            id_ex_imm <= 32'b0;
            id_ex_lui_value <= 32'b0;
            id_ex_jump_target <= 32'b0;
            id_ex_rs <= 5'd0;
            id_ex_rt <= 5'd0;
            id_ex_rd <= 5'd0;
            id_ex_dest <= 5'd0;
            id_ex_write_src_sel <= `WRITE_SRC_ALU;
            id_ex_reg_write <= 1'b0;
            id_ex_alu_src <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_branch <= 1'b0;
            id_ex_jump <= 1'b0;
            id_ex_jump_reg <= 1'b0;
            id_ex_is_syscall <= 1'b0;
            id_ex_alu_control <= `ALU_CTRL_ADD;
            id_ex_mem_to_reg <= 1'b0;
        end else if (flushE) begin
            id_ex_reg_write <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_branch <= 1'b0;
            id_ex_jump <= 1'b0;
            id_ex_jump_reg <= 1'b0;
            id_ex_is_syscall <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
        end else if (!stallD) begin
            id_ex_pc <= if_id_pc;
            id_ex_pc4 <= if_id_pc4;
            id_ex_pc8 <= pc_plus8D;
            id_ex_reg_data1 <= reg_data1D;
            id_ex_reg_data2 <= reg_data2D;
            id_ex_imm <= imm_extD;
            id_ex_lui_value <= lui_valueD;
            id_ex_jump_target <= jump_targetD;
            id_ex_rs <= rsD;
            id_ex_rt <= rtD;
            id_ex_rd <= rdD;
            id_ex_dest <= reg_dstD;
            id_ex_write_src_sel <= write_src_selD;
            id_ex_reg_write <= reg_writeD;
            id_ex_alu_src <= alu_srcD;
            id_ex_mem_read <= mem_readD;
            id_ex_mem_write <= mem_writeD;
            id_ex_branch <= branchD;
            id_ex_jump <= jumpD;
            id_ex_jump_reg <= jump_regD;
            id_ex_is_syscall <= is_syscallD;
            id_ex_alu_control <= alu_controlD;
            id_ex_mem_to_reg <= id_mem_to_reg;
        end
    end

    // Debug: report when ID stage detects a syscall
    always @(posedge clock) begin
        if (!reset && is_syscallD) begin
            $display("[DBG] ID detected syscall at IF/ID PC=%h (if_id_pc=%h)", if_id_instr, if_id_pc);
        end
    end

    // EX/MEM register update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_write_src_sel <= `WRITE_SRC_ALU;
            ex_mem_dest <= 5'd0;
            ex_mem_pc <= 32'b0;
            ex_mem_pc8 <= 32'b0;
            ex_mem_alu_result <= 32'b0;
            ex_mem_write_data <= 32'b0;
            ex_mem_lui_value <= 32'b0;
            ex_mem_is_syscall <= 1'b0;
        end else begin
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_write_src_sel <= id_ex_write_src_sel;
            ex_mem_dest <= id_ex_dest;
            ex_mem_pc <= id_ex_pc;
            ex_mem_pc8 <= id_ex_pc8;
            ex_mem_alu_result <= alu_resultE;
            ex_mem_write_data <= store_dataE;
            ex_mem_lui_value <= id_ex_lui_value;
            ex_mem_is_syscall <= id_ex_is_syscall;
            if (id_ex_is_syscall) begin
                $display("[DBG] EX stage passing syscall from ID pc=%h (id_ex_pc=%h)", id_ex_dest, id_ex_pc);
            end
        end
    end

    // MEM/WB register update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
            mem_wb_write_src_sel <= `WRITE_SRC_ALU;
            mem_wb_dest <= 5'd0;
            mem_wb_pc <= 32'b0;
            mem_wb_pc8 <= 32'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_mem_read_data <= 32'b0;
            mem_wb_lui_value <= 32'b0;
            mem_wb_is_syscall <= 1'b0;
        end else begin
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_write_src_sel <= ex_mem_write_src_sel;
            mem_wb_dest <= ex_mem_dest;
            mem_wb_pc <= ex_mem_pc;
            mem_wb_pc8 <= ex_mem_pc8;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_read_data <= data_memory_read_data;
            mem_wb_lui_value <= ex_mem_lui_value;
            mem_wb_is_syscall <= ex_mem_is_syscall;
            if (ex_mem_is_syscall) begin
                $display("[DBG] MEM/WB stage received syscall, ex_mem_pc=%h mem_wb_pc will be %h", ex_mem_pc, ex_mem_pc);
            end
            // Additional debug: when EX/MEM is going to write to $23 (s7), print source and values
            if (ex_mem_reg_write && ex_mem_dest == 5'd23) begin
                $display("[WR_DBG] time=%0t EX/MEM will write $23: ex_mem_pc=%h write_src_sel=%0d alu_result=%h mem_read_data=%h", $time, ex_mem_pc, ex_mem_write_src_sel, ex_mem_alu_result, data_memory_read_data);
            end
        end
    end

    // Register write back bookkeeping
    always @(*) begin
        reg_write_addrW = mem_wb_dest;
        reg_write_dataW = mem_wb_write_data;
        reg_writeW = mem_wb_reg_write;
    end

    // Halt monitor ---------------------------------------------------------------
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            halted <= 1'b0;
        end else if (mem_wb_is_syscall && !halted) begin
            halted <= 1'b1;
            $display("\n==== Simulation finished via syscall at PC %h ====", mem_wb_pc);
            $finish;
        end
    end
endmodule
