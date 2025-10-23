.data
prompt_n: .asciiz "Please input n (array length):\n"
newline: .asciiz "\n"
str_true: .asciiz "True\n"
str_false: .asciiz "False\n"

.text
.globl main
main:
    # print prompt
    li $v0, 4
    la $a0, prompt_n
    syscall

    # read n into $t0
    li $v0, 5
    syscall
    move $t0, $v0

    # TODO: 为简单起见，在内存中为数组分配空间或使用寄存器循环读取并更新最远可达位置

    # 退出
    li $v0, 10
    syscall

# 提示：实现贪心算法，维护 furthest 变量（寄存器或内存），每读一个元素更新 furthest=max(furthest, index + A[index])，并判断是否能到达最后一个下标。