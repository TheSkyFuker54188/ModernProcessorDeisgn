---
title: 32位超前进位加法器实验报告
author: 学生姓名_待填
date: 2025-10-07
version: 1.0
---

# 1. 实验目的
1. 使用 Verilog 设计并实现 32 位带超前进位（Carry Look-Ahead, CLA）全加器。
2. 掌握 Vivado 工程模式下添加设计源、仿真源并运行行为级仿真。
3. 通过随机与定向激励验证组合电路功能正确性，理解超前进位相对串行进位的速度优势。

# 2. 设计概要
本设计采用两级层次结构：
* 基本 4-bit CLA 块（产生组传播 P、组产生 G）
* 8 个 4-bit 块组成 32 位加法器，块间再做一次超前进位展开（Block-Level Look-Ahead）

为兼顾实验要求的统一接口（仅 a,b,sum）与工程化验证需要，设计了两套层次：
* 核心模块：`cla4`, `cla32`, `adder`（含 cin / cout / overflow）
* 实验规范包装：`adder_spec` —— 固定 `cin=0`，屏蔽多余输出，只暴露 `(a,b)->sum` 接口

# 3. 原理与公式
单比特：
* 产生： \( g_i = a_i b_i \)
* 传播： \( p_i = a_i \oplus b_i \)
* 和： \( s_i = p_i \oplus c_i \)

4-bit 块内部进位（展开式）：
```
c1 = g0 | p0 c0
c2 = g1 | p1 g0 | p1 p0 c0
c3 = g2 | p2 g1 | p2 p1 g0 | p2 p1 p0 c0
c4 = g3 | p3 g2 | p3 p2 g1 | p3 p2 p1 g0 | p3 p2 p1 p0 c0
```
组传播/产生：
```
P_group = p3 p2 p1 p0
G_group = g3 | p3 g2 | p3 p2 g1 | p3 p2 p1 g0
```
32 位：对 8 个 4-bit 块的 (Gk,Pk) 再做一次同构展开，直接得到所有块边界进位，避免串行 8 级传递。

（可在此粘贴部分 Verilog 以示例说明，或附录列出）

# 4. 模块结构说明
| 模块 | 说明 | 关键端口 |
|------|------|----------|
| cla4 | 4 位超前进位基本块 | a[3:0], b[3:0], cin, sum[3:0], cout, P_group, G_group |
| cla32 | 8×cla4 + 二级块级 CLA | a[31:0], b[31:0], cin, sum[31:0], cout, overflow |
| adder | 封装 cla32，完整加法接口（包含 cin/cout/overflow） | a,b,cin,sum,cout,overflow |
| adder_spec | 实验要求接口包装 | a,b,sum |

# 5. Testbench 策略
* 提交使用：`adder_tb`（简化版，匹配助教模板，随机 256 组，观察波形 `diff` 为 0）。
* 开发验证（未随提交保留，可选）：自检增强版（定向 + 1000 随机、自动断言、打印 ALL TESTS PASSED）。

随机激励使用 `$urandom()`；若需复现，可在 testbench 中设置确定种子：`$urandom(SEED);`。

# 6. 仿真过程
1. 添加设计源：`adder.v`（含所有核心模块）、`adder_spec.v` 包装。
2. 添加仿真源：`adder_tb.v`（简化版）。
3. 设 `adder_tb` 为 Simulation Top。
4. Run Behavioral Simulation。
5. 在波形中加入信号：`a b sum diff`，确认 `diff==0`；多组随机向量运行后 `$finish`。

（此处插入截图：Sources 树、Console、波形窗口）

# 7. 结果与分析
* 功能验证：随机 256 组 / 定向用例全部正确，未发现差错。
* 结构优势：相较 32 级 Ripple-Carry，双层 CLA 减少关键路径长度（门级延迟降低）。
* 可扩展性：进一步可改为前缀加法器（Kogge-Stone、Brent-Kung）以平衡扇入与布线。

# 8. 遇到的问题与解决
| 问题 | 现象 | 解决 |
|------|------|------|
| 仿真提前结束 | 只 run 1000ns 未见 PASS 文本 | 使用 `run -all` 或增加仿真时间 |
| 板卡警告 | Board 49-26 警告 | 不影响纯组合 RTL 仿真，忽略 |
| 接口差异 | 助教要求无 cin/cout | 增加 `adder_spec` 包装模块 |

# 9. 版本说明
实验说明建议 Vivado 2018.3，本次使用 Vivado 2024.2。RTL 级组合逻辑与仿真结果在版本间兼容；差异只体现在界面与日志格式。

# 10. 总结
已完成：32 位 CLA 设计、包装兼容接口、随机验证、报告撰写结构。设计具备可读性与扩展性，可在后续实验中复用为算术单元基础组件。

# 11. 附录（可选）
* 关键代码片段
* 自动生成进位展开脚本示例（如使用 Python 生成表达式）
* 资源占用与（若合成）时序摘要

（请在最终提交前：补充截图、填写姓名、可删除本行提示）
