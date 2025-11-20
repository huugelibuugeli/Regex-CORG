
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
	b backward_slash