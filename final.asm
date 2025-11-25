
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