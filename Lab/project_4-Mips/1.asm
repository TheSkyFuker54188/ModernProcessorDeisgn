.data
# 提示字符串
prompt_len: .asciiz "Please input length (integer):\n"
prompt_wid: .asciiz "Please input width (integer):\n"
prompt_hgt: .asciiz "Please input height (integer):\n"
illegal: .asciiz "Illegal Input\n"
newline: .asciiz "\n"

.text
.globl main
main:
    # 示例：打印提示并读取整数
    # print prompt_len
    li $v0, 4
    la $a0, prompt_len
    syscall

    # read integer into $t0 (length)
    li $v0, 5
    syscall
    move $t0, $v0

    # 这里放置输入校验与重读逻辑
    # TODO: 如果 $t0 <= 0, 打印 illegal 并重新读取

    # 读取宽和高的示例（参考上面）
    # li $v0, 4; la $a0, prompt_wid; syscall
    # li $v0, 5; syscall; move $t1, $v0

    # 计算体积与表面积并输出（示例输出）
    # li $v0, 1; move $a0, $t0; syscall

    # 退出
    li $v0, 10
    syscall

# 注：在实现时请把具体计算和循环重读逻辑补入本文件中。