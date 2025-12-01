
parse_loop:
	#############################
	#loading next character to $t1
	#############################
	
	li $t2, 42 # asterisk ascii
	beq $t1, $t2, asterisk
	
	li $t2, 46 # period ascii
	beq $t1, $t2, period
	
	li $t2, 93 # backward square bracket ascii
	beq $t1, $t2, square_bracket
	
	li $t2, 92 # backward slash ascii
	beq $t1, $t2, backward_slash
	
	li $t2, 45 # dash ascii
	beq $t1, $t2, dash

	li $t2, 94 # caret ascii
	beq $t1, $t2, caret


asterisk:
	# code
	b parse_loop
	
period:
	# code
	b parse_loop

square_bracket:
	# code
	b parse_loop
	
backward_slash:
	#code
	b parse_loop

dash:
	# code
	b parse_loop

caret:
	#code
	b parse_loop

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