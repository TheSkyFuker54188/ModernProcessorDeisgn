.data
# 无需数据段，除非在调试时为 a,b 赋值或输出中间变量

.text
.globl main
main:
    # 约定：a -> $s0, b -> $s1, i -> $t0, j -> $t1, D(base) -> $s2

    # TODO: 在自行调试时可以在这里为 $s0,$s1 赋值，例如：
    # li $s0, 3
    # li $s1, 4
    # la $s2, data_array

    # 初始化 i = 0
    li $t0, 0
outer_loop:
    # if i >= a goto end_outer
    bge $t0, $s0, end_outer

    # 初始化 j = 0
    li $t1, 0
inner_loop:
    # if j >= b goto end_inner
    bge $t1, $s1, end_inner

    # compute i + j -> $t2
    addu $t2, $t0, $t1

    # compute address offset = 4 * j
    sll $t3, $t1, 2
    addu $t4, $s2, $t3   # address = base + 4*j

    # store i+j into memory at address (word store)
    sw $t2, 0($t4)

    # j++
    addi $t1, $t1, 1
    j inner_loop
end_inner:
    # i++
    addi $t0, $t0, 1
    j outer_loop
end_outer:
    li $v0, 10
    syscall

# 可在 .data 部分添加 data_array: .space 400  供调试使用（提交时请移除或注释赋值语句）。