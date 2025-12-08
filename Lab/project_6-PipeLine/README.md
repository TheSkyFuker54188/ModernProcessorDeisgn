# Lab 6 – 五级流水线 MIPS CPU

本目录包含实验 6 需要提交的全部 Verilog 源文件、测试平台以及运行说明。顶层模块 `PipelineTop` 组织 IF/ID/EX/MEM/WB 五级流水、旁路转发与阻塞逻辑，`docs/pipeline-10inst.md` 则是助教提供的实验指导。

## 目录结构

```
Lab/project_6-PipeLine/
├── docs/                     # 实验要求
├── src/                      # 所有可综合模块
│   ├── cpu_defs.vh           # 宏定义/常量
│   ├── ProgramCounter_simple.v
│   ├── InstructionMemory.v   # 自动以 BASE_ADDR=0x3000 为起始地址
│   ├── DataMemory.v
│   ├── RegisterFile.v        # 写寄存器时自动打印 @PC: $id <= data
│   ├── ArithmeticLogicUnit.v
│   ├── Controller.v          # 输出 uses_rs/uses_rt 供 hazard 单元使用
│   ├── HazardDetectionUnit.v
│   ├── ForwardingUnit.v
│   └── PipelineTop.v
├── pipeline_tb.v             # 通用 testbench（可选 VCD dump）
├── code.txt                  # 示例程序（十六进制，自动映射到 0x3000）
└── project_6.*               # Vivado 产生的工程文件
```

## 仿真运行方法

### 1. Icarus Verilog（推荐命令行）
```powershell
cd D:\PROGRAMMING\ModernProcessorDeisgn\Lab\project_6-PipeLine
iverilog -g2012 -DDUMP_VCD -o pipeline_sim pipeline_tb.v src\*.v
vvp pipeline_sim | Tee-Object sim_output.log
```
- `-DDUMP_VCD` 会让 `pipeline_tb.v` 生成 `pipeline.vcd`，便于在 GTKWave 中查看波形。
- 仿真结束后，输出文件 `sim_output.log` 中会出现寄存器/内存写入日志（格式 `@PC: $id <= value` / `@PC: *addr <= value`）以及 testbench 的停止信息。

### 2. Vivado (xsim)
```powershell
cd D:\PROGRAMMING\ModernProcessorDeisgn\Lab\project_6-PipeLine
xvlog -sv src\*.v pipeline_tb.v
xelab pipeline_tb -s pipeline_sim
xsim pipeline_sim -run all | Tee-Object sim_output.log
```
- 若你更习惯 Vivado GUI，也可以新建仿真项目并导入同样的文件。
- XSIM 支持 `write_vcd` / `log_wave` 等命令，可在需要时启用波形记录。

## 与 Mars 输出对比
1. 使用带日志的 Mars（题目提供的 `Mars.jar`）运行你的汇编程序：
   ```powershell
   java -jar D:\PROGRAMMING\ModernProcessorDeisgn\Mars.jar db nc 500 ae2 mc CompactDataAtZero your_program.asm > mars_output.log
   ```
   - `db`：启用分支延迟槽（必须开启）。
   - `mc CompactDataAtZero`：与本 Verilog 实现一致的数据布局。

2. 将 Mars 与仿真生成的日志逐行比较：
   ```powershell
   Compare-Object \
       (Get-Content .\sim_output.log) \
       (Get-Content .\mars_output.log) \
       | Out-File diff.log
   ```
   或直接使用 `fc sim_output.log mars_output.log`。按照实验指导，**第一处不一致的行就是需要排查的流水线 bug**。

3. 成功标志：
   - 控制台输出中包含与实验文档相同格式的写寄存器/写内存日志。
   - 与 Mars 的输出完全一致（无差异行）。
   - testbench 显示 `Testbench detected halt at cycle N`，表明流水线在 syscall 处正常停止。

## 调试提示
- 若需要观察旁路/阻塞，可在 `PipelineTop.v` 的相关 always 块加入临时 `$display`，或在波形中查看 `stallF/stallD/forwardAE/forwardBE` 等信号。
- `HazardDetectionUnit.v` 只负责 load-use 冲突；若需要扩展其它 hazard，只需在该模块中增加条件即可。
- `InstructionMemory` 会把 `code.txt` 自动映射到 0x3000 起始地址；如果你用其它 ASM，请通过 Mars 生成新的十六进制文件覆盖 `code.txt`。
- 当仿真卡死时，首先检查是否未触发 `syscall`、或 load-use hazard 未正确插入气泡导致流水线被阻塞。

祝实验顺利，如需进一步说明，可参考 `docs/pipeline-10inst.md` 中的建议。