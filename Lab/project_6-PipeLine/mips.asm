# Compact comprehensive test for pipeline (covers ALU, load/store, branch, call/return, load-use)
    .text
    .org 0x00003000
start:
    addi $t0, $zero, 5    # $8 = 5
    addi $t1, $zero, 2    # $9 = 2
    addu $t2, $t0, $t1    # $10 = 7
    sw   $t2, 0($zero)    # mem[0] = 7
    lw   $t3, 0($zero)    # $11 = 7
    ori  $s0, $t3, 0x00FF # $16 = 7 | 0x00FF

    # Load-use hazard: load then use immediately
    sw   $t1, 4($zero)    # mem[4] = 2
    lw   $t4, 4($zero)    # $12 = 2
    addu $t5, $t4, $t1    # $13 = $12 + $9 (load-use)

    # Branch with delay slot
    addi $t6, $zero, 1    # delay-slot instruction (executes regardless)
    beq  $t5, $zero, skip # branch likely not taken
    nop
skip:

    # Call and return
    jal  func             # $31 = return addr, jump to func
    addi $v0, $zero, 10   # syscall code in delay slot
    syscall

func:
    addi $a0, $zero, 3
    jr   $ra
    nop
