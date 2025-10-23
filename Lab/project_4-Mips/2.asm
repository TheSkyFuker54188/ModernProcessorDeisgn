.data
newline: .asciiz "\n"

.text
.globl main
main:
    # 读取 n（单个整数）
    li   $v0, 5
    syscall
    move $t0, $v0         # t0 = n

    # 若 n <= 1，则 F(n) = 1
    li   $t1, 1
    slt  $t2, $t1, $t0    # t2 = 1 if (1 < n)
    beq  $t2, $zero, print_one

    # 迭代：prev=F(0)=1, cur=F(1)=1，从 i=2 计算到 n
    li   $t3, 1           # t3 = prev
    li   $t4, 1           # t4 = cur
    li   $t5, 2           # t5 = i
fib_loop:
    # if (i > n) 结束
    bgt  $t5, $t0, fib_done

    # next = prev + cur
    addu $t6, $t3, $t4
    # prev = cur; cur = next
    move $t3, $t4
    move $t4, $t6
    addi $t5, $t5, 1
    j    fib_loop

fib_done:
    # 输出 cur
    li   $v0, 1
    move $a0, $t4
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall
    j    exit

print_one:
    li   $v0, 1
    li   $a0, 1
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall

exit:
    li   $v0, 10
    syscall