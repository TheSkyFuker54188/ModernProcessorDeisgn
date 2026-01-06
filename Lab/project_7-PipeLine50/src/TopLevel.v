`timescale 1us/1us
`include "cpu_defs.vh"

module TopLevel (
    input wire reset,
    input wire clock,
    output reg halted
);
    // Program counter and IF stage --------------------------------------------------
    wire [31:0] pc_current;
    wire [31:0] pc_plus4 = pc_current + 32'd4;
    reg  [31:0] pc_next;

    wire stallF;
    wire stallD;
    wire stallE;
    wire flushE;
    wire flushM;
    wire pc_enable;

    ProgramCounter #(
        .RESET_PC(32'h00003000)
    ) pc_reg (
        .clock(clock),
        .reset(reset),
        .enable(pc_enable),
        .next_pc(pc_next),
        .current_pc(pc_current)
    );

    wire [31:0] instructionF;
    InstructionMemory #(
        .BASE_ADDR(32'h00003000),
        .MEM_DEPTH(4096)
    ) instruction_memory (
        .address(pc_current),
        .instruction(instructionF)
    );

    // IF/ID pipeline register ------------------------------------------------------
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc4;
    reg [31:0] if_id_instr;

    wire flush_if_id;
    wire if_id_write_enable;

    localparam [31:0] NOP_INSTR = 32'b0;

    // ID stage decode --------------------------------------------------------------
    wire [5:0] opcodeD = if_id_instr[31:26];
    wire [4:0] rsD = if_id_instr[25:21];
    wire [4:0] rtD = if_id_instr[20:16];
    wire [4:0] rdD = if_id_instr[15:11];
    wire [4:0] shamtD = if_id_instr[10:6];
    wire [5:0] functD = if_id_instr[5:0];
    wire [15:0] immD = if_id_instr[15:0];

    wire [1:0] reg_dst_selD;
    wire [1:0] write_src_selD;
    wire reg_writeD;
    wire alu_srcD;
    wire mem_readD;
    wire mem_writeD;
    wire branchD;
    wire [2:0] branch_opD;
    wire jumpD;
    wire jump_regD;
    wire use_zero_extendD;
    wire is_syscallD;
    wire uses_rsD;
    wire uses_rtD;
    wire [3:0] alu_controlD;
    wire [2:0] mdu_opD;
    wire mdu_startD;
    wire mdu_readD;
    wire [2:0] mem_sizeD;

    Controller controller (
        .opcode(opcodeD),
        .funct(functD),
        .rt(rtD),
        .reg_dst_sel(reg_dst_selD),
        .reg_write_data_sel(write_src_selD),
        .reg_write(reg_writeD),
        .alu_src(alu_srcD),
        .mem_read(mem_readD),
        .mem_write(mem_writeD),
        .branch(branchD),
        .branch_op(branch_opD),
        .jump(jumpD),
        .jump_reg(jump_regD),
        .use_zero_extend(use_zero_extendD),
        .is_syscall(is_syscallD),
        .uses_rs(uses_rsD),
        .uses_rt(uses_rtD),
        .alu_control(alu_controlD),
        .mdu_op(mdu_opD),
        .mdu_start(mdu_startD),
        .mdu_read(mdu_readD),
        .mem_size(mem_sizeD)
    );

    // Register File
    wire [31:0] reg_data1D, reg_data2D;
    reg [4:0] reg_write_addrW;
    reg [31:0] reg_write_dataW;
    reg reg_writeW;

    RegisterFile register_file (
        .clock(clock),
        .reset(reset),
        .read_addr1(rsD),
        .read_addr2(rtD),
        .write_addr(reg_write_addrW),
        .write_data(reg_write_dataW),
        .reg_write(reg_writeW),
        .debug_pc(mem_wb_pc),
        .read_data1(reg_data1D),
        .read_data2(reg_data2D)
    );

    // Sign/Zero Extension
    wire [31:0] imm_extD = use_zero_extendD ? {16'b0, immD} : {{16{immD[15]}}, immD};
    wire [31:0] pc_plus8D = if_id_pc4 + 32'd4;
    wire [31:0] jump_targetD = {if_id_pc4[31:28], if_id_instr[25:0], 2'b00};

    wire [1:0] reg_dstD = (reg_dst_selD == `REG_DST_RD) ? 2'b01 :
                          (reg_dst_selD == `REG_DST_RA) ? 2'b10 : 2'b00;

    // Syscall argument reading in ID stage (with full forwarding from MEM, WB)
    // $v0 = register 2, $a0 = register 4
    // Need to check forwarding from pipeline stages where result is available
    // Priority: MEM (ex_mem) > WB (mem_wb) > Register File
    // Note: Cannot forward from ID_EX because ALU result is not yet computed
    // The forwarding at later stages (EX, MEM) will catch those cases
    wire [31:0] syscall_v0_D = 
        (ex_mem_reg_write && ex_mem_dest == 5'd2) ? ex_mem_alu_result :
        (mem_wb_reg_write && mem_wb_dest == 5'd2) ? reg_write_dataW :
        register_file.registers[2];
    wire [31:0] syscall_a0_D = 
        (ex_mem_reg_write && ex_mem_dest == 5'd4) ? ex_mem_alu_result :
        (mem_wb_reg_write && mem_wb_dest == 5'd4) ? reg_write_dataW :
        register_file.registers[4];

    // Hazard Detection
    wire hazard_stallF, hazard_stallD, hazard_flushE;
    
    reg id_ex_mem_read;
    reg [4:0] id_ex_dest;
    reg id_ex_mem_to_reg;

    HazardDetectionUnit hazard_unit (
        .id_use_rs(uses_rsD),
        .id_use_rt(uses_rtD),
        .if_id_rs(rsD),
        .if_id_rt(rtD),
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_dest(id_ex_dest),
        .stallF(hazard_stallF),
        .stallD(hazard_stallD),
        .flushE(hazard_flushE)
    );

    // ID/EX pipeline register ------------------------------------------------------
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_pc4;
    reg [31:0] id_ex_pc8;
    reg [31:0] id_ex_reg_data1;
    reg [31:0] id_ex_reg_data2;
    reg [31:0] id_ex_imm;
    reg [31:0] id_ex_jump_target;
    reg [4:0] id_ex_rs;
    reg [4:0] id_ex_rt;
    reg [4:0] id_ex_rd;
    reg [4:0] id_ex_shamt;
    reg [1:0] id_ex_write_src_sel;
    reg id_ex_reg_write;
    reg id_ex_alu_src;
    reg id_ex_mem_write;
    reg id_ex_branch;
    reg [2:0] id_ex_branch_op;
    reg id_ex_jump;
    reg id_ex_jump_reg;
    reg id_ex_is_syscall;
    reg [31:0] id_ex_syscall_v0;  // Syscall $v0 value captured in ID
    reg [31:0] id_ex_syscall_a0;  // Syscall $a0 value captured in ID
    reg [3:0] id_ex_alu_control;
    reg [2:0] id_ex_mdu_op;
    reg id_ex_mdu_start;
    reg id_ex_mdu_read;
    reg [2:0] id_ex_mem_size;

    // EX Stage signals
    wire [31:0] forwardA_value;
    wire [31:0] forwardB_value;
    wire mdu_busy;
    
    // Stall Logic
    wire stall_mdu = (id_ex_mdu_start || id_ex_mdu_read) && mdu_busy;
    
    assign stallF = hazard_stallF || stall_mdu;
    assign stallD = hazard_stallD || stall_mdu;
    assign stallE = stall_mdu;
    assign flushE = hazard_flushE && !stall_mdu;
    assign flushM = stall_mdu;

    // Branch Logic (Forward Declaration for redirect_validE)
    reg branch_cond;
    wire branch_takenE;
    wire jump_takenE = id_ex_jump;
    wire jump_reg_takenE = id_ex_jump_reg;
    wire redirect_validE = branch_takenE || jump_takenE || jump_reg_takenE;

    assign pc_enable = !stallF && !halted;
    assign if_id_write_enable = !stallD && !halted;
    // Only flush IF/ID on branch/jump redirects, NOT on syscall
    // Syscall should proceed normally through the pipeline
    assign flush_if_id = redirect_validE;

    // IF/ID Update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            if_id_pc <= 0;
            if_id_pc4 <= 0;
            if_id_instr <= NOP_INSTR;
        end else if (flush_if_id) begin
            if_id_pc <= 0;
            if_id_pc4 <= 0;
            if_id_instr <= NOP_INSTR;
        end else if (if_id_write_enable) begin
            if_id_pc <= pc_current;
            if_id_pc4 <= pc_plus4;
            if_id_instr <= instructionF;
        end
    end

    // ID/EX Update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            id_ex_pc <= 0;
            id_ex_reg_write <= 0;
            id_ex_mem_read <= 0;
            id_ex_mem_write <= 0;
            id_ex_branch <= 0;
            id_ex_jump <= 0;
            id_ex_mdu_start <= 0;
            id_ex_mem_to_reg <= 0;
        end else if (flushE) begin
            id_ex_reg_write <= 0;
            id_ex_mem_read <= 0;
            id_ex_mem_write <= 0;
            id_ex_branch <= 0;
            id_ex_jump <= 0;
            id_ex_mdu_start <= 0;
            id_ex_mem_to_reg <= 0;
        end else if (!stallE) begin
            id_ex_pc <= if_id_pc;
            id_ex_pc4 <= if_id_pc4;
            id_ex_pc8 <= pc_plus8D;
            id_ex_reg_data1 <= reg_data1D;
            id_ex_reg_data2 <= reg_data2D;
            id_ex_imm <= imm_extD;
            id_ex_jump_target <= jump_targetD;
            id_ex_rs <= rsD;
            id_ex_rt <= rtD;
            id_ex_rd <= rdD;
            id_ex_shamt <= shamtD;
            id_ex_dest <= (reg_dstD == 2'b01) ? rdD : (reg_dstD == 2'b10) ? 5'd31 : rtD;
            id_ex_write_src_sel <= write_src_selD;
            id_ex_reg_write <= reg_writeD;
            id_ex_alu_src <= alu_srcD;
            id_ex_mem_read <= mem_readD;
            id_ex_mem_write <= mem_writeD;
            id_ex_branch <= branchD;
            id_ex_branch_op <= branch_opD;
            id_ex_jump <= jumpD;
            id_ex_jump_reg <= jump_regD;
            id_ex_is_syscall <= is_syscallD;
            id_ex_syscall_v0 <= syscall_v0_D;
            id_ex_syscall_a0 <= syscall_a0_D;
            id_ex_alu_control <= alu_controlD;
            id_ex_mem_to_reg <= (write_src_selD == `WRITE_SRC_MEM);
            id_ex_mdu_op <= mdu_opD;
            id_ex_mdu_start <= mdu_startD;
            id_ex_mdu_read <= mdu_readD;
            id_ex_mem_size <= mem_sizeD;
        end
    end

    // EX Stage ---------------------------------------------------------------------
    // Forwarding Unit
    wire [1:0] forwardAE, forwardBE;
    reg [4:0] ex_mem_dest;
    reg ex_mem_reg_write;
    reg [4:0] mem_wb_dest;
    reg mem_wb_reg_write;

    ForwardingUnit forwarding_unit (
        .id_ex_rs(id_ex_rs),
        .id_ex_rt(id_ex_rt),
        .ex_mem_dest(ex_mem_dest),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_to_reg(ex_mem_mem_to_reg),
        .mem_wb_dest(mem_wb_dest),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forwardAE(forwardAE),
        .forwardBE(forwardBE)
    );

    assign forwardA_value = (forwardAE == 2'b10) ? ex_mem_alu_result :
                            (forwardAE == 2'b01) ? reg_write_dataW : id_ex_reg_data1;
    assign forwardB_value = (forwardBE == 2'b10) ? ex_mem_alu_result :
                            (forwardBE == 2'b01) ? reg_write_dataW : id_ex_reg_data2;

    wire [31:0] alu_operand_b = id_ex_alu_src ? id_ex_imm : forwardB_value;
    wire [31:0] alu_result_raw;
    wire alu_zero;

    ArithmeticLogicUnit alu (
        .operand_a(forwardA_value),
        .operand_b(alu_operand_b),
        .shamt(id_ex_shamt),
        .control(id_ex_alu_control),
        .result(alu_result_raw),
        .zero(alu_zero)
    );

    // MDU
    wire [31:0] mdu_data_read;
    MultiplicationDivisionUnit mdu (
        .reset(reset),
        .clock(clock),
        .operand1(forwardA_value),
        .operand2(forwardB_value),
        .operation(id_ex_mdu_op),
        .start(id_ex_mdu_start && !mdu_busy),
        .busy(mdu_busy),
        .dataRead(mdu_data_read)
    );

    wire [31:0] alu_resultE = id_ex_mdu_read ? mdu_data_read : alu_result_raw;

    // Branch Logic
    always @(*) begin
        case (id_ex_branch_op)
            `BRANCH_BEQ:  branch_cond = (forwardA_value == forwardB_value);
            `BRANCH_BNE:  branch_cond = (forwardA_value != forwardB_value);
            `BRANCH_BLEZ: branch_cond = ($signed(forwardA_value) <= 0);
            `BRANCH_BGTZ: branch_cond = ($signed(forwardA_value) > 0);
            `BRANCH_BLTZ: branch_cond = ($signed(forwardA_value) < 0);
            `BRANCH_BGEZ: branch_cond = ($signed(forwardA_value) >= 0);
            default:      branch_cond = 1'b0;
        endcase
    end

    assign branch_takenE = id_ex_branch && branch_cond;
    
    wire [31:0] branch_targetE = id_ex_pc4 + (id_ex_imm << 2);
    wire [31:0] redirect_targetE = jump_reg_takenE ? forwardA_value :
                                   jump_takenE     ? id_ex_jump_target :
                                                     branch_targetE;

    always @(*) begin
        if (redirect_validE) pc_next = redirect_targetE;
        else pc_next = pc_plus4;
    end

    // EX/MEM pipeline register -----------------------------------------------------
    reg [31:0] ex_mem_pc;
    reg [31:0] ex_mem_pc8;
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_write_data;
    reg ex_mem_mem_read;
    reg ex_mem_mem_write;
    reg ex_mem_mem_to_reg;
    reg [1:0] ex_mem_write_src_sel;
    reg ex_mem_is_syscall;
    reg [31:0] ex_mem_syscall_v0;
    reg [31:0] ex_mem_syscall_a0;
    reg [2:0] ex_mem_mem_size;

    // Syscall argument forwarding in EX stage
    // When syscall is in EX stage, forward from EX_MEM and MEM_WB
    // The instruction that was in ID_EX when syscall was in ID is now in EX_MEM
    wire [31:0] syscall_v0_E = 
        (ex_mem_reg_write && ex_mem_dest == 5'd2) ? ex_mem_alu_result :
        (mem_wb_reg_write && mem_wb_dest == 5'd2) ? reg_write_dataW :
        id_ex_syscall_v0;
    wire [31:0] syscall_a0_E = 
        (ex_mem_reg_write && ex_mem_dest == 5'd4) ? ex_mem_alu_result :
        (mem_wb_reg_write && mem_wb_dest == 5'd4) ? reg_write_dataW :
        id_ex_syscall_a0;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ex_mem_reg_write <= 0;
            ex_mem_mem_read <= 0;
            ex_mem_mem_write <= 0;
            ex_mem_is_syscall <= 0;
        end else if (flushM) begin
            ex_mem_reg_write <= 0;
            ex_mem_mem_read <= 0;
            ex_mem_mem_write <= 0;
            ex_mem_is_syscall <= 0;
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
            ex_mem_write_data <= forwardB_value;
            ex_mem_is_syscall <= id_ex_is_syscall;
            ex_mem_syscall_v0 <= syscall_v0_E;
            ex_mem_syscall_a0 <= syscall_a0_E;
            ex_mem_mem_size <= id_ex_mem_size;
        end
    end

    // MEM Stage --------------------------------------------------------------------
    wire [31:0] data_memory_read_data;

    DataMemory data_memory (
        .clock(clock),
        .reset(reset),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .size(ex_mem_mem_size),
        .address(ex_mem_alu_result),
        .write_data(ex_mem_write_data),
        .debug_pc(ex_mem_pc),
        .read_data(data_memory_read_data)
    );

    // MEM/WB pipeline register -----------------------------------------------------
    reg [31:0] mem_wb_pc;
    reg [31:0] mem_wb_pc8;
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_read_data;
    reg [1:0] mem_wb_write_src_sel;
    reg mem_wb_mem_to_reg;
    reg mem_wb_is_syscall;
    reg [31:0] mem_wb_syscall_v0;
    reg [31:0] mem_wb_syscall_a0;

    // Syscall argument forwarding in MEM stage
    wire [31:0] syscall_v0_M = 
        (mem_wb_reg_write && mem_wb_dest == 5'd2) ? reg_write_dataW :
        ex_mem_syscall_v0;
    wire [31:0] syscall_a0_M = 
        (mem_wb_reg_write && mem_wb_dest == 5'd4) ? reg_write_dataW :
        ex_mem_syscall_a0;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            mem_wb_reg_write <= 0;
            mem_wb_is_syscall <= 0;
        end else begin
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_write_src_sel <= ex_mem_write_src_sel;
            mem_wb_dest <= ex_mem_dest;
            mem_wb_pc <= ex_mem_pc;
            mem_wb_pc8 <= ex_mem_pc8;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_read_data <= data_memory_read_data;
            mem_wb_is_syscall <= ex_mem_is_syscall;
            mem_wb_syscall_v0 <= syscall_v0_M;
            mem_wb_syscall_a0 <= syscall_a0_M;
        end
    end

    // WB Stage ---------------------------------------------------------------------
    always @(*) begin
        case (mem_wb_write_src_sel)
            `WRITE_SRC_ALU: reg_write_dataW = mem_wb_alu_result;
            `WRITE_SRC_MEM: reg_write_dataW = mem_wb_mem_read_data;
            `WRITE_SRC_PC8: reg_write_dataW = mem_wb_pc8;
            default:        reg_write_dataW = mem_wb_alu_result;
        endcase
        reg_write_addrW = mem_wb_dest;
        reg_writeW = mem_wb_reg_write;
    end

    // Syscall handling
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            halted <= 1'b0;
        end else if (mem_wb_is_syscall && !halted) begin
            if (mem_wb_syscall_v0 == 32'd10) begin // Exit
                halted <= 1'b1;
                $display("\n==== Simulation finished via syscall 10 (Exit) at PC %h ====", mem_wb_pc);
                $finish;
            end else if (mem_wb_syscall_v0 == 32'd1) begin // Print Int
                $display("[SYSCALL] Print Int: %0d", mem_wb_syscall_a0);
            end else begin
                $display("[SYSCALL] Unknown syscall %0d at PC %h", mem_wb_syscall_v0, mem_wb_pc);
            end
        end
    end
    
    // Force pipeline flush when halted to prevent infinite loop of last instruction
    always @(posedge clock) begin
        if (halted) begin
            if_id_instr <= NOP_INSTR;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_branch <= 1'b0;
            id_ex_jump <= 1'b0;
        end
    end

endmodule
