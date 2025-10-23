.data
prompt_n: .asciiz "Please input n (non-negative integer):\n"
newline: .asciiz "\n"

.text
.globl main
main:
    # print prompt
    li $v0, 4
    la $a0, prompt_n
    syscall

    # read n
    li $v0, 5
    syscall
    move $t0, $v0   # t0 = n

    # TODO: 如果 n == 0 或 n == 1，直接输出 1；否则使用迭代计算 F(n)
    # 示例：输出 current value
    # li $v0, 1; move $a0, $t1; syscall

    li $v0, 10
    syscall

# 提示：在 MIPS 中用迭代方式计算斐波那契，保存 prev (F(k-2)) 和 cur (F(k-1))，从 k=2 循环到 n 计算。