.data
input1:     .asciiz "ab\."
input2:     .asciiz "ab.fasf"

tmp_input1: .space 128
output:     .space 128

.text
.globl main

main:
    li $t9, 0  # input1 index
    li $t8, 0  # tmp_input1 index
    j parse_loop

# -----------------------------
# instruction parse loop
# -----------------------------
parse_loop:
    la $t2, input1
    add $t2, $t2, $t9
    lb $t1, 0($t2)

    # backward slash
    li $t2, 92
    beq $t1, $t2, backward_slash

    li $t2, 42
    beq $t1, $t2, asterisk

    li $t2, 46
    beq $t1, $t2, period

    li $t2, 93
    beq $t1, $t2, square_bracket

    li $t2, 45
    beq $t1, $t2, dash

    li $t2, 94
    beq $t1, $t2, caret

    beq $t1, $zero, equality   # end of input1 triggers equality

    # store literal character
    la $t2, tmp_input1
    add $t2, $t2, $t8
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    la $t2, tmp_input1
    add $t2, $t2, $t8
    sb $zero, 0($t2)

    addi $t9, $t9, 1
    j parse_loop

backward_slash:
    addi $t9, $t9, 1
    la $t2, input1
    add $t2, $t2, $t9
    lb $t1, 0($t2)

    # store literal after backslash
    la $t2, tmp_input1
    add $t2, $t2, $t8
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    la $t2, tmp_input1
    add $t2, $t2, $t8
    sb $zero, 0($t2)

    addi $t9, $t9, 1
    j parse_loop

# -----------------------------
# equality check (match from start of input2)
# -----------------------------
equality:
    li $t3, 0           # tmp_input1 index
    li $t4, 0           # input2 index

eq_loop:
    la $t2, tmp_input1
    add $t2, $t2, $t3
    lb $a0, 0($t2)
    beq $a0, $zero, eq_done   # end of tmp_input1 => done

    la $t5, input2
    add $t5, $t5, $t4
    lb $a1, 0($t5)
    beq $a1, $zero, eq_done   # end of input2 => done

    bne $a0, $a1, eq_done     # mismatch => done

    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j eq_loop

eq_done:
    # print matched portion
    li $t0, 0
print_loop:
    beq $t0, $t3, program_end
    la $t2, tmp_input1
    add $t2, $t2, $t0
    lb $a0, 0($t2)
    li $v0, 11
    syscall
    addi $t0, $t0, 1
    j print_loop

# -----------------------------
# operator placeholders (skeleton intact)
# -----------------------------
asterisk:
    add $t8, $zero, $t9
    #j parse_loop

period:
    #j parse_loop

square_bracket:
    #j parse_loop

dash:
    #j parse_loop

caret:
    #j parse_loop

print_match:
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $t0, 8($sp)
    sw   $t1, 4($sp)
    sw   $t2, 0($sp)

    # If not first match, print ", "
    beq  $a3, $zero, pm_no_sep

    la   $a0, comma_space
    li   $v0, 4          # print_string
    syscall

pm_no_sep:
    # t0 = base address of input string
    move $t0, $a0
    # t1 = current index (start)
    move $t1, $a1
    # t2 = remaining length
    move $t2, $a2

pm_loop:
    beq  $t2, $zero, pm_done   # len == 0 -> done

    add  $t3, $t0, $t1         # addr = base + index
    lb   $a0, 0($t3)           # load char
    li   $v0, 11               # print_char
    syscall

    addi $t1, $t1, 1           # index++
    addi $t2, $t2, -1          # len--
    j    pm_loop

pm_done:
    # restore
    lw   $t2, 0($sp)
    lw   $t1, 4($sp)
    lw   $t0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra