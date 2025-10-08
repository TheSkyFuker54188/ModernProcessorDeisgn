录屏

[http://10.77.110.159/Vivado/%E5%A4%84%E7%90%86%E5%99%A8%E8%AE%BE%E8%AE%A1/%E5%AE%9E%E9%AA%8C2.mp4](http://10.77.110.159/Vivado/%E5%A4%84%E7%90%86%E5%99%A8%E8%AE%BE%E8%AE%A1/%E5%AE%9E%E9%AA%8C2.mp4)

ALU（Arithmetic Logic Unit，算术逻辑单元）是 CPU 的重要组成部分，也是承担运算任务的主要部分。在 CPU 工作时，ALU 会根据控制电路解码出的操作码（Operation Code）与获取到的源操作数（Oprands）来计算结果。该结果会由后续的电路使用或保存。

请根据实验指导中的要求来设计并仿真验证 ALU 元件（本次实验与最终 CPU 设计相独立，但最好保持Opcode一致，不然可能要完全重写）。

本次实验希望大家体验多文件项目，请提交以下文件：

1. ALU 模块（调用全加器模块完成加法）
2. 全加器模块（使用第一次实验的超前进位加法器，或者简单的一行加法）
3. 实验报告

注意：ALU 是一个纯粹的组合逻辑电路，不涉及到时序部分。请注意 always @ (*) 语句的使用，并尝试检查编写的代码编译综合后生成的电路中是否有寄存器（REG）或锁存器（LATCH）。

清华组成原理课程verilog简单教程 [https://lab.cs.tsinghua.edu.cn/cod-lab-docs/labs/verilog/](https://lab.cs.tsinghua.edu.cn/cod-lab-docs/labs/verilog/)

Verilog数字系统设计教程第二版-夏宇闻.pdf 在课件里
