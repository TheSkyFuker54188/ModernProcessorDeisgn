.data
str_true:  .asciiz "True\n"
str_false: .asciiz "False\n"

.text
.globl main
main:
    # 读取 n
    li   $v0, 5
    syscall
    move $t0, $v0          # t0 = n

    # n <= 1 直接可达
    li   $t1, 1
    slt  $t2, $t1, $t0     # t2 = 1 if (1 < n)
    beq  $t2, $zero, print_true

    # 初始化 i=0, furthest=0
    move $t1, $zero        # t1 = i
    move $t3, $zero        # t3 = furthest

loop:
    # 若 i > furthest，无法继续
    bgt  $t1, $t3, print_false
    # 读 A[i]
    li   $v0, 5
    syscall
    move $t2, $v0          # t2 = A[i]

    # furthest = max(furthest, i + A[i])
    addu $t4, $t1, $t2     # t4 = i + A[i]
    slt  $t5, $t3, $t4     # t5 = 1 if furthest < t4
    beq  $t5, $zero, no_update
    move $t3, $t4
no_update:
    addi $t1, $t1, 1       # i++

    # 如果已读完 n 个元素，结束
    beq  $t1, $t0, done
    j    loop

done:
    # 检查 furthest 是否覆盖到 n-1
    addi $t4, $t0, -1      # t4 = n-1
    slt  $t5, $t3, $t4     # if furthest < n-1 -> False
    bne  $t5, $zero, print_false
    j    print_true

print_true:
    li   $v0, 4
    la   $a0, str_true
    syscall
    j    exit

print_false:
    li   $v0, 4
    la   $a0, str_false
    syscall
    j    exit

exit:
    li   $v0, 10
    syscall