.data
prompt_len: .asciiz "Length:\n"
prompt_wid: .asciiz "Width:\n"
prompt_hgt: .asciiz "Height:\n"
illegal: .asciiz "Illegal Input\n"
newline: .asciiz "\n"

.text
.globl main
main:
    # 读取 length -> $t0, 要求 > 0
read_len:
    li $v0, 4
    la $a0, prompt_len
    syscall
    li $v0, 5
    syscall
    move $t0, $v0
    blez $t0, len_invalid
    j read_width
len_invalid:
    li $v0, 4
    la $a0, illegal
    syscall
    j read_len

    # 读取 width -> $t1, 要求 > 0
read_width:
    li $v0, 4
    la $a0, prompt_wid
    syscall
    li $v0, 5
    syscall
    move $t1, $v0
    blez $t1, wid_invalid
    j read_height
wid_invalid:
    li $v0, 4
    la $a0, illegal
    syscall
    j read_width

    # 读取 height -> $t2, 要求 > 0
read_height:
    li $v0, 4
    la $a0, prompt_hgt
    syscall
    li $v0, 5
    syscall
    move $t2, $v0
    blez $t2, hgt_invalid
    j compute
hgt_invalid:
    li $v0, 4
    la $a0, illegal
    syscall
    j read_height

    # 计算体积与表面积
compute:
    # volume = t0 * t1 * t2  -> use t3 as temp
    mul $t3, $t0, $t1
    mul $t3, $t3, $t2

    # surface = 2*(t0*t1 + t0*t2 + t1*t2)
    mul $t4, $t0, $t1   # t4 = t0*t1
    mul $t5, $t0, $t2   # t5 = t0*t2
    mul $t6, $t1, $t2   # t6 = t1*t2
    addu $t7, $t4, $t5
    addu $t7, $t7, $t6  # t7 = t4 + t5 + t6
    sll $t7, $t7, 1     # t7 = 2 * ( ... )

    # 输出 volume (一行)
    li $v0, 1
    move $a0, $t3
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # 输出 surface (一行)
    li $v0, 1
    move $a0, $t7
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # 退出
    li $v0, 10
    syscall