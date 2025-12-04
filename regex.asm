# Name: Zora Djuric, Hugo Shamberger, Dwayne Johnson
# CS 35101 Computer Organization
# Project: FinalFinalFinal(regex.asm)
# Date: 12/04/2025
#
# Description:
# This program reads a regex pattern and a text string, then finds
# all non-overlapping matches.
# Supports:
#   .       (wildcard for any char)
#   * (matches preceding element 1 or more times)
#   [abc]   (character classes)
#   [a-z]   (character ranges)
#   [^...]  (negated classes)
#   \       (escape character)
.data
prompt1:     .asciiz "Enter search pattern: "
prompt2:     .asciiz "Enter search text: "
input1:      .space 128          # pattern buffer
input2:      .space 128          # text buffer
tmp_input1:  .space 128          # parsed pattern buffer (handles escapes)
comma_space: .asciiz ", "

.text
.globl main

main:
    # read pattern input1
    li   $v0, 4
    la   $a0, prompt1
    syscall

    li   $v0, 8           # read_string
    la   $a0, input1
    li   $a1, 128
    syscall

    la   $a0, input1
    jal  strip_newline

    # check if empty pattern (user wants to exit)
    la   $t0, input1
    lb   $t1, 0($t0)
    beq  $t1, $zero, program_end

    # read text input2
    li   $v0, 4
    la   $a0, prompt2
    syscall

    li   $v0, 8
    la   $a0, input2
    li   $a1, 128
    syscall

    # strip newline from input2
    la   $a0, input2
    jal  strip_newline

    # parse pattern into tmp_input1
    li $t9, 0  # input1 index
    li $t8, 0  # tmp_input1 index
    j parse_loop

# parse loop - check each char for special handling
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

    li $t2, 91
    beq $t1, $t2, open_bracket

    li $t2, 93
    beq $t1, $t2, close_bracket

    li $t2, 45
    beq $t1, $t2, dash

    li $t2, 94
    beq $t1, $t2, caret

    beq $t1, $zero, parse_done   # end of input1 triggers parsing done

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

# done parsing - null terminate tmp_input1
parse_done:
    la   $t2, tmp_input1
    add  $t2, $t2, $t8
    sb   $zero, 0($t2)

    # Scan input2 for matches
    # For each start index i in input2:
    #   len = match_at(input2, tmp_input1, i)
    #   if len > 0: print_match(input2, i, len, printed_before)
    li   $s1, 0           # printed_before flag (0 = first match)
    li   $s0, 0           # current start index in input2

scan_loop:
    la   $t2, input2
    add  $t2, $t2, $s0
    lb   $t3, 0($t2)
    beq  $t3, $zero, scan_done  # end of text

    # try matching at this position
    la   $a0, input2 # text base
    la   $a1, tmp_input1 # pattern base
    move $a2, $s0 # start index
    jal  match_at
    move $t4, $v0 # t4 = match length

    beq  $t4, $zero, no_match_here

    # found match - print it
    la   $a0, input2 # base of text
    move $a1, $s0         # start index
    move $a2, $t4         # length
    move $a3, $s1         # printed_before flag
    jal  print_match

    li   $s1, 1           # printed at least one
    add  $s0, $s0, $t4    # skip past matched chars
    j    scan_loop

no_match_here:
    addi $s0, $s0, 1      # next start index
    j    scan_loop

scan_done:
    li   $v0, 11
    li   $a0, 10
    syscall

    j    main             # loop back for another input

program_end:
    li   $v0, 10
    syscall

# operator handlers - store chars in tmp_input1
asterisk:
    # Store '*' as-is in parsed pattern (for match_at to handle)
    la $t2, tmp_input1
    add $t2, $t2, $t8
    li $t1, 42            # '*'
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    addi $t9, $t9, 1
    j parse_loop

period:
    # Store ANY token for '.'
    la $t2, tmp_input1
    add $t2, $t2, $t8
    li $t1, -1            # ANY token (0xFF)
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    addi $t9, $t9, 1
    j parse_loop

open_bracket:
    # Store '[' as-is
    la $t2, tmp_input1
    add $t2, $t2, $t8
    li $t1, 91            # '['
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    addi $t9, $t9, 1
    j parse_loop

close_bracket:
    # Store ']' as-is
    la $t2, tmp_input1
    add $t2, $t2, $t8
    li $t1, 93            # ']'
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    addi $t9, $t9, 1
    j parse_loop

dash:
    # Store '-' as-is
    la $t2, tmp_input1
    add $t2, $t2, $t8
    li $t1, 45            # '-'
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    addi $t9, $t9, 1
    j parse_loop

caret:
    # Store '^' as-is
    la $t2, tmp_input1
    add $t2, $t2, $t8
    li $t1, 94            # '^'
    sb $t1, 0($t2)
    addi $t8, $t8, 1
    addi $t9, $t9, 1
    j parse_loop

# strip_newline - replace \n or \r with null
strip_newline:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $t0, 0($sp)

    move $t0, $a0         # t0 = current pointer

sn_loop:
    lb   $t1, 0($t0)
    beq  $t1, $zero, sn_done

    li   $t2, 10          # '\n'
    beq  $t1, $t2, sn_terminate

    li   $t2, 13          # '\r'
    beq  $t1, $t2, sn_terminate

    addi $t0, $t0, 1
    j    sn_loop

sn_terminate:
    sb   $zero, 0($t0)

sn_done:
    lw   $t0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra


# match_at - returns match length or 0
# args: $a0=text, $a1=pattern, $a2=start index
# supports: literals, . (any), [...] char class, [^...] negation, * (one or more)
match_at:
    addi $sp, $sp, -28
    sw   $ra, 24($sp)
    sw   $s0, 20($sp)
    sw   $s1, 16($sp)
    sw   $s2, 12($sp)
    sw   $s3, 8($sp)
    sw   $s4, 4($sp)
    sw   $s5, 0($sp)

    move $s0, $a0         # text base
    move $s1, $a1         # pattern base
    move $s2, $a2         # text index
    li   $s3, 0           # pattern index
    li   $s4, 0           # match length (chars matched in text)

match_loop:
    # get pattern char
    add  $t0, $s1, $s3
    lb   $t1, 0($t0)
    beq  $t1, $zero, match_success   # end of pattern = success

    # get text char
    add  $t2, $s0, $s2
    lb   $t3, 0($t2)

    # check for '[' - start of char class
    li   $t4, 91
    beq  $t1, $t4, handle_bracket

    # check for '.' wildcard (0xFF token)
    li   $t4, -1
    beq  $t1, $t4, handle_dot

    # literal char - check if next pattern char is '*'
    addi $t5, $s3, 1
    add  $t5, $s1, $t5
    lb   $t6, 0($t5)
    li   $t7, 42          # '*'
    beq  $t6, $t7, handle_literal_star

    # simple literal match (no star)
    beq  $t3, $zero, match_fail      # no more text
    bne  $t1, $t3, match_fail
    addi $s2, $s2, 1      # text++
    addi $s3, $s3, 1      # pattern++
    addi $s4, $s4, 1      # matched++
    j    match_loop

handle_dot:
    # check if next is '*'
    addi $t5, $s3, 1
    add  $t5, $s1, $t5
    lb   $t6, 0($t5)
    li   $t7, 42
    beq  $t6, $t7, handle_dot_star

    # single dot match
    beq  $t3, $zero, match_fail      # no more text
    addi $s2, $s2, 1
    addi $s3, $s3, 1
    addi $s4, $s4, 1
    j    match_loop

handle_dot_star:
    # .* matches one or more of any char
    beq  $t3, $zero, match_fail      # need at least one
    addi $s2, $s2, 1
    addi $s4, $s4, 1
dot_star_loop:
    add  $t2, $s0, $s2
    lb   $t3, 0($t2)
    beq  $t3, $zero, dot_star_done   # end of text
    addi $s2, $s2, 1
    addi $s4, $s4, 1
    j    dot_star_loop
dot_star_done:
    addi $s3, $s3, 2      # skip . and *
    j    match_loop

handle_literal_star:
    # char* matches one or more of that char
    beq  $t3, $zero, match_fail      # need at least one
    bne  $t1, $t3, match_fail        # first must match
    addi $s2, $s2, 1
    addi $s4, $s4, 1
lit_star_loop:
    add  $t2, $s0, $s2
    lb   $t3, 0($t2)
    bne  $t1, $t3, lit_star_done     # different char = done
    addi $s2, $s2, 1
    addi $s4, $s4, 1
    j    lit_star_loop
lit_star_done:
    addi $s3, $s3, 2      # skip char and *
    j    match_loop

handle_bracket:
    # [...] char class - check for negation
    addi $s3, $s3, 1      # skip '['
    add  $t0, $s1, $s3
    lb   $t1, 0($t0)
    li   $s5, 0           # negation flag = false
    li   $t4, 94          # '^'
    bne  $t1, $t4, bracket_no_neg
    li   $s5, 1           # negation = true
    addi $s3, $s3, 1      # skip '^'
bracket_no_neg:
    # check if next pattern char after ] is '*'
    move $t8, $s3         # save bracket content start
    # find closing ]
find_close:
    add  $t0, $s1, $s3
    lb   $t1, 0($t0)
    beq  $t1, $zero, match_fail      # no closing bracket
    li   $t4, 93
    beq  $t1, $t4, found_close
    addi $s3, $s3, 1
    j    find_close
found_close:
    # $s3 points to ']', check if next is '*'
    addi $t5, $s3, 1
    add  $t5, $s1, $t5
    lb   $t6, 0($t5)
    li   $t7, 42
    beq  $t6, $t7, bracket_star
    # no star - single char class match
    move $s3, $t8         # restore to bracket content
    beq  $t3, $zero, match_fail
    jal  check_char_class
    # v0 = 1 if char matches class, 0 otherwise
    beq  $s5, $zero, bracket_no_neg2
    # negated: want v0 == 0
    bne  $v0, $zero, match_fail
    j    bracket_matched_one
bracket_no_neg2:
    beq  $v0, $zero, match_fail
bracket_matched_one:
    addi $s2, $s2, 1
    addi $s4, $s4, 1
    # skip to after ]
skip_to_close1:
    add  $t0, $s1, $s3
    lb   $t1, 0($t0)
    li   $t4, 93
    beq  $t1, $t4, after_close1
    addi $s3, $s3, 1
    j    skip_to_close1
after_close1:
    addi $s3, $s3, 1      # skip ']'
    j    match_loop

bracket_star:
    # [...]* - match one or more
    move $s3, $t8         # restore to bracket content
    beq  $t3, $zero, match_fail      # need at least one char
    jal  check_char_class
    beq  $s5, $zero, bstar_no_neg1
    # negated
    bne  $v0, $zero, match_fail
    j    bstar_first_ok
bstar_no_neg1:
    beq  $v0, $zero, match_fail
bstar_first_ok:
    addi $s2, $s2, 1
    addi $s4, $s4, 1
bstar_loop:
    add  $t2, $s0, $s2
    lb   $t3, 0($t2)
    beq  $t3, $zero, bstar_done
    move $s3, $t8         # back to bracket start
    jal  check_char_class
    beq  $s5, $zero, bstar_no_neg2
    bne  $v0, $zero, bstar_done      # negated and matched = stop
    j    bstar_cont
bstar_no_neg2:
    beq  $v0, $zero, bstar_done      # not in class = stop
bstar_cont:
    addi $s2, $s2, 1
    addi $s4, $s4, 1
    j    bstar_loop
bstar_done:
    # skip to after ]*
    move $s3, $t8
skip_to_close2:
    add  $t0, $s1, $s3
    lb   $t1, 0($t0)
    li   $t4, 93
    beq  $t1, $t4, after_close2
    addi $s3, $s3, 1
    j    skip_to_close2
after_close2:
    addi $s3, $s3, 2      # skip ']' and '*'
    j    match_loop

match_success:
    beq  $s4, $zero, match_fail      # must match at least one char
    move $v0, $s4
    j    match_return

match_fail:
    li   $v0, 0

match_return:
    lw   $s5, 0($sp)
    lw   $s4, 4($sp)
    lw   $s3, 8($sp)
    lw   $s2, 12($sp)
    lw   $s1, 16($sp)
    lw   $s0, 20($sp)
    lw   $ra, 24($sp)
    addi $sp, $sp, 28
    jr   $ra

# check_char_class - check if $t3 matches bracket contents starting at $s3
# returns $v0 = 1 if match, 0 if not
# does not modify $s3
check_char_class:
    li   $v0, 0           # default no match
    move $t9, $s3         # use t9 as local iterator
ccc_loop:
    add  $t0, $s1, $t9
    lb   $t1, 0($t0)
    li   $t4, 93          # ']'
    beq  $t1, $t4, ccc_done
    beq  $t1, $zero, ccc_done
    # check if next char is '-' for range
    addi $t5, $t9, 1
    add  $t5, $s1, $t5
    lb   $t6, 0($t5)
    li   $t7, 45          # '-'
    bne  $t6, $t7, ccc_single
    # it's a range: t1 is start, get end
    addi $t5, $t9, 2
    add  $t5, $s1, $t5
    lb   $t7, 0($t5)      # t7 = end of range
    # check if t3 >= t1 and t3 <= t7
    blt  $t3, $t1, ccc_skip_range
    bgt  $t3, $t7, ccc_skip_range
    li   $v0, 1           # in range
    jr   $ra
ccc_skip_range:
    addi $t9, $t9, 3      # skip start-end
    j    ccc_loop
ccc_single:
    beq  $t3, $t1, ccc_match
    addi $t9, $t9, 1
    j    ccc_loop
ccc_match:
    li   $v0, 1
    jr   $ra
ccc_done:
    jr   $ra


# print_match - prints substring with comma separator
# args: $a0=text, $a1=start, $a2=len, $a3=printed_before
print_match:
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $t0, 8($sp)
    sw   $t1, 4($sp)
    sw   $t2, 0($sp)

    # save args before potential syscall
    move $t0, $a0         # base address
    move $t1, $a1         # start index
    move $t2, $a2         # length

    beq  $a3, $zero, pm_loop

    la   $a0, comma_space
    li   $v0, 4
    syscall

pm_loop:
    beq  $t2, $zero, pm_done

    add  $t3, $t0, $t1
    lb   $a0, 0($t3)
    li   $v0, 11
    syscall

    addi $t1, $t1, 1
    addi $t2, $t2, -1
    j    pm_loop

pm_done:
    lw   $t2, 0($sp)
    lw   $t1, 4($sp)
    lw   $t0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra
