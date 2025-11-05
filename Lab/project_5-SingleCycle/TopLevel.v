`timescale 1ns/1ps
`include "cpu_defs.vh"

module TopLevel (
    input wire reset,
    input wire clock,
    output reg halted
);
    // Windows 路径请使用双反斜杠 \\
    localparam IMEM_INIT_FILE   = "D:\\PROGRAMMING\\ModernProcessorDeisgn\\Lab\\project_5-SingleCycle\\code.txt";
    // 可选：期望数据内存（从 MARS 导出的十六进制文本），用于自动对比
    localparam DM_EXPECT_FILE   = "D:\\PROGRAMMING\\ModernProcessorDeisgn\\Lab\\project_5-SingleCycle\\dm_expected.txt"; // 若不需要自动对比，可设为空串
    localparam integer CMP_WORDS = 64;   // 比对多少个连续 word（用于自动对比）
    localparam integer EXPECT_DEPTH = 1024; // 期望数组深度（需与 $readmemh 加载容量一致）
    localparam integer MAX_MISMATCH_PRINT = 5;  // 打印的最大差异条目数（精简）
    // 调试输出控制（提交版本默认关闭，若需要可在仿真时定义 SIM_DEBUG 来启用）
    localparam integer DEBUG_PRINT_DM_WORDS = 0;        // syscall 时打印 DataMemory 的 word 数（0=不打印）
    localparam integer DEBUG_PRINT_SW_MAX  = 12;        // 仅记录前若干条针对低地址的 SW

    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] instruction;
    wire [31:0] pc_plus4;

    ProgramCounter pc_reg (
        .clock(clock),
        .reset(reset),
        .next_pc(pc_next),
        .current_pc(pc_current)
    );

    InstructionMemory #(
        .INIT_FILE(IMEM_INIT_FILE)
    ) instruction_memory (
        .address(pc_current),
        .instruction(instruction)
    );

    wire [5:0] opcode = instruction[31:26];
    wire [4:0] rs = instruction[25:21];
    wire [4:0] rt = instruction[20:16];
    wire [4:0] rd = instruction[15:11];
    wire [5:0] funct = instruction[5:0];
    wire [15:0] immediate = instruction[15:0];

    wire [1:0] reg_dst_sel;
    wire [1:0] reg_write_data_sel;
    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire branch;
    wire jump;
    wire jump_reg;
    wire use_zero_extend;
    wire is_syscall;
    wire [3:0] alu_control;

    Controller controller (
        .opcode(opcode),
        .funct(funct),
        .reg_dst_sel(reg_dst_sel),
        .reg_write_data_sel(reg_write_data_sel),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .jump_reg(jump_reg),
        .use_zero_extend(use_zero_extend),
        .is_syscall(is_syscall),
        .alu_control(alu_control)
    );

    wire [31:0] reg_data1;
    wire [31:0] reg_data2;
    wire [4:0] reg_write_addr;
    wire [31:0] reg_write_data;
    wire reg_write_enable;

    assign reg_write_enable = reg_write && !is_syscall;

    assign reg_write_addr = (reg_dst_sel == 2'b00) ? rt :
                            (reg_dst_sel == 2'b01) ? rd :
                            `REG_RA;

    RegisterFile register_file (
        .clock(clock),
        .reset(reset),
        .reg_write(reg_write_enable),
        .read_addr1(rs),
        .read_addr2(rt),
        .write_addr(reg_write_addr),
        .write_data(reg_write_data),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    wire [31:0] sign_extended_imm = {{16{immediate[15]}}, immediate};
    wire [31:0] zero_extended_imm = {16'b0, immediate};
    wire [31:0] selected_imm = use_zero_extend ? zero_extended_imm : sign_extended_imm;
    wire [31:0] lui_value = {immediate, 16'b0};

    wire [31:0] alu_operand_b = alu_src ? selected_imm : reg_data2;
    wire [31:0] alu_result;
    wire alu_zero;

    ArithmeticLogicUnit alu (
        .operand_a(reg_data1),
        .operand_b(alu_operand_b),
        .control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );

    wire [31:0] data_memory_read_data;

    DataMemory data_memory (
        .clock(clock),
        .reset(reset),
        .mem_read(mem_read && !is_syscall),
        .mem_write(mem_write && !is_syscall),
        .address(alu_result),
        .write_data(reg_data2),
        .read_data(data_memory_read_data)
    );

    reg [31:0] reg_write_data_reg;
    always @(*) begin
        case (reg_write_data_sel)
            2'b00: reg_write_data_reg = alu_result;
            2'b01: reg_write_data_reg = data_memory_read_data;
            2'b10: reg_write_data_reg = pc_plus4;
            2'b11: reg_write_data_reg = lui_value;
            default: reg_write_data_reg = alu_result;
        endcase
    end
    assign reg_write_data = reg_write_data_reg;

    assign pc_plus4 = pc_current + 32'd4;

    wire [31:0] branch_target = pc_plus4 + (sign_extended_imm << 2);
    wire branch_taken = branch && alu_zero;

    wire [31:0] jump_target = {pc_plus4[31:28], instruction[25:0], 2'b00};

    wire [31:0] pc_after_branch = branch_taken ? branch_target : pc_plus4;
    wire [31:0] pc_after_jump = jump ? jump_target : pc_after_branch;

    assign pc_next = jump_reg ? reg_data1 : pc_after_jump;

    // 自动对比相关
    integer dm_i, fd, expected_loaded;
    reg [31:0] dm_expected [0:1023];
    // 对比用变量（提前声明，避免在语句块中声明）
    integer cmp_mismatches, cmp_printed, cmp_idx;
    integer cmp_off, cmp_best_off, cmp_best_mism, cmp_j;
    // 调试计数器
    integer dbg_sw_count;

    // 在仿真启动时尝试加载期望 DataMemory
    initial begin
        expected_loaded = 0;
        if (DM_EXPECT_FILE != "") begin
            fd = $fopen(DM_EXPECT_FILE, "r");
            if (fd != 0) begin
                $fclose(fd);
                $display("Loading expected DataMemory from %s", DM_EXPECT_FILE);
                $readmemh(DM_EXPECT_FILE, dm_expected);
                expected_loaded = 1;
            end else begin
                $display("[AutoCompare] Expected file not found: %s, skip auto compare.", DM_EXPECT_FILE);
            end
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            halted <= 1'b0;
            dbg_sw_count <= 0;
        end else begin
            // 调试：只记录写往低地址（DM[0..4]）的 SW，且限前 DEBUG_PRINT_SW_MAX 条
            `ifdef SIM_DEBUG
            if (mem_write && (alu_result[11:2] < 5) && (dbg_sw_count < DEBUG_PRINT_SW_MAX)) begin
                $display("[SW] PC=%h instr=%h addr=%h (word=%0d) data=%h", pc_current, instruction, alu_result, alu_result[11:2], reg_data2);
                dbg_sw_count <= dbg_sw_count + 1;
            end
            `endif
            if (is_syscall && !halted) begin
                halted <= 1'b1;
                $display("\n==== Simulation finished via syscall at PC %h ====", pc_current);
                // 可选：打印 DataMemory 前若干 word（默认关闭，避免输出过长）
                `ifdef SIM_DEBUG
                if (DEBUG_PRINT_DM_WORDS > 0) begin
                    for (dm_i = 0; dm_i < DEBUG_PRINT_DM_WORDS; dm_i = dm_i + 1) begin
                        $display("DM[%0d] = 0x%08h", dm_i, data_memory.memory[dm_i]);
                    end
                end
                `endif

                // 自动对比（若已加载期望数据）：滑动窗口匹配，寻找最小差异的对齐偏移
                if (expected_loaded) begin
                    cmp_best_mism = CMP_WORDS + 1;
                    cmp_best_off = 0;
                    for (cmp_off = 0; cmp_off <= (EXPECT_DEPTH - CMP_WORDS); cmp_off = cmp_off + 1) begin
                        cmp_mismatches = 0;
                        for (cmp_idx = 0; cmp_idx < CMP_WORDS; cmp_idx = cmp_idx + 1) begin
                            if (data_memory.memory[cmp_idx] !== dm_expected[cmp_off + cmp_idx]) begin
                                cmp_mismatches = cmp_mismatches + 1;
                            end
                        end
                        if (cmp_mismatches < cmp_best_mism) begin
                            cmp_best_mism = cmp_mismatches;
                            cmp_best_off = cmp_off;
                            if (cmp_best_mism == 0) begin
                                // 早停：完美匹配
                                // 注意：Verilog 无法从 for 中直接 break，这里通过条件提前判断
                            end
                        end
                    end
                    if (cmp_best_mism == 0) begin
                        $display("[AutoCompare] PASS: %0d words match expected starting at offset %0d.", CMP_WORDS, cmp_best_off);
                    end else begin
                        $display("[AutoCompare] BEST ALIGN: offset=%0d, mismatches=%0d/%0d.", cmp_best_off, cmp_best_mism, CMP_WORDS);
                        `ifdef SIM_DEBUG
                        $display("[AutoCompare] Showing up to %0d diffs:", MAX_MISMATCH_PRINT);
                        cmp_printed = 0;
                        for (cmp_j = 0; cmp_j < CMP_WORDS; cmp_j = cmp_j + 1) begin
                            if (data_memory.memory[cmp_j] !== dm_expected[cmp_best_off + cmp_j]) begin
                                if (cmp_printed < MAX_MISMATCH_PRINT) begin
                                    $display("  [Mismatch] DM[%0d]: got=0x%08h, exp@%0d=0x%08h", cmp_j, data_memory.memory[cmp_j], (cmp_best_off + cmp_j), dm_expected[cmp_best_off + cmp_j]);
                                    cmp_printed = cmp_printed + 1;
                                end
                            end
                        end
                        `endif
                    end
                end
                $finish;
            end
        end
    end
endmodule
