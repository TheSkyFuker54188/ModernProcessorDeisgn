# 50-Instruction MIPS CPU Test Code (Debug Version)
.text 0x3000
.globl main

main:
    # ==========================================
    # 1. Immediate Operations
    # ==========================================
    addi  $k0, $zero, 1         # Debug: Test 1
    addi  $t0, $zero, 10
    addiu $t1, $zero, 20
    andi  $t2, $t0, 0x0F
    ori   $t3, $t0, 0xF0
    xori  $t4, $t0, 0xFF
    lui   $t5, 0x1234
    slti  $t6, $t0, 20
    sltiu $t7, $t0, 5

    # ==========================================
    # 2. Register ALU Operations
    # ==========================================
    addi  $k0, $zero, 2         # Debug: Test 2
    add   $s0, $t0, $t1
    addu  $s1, $t0, $t1
    sub   $s2, $t1, $t0
    subu  $s3, $t1, $t0
    and   $s4, $t3, $t4
    or    $s5, $t3, $t4
    xor   $s6, $t3, $t4
    nor   $s7, $t0, $zero
    slt   $t8, $t0, $t1
    sltu  $t9, $s7, $t0

    # ==========================================
    # 3. Shift Operations
    # ==========================================
    addi  $k0, $zero, 3         # Debug: Test 3
    sll   $a0, $t0, 2
    sra   $a1, $s7, 2
    sllv  $a2, $t0, $t1
    srav  $a3, $s7, $t0

    # ==========================================
    # 4. Multiplication & Division (MDU)
    # ==========================================
    addi  $k0, $zero, 4         # Debug: Test 4
    mult  $t0, $t1
    mflo  $k0
    mfhi  $k1
    
    div   $t1, $t0
    mflo  $k0
    mfhi  $k1
    
    addi  $at, $zero, 100
    mthi  $at
    mtlo  $at
    mfhi  $v0
    mflo  $v1

    # ==========================================
    # 5. Memory Access
    # ==========================================
    addi  $k0, $zero, 5         # Debug: Test 5
    addi  $sp, $zero, 0x100
    
    sw    $s0, 0($sp)
    lw    $t0, 0($sp)
    
    sh    $s0, 4($sp)
    lh    $t1, 4($sp)
    lhu   $t2, 4($sp)
    
    sb    $s0, 8($sp)
    lb    $t3, 8($sp)
    lbu   $t4, 8($sp)

    # ==========================================
    # 6. Branch & Jump
    # ==========================================
    addi  $k0, $zero, 6         # Debug: Test 6
    beq   $s0, $s0, label_beq
    nop
    addi  $k1, $zero, 0x61      # Fail code 6.1
    j     fail
    nop
label_beq:
    bne   $s0, $zero, label_bne
    nop
    addi  $k1, $zero, 0x62      # Fail code 6.2
    j     fail
    nop
label_bne:
    blez  $zero, label_blez
    nop
    addi  $k1, $zero, 0x63      # Fail code 6.3
    j     fail
    nop
label_blez:
    bgtz  $s0, label_bgtz
    nop
    addi  $k1, $zero, 0x64      # Fail code 6.4
    j     fail
    nop
label_bgtz:
    bltz  $s7, label_bltz
    nop
    addi  $k1, $zero, 0x65      # Fail code 6.5
    j     fail
    nop
label_bltz:
    bgez  $s0, label_bgez
    nop
    addi  $k1, $zero, 0x66      # Fail code 6.6
    j     fail
    nop
label_bgez:

    # Jump and Link Test
    addi  $k0, $zero, 7         # Debug: Test 7
    jal   my_func
    nop                         # Delay slot
    
    # Should return here
    j     end_test
    nop                         # Delay slot

my_func:
    jr    $ra
    nop                         # Delay slot

    # Buffer to prevent fall-through confusion
    nop
    nop
    nop
    nop

fail:
    # Loop here if failed
    # $k0 holds test number, $k1 holds fail code
    j     fail
    nop

    # Buffer
    nop
    nop
    nop
    nop

end_test:
    # ==========================================
    # 7. Syscall
    # ==========================================
    # Print Integer (1)
    ori   $v0, $zero, 1
    ori   $a0, $zero, 2024
    syscall
    
    # Exit (10)
    ori   $v0, $zero, 10
    syscall
