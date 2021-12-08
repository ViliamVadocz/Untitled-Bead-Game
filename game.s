.text

# ************************************************* #
# game()                                            #
# - Runs the bead game with level read from file    #
# ************************************************* #
game:
    # save callee-saved registers
    pushq %r12          # number of current beads / scratch
    pushq %r13          # number of operations used / scratch
    pushq %r14          # bead cursor
    pushq %r15          # ops cursor
    
    xor %r13d, %r13d
    xor %r14d, %r14d
    xor %r15d, %r15d

    call enable_raw_mode

tick:
    # clear screen
    lea clear, %edi
    xor %eax, %eax
    call printf

    xor %r12d, %r12d                    # clear current number of beads
    draw_goal:
        movzbl goal_beads(%r12d), %edi      # get id of next bead
        test %edi, %edi
        jz done_draw_goal                   # if it's zero, exit loop
        call draw_bead                      # draw the bead to stdout
        inc %r12d                           # increment bead counter
        jmp draw_goal                       # loop
    done_draw_goal:

    mov $0x0A, %edi                     # print newline
    call putchar

    xor %r12d, %r12d
    draw_current:
        movzbl current_beads(%r12d), %edi   # get id of next bead
        test %edi, %edi
        jz done_draw_current                # if it's zero, exit loop
        call draw_bead                      # draw the bead to stdout
        inc %r12d                           # increment bead counter
        jmp draw_current                    # loop
    done_draw_current:
    pushq %r12                          # save number of current beads on stack

    mov $0x0A, %edi                     # print newline
    call putchar

    test %r14d, %r14d                   # if cursor position is zero, skip ahead
    jz just_draw_bead_cursor            
    mov %r14d, %r12d                    # copy cursor position to R12
    draw_bead_cursor_space:
        # print spaces until R12 is zero
        lea space, %edi
        xor %eax, %eax
        call printf
        dec %r12d
        jnz draw_bead_cursor_space
    just_draw_bead_cursor:
    lea bead_cursor, %edi               # print the actual cursor
    xor %eax, %eax                      
    call printf

    mov $0x0A, %edi                     # print newline
    call putchar

    xor %r12d, %r12d
    pushq %r13                           # save number of operations used on the stack
    lea operations, %r13d                # use R13 to store address to make indirect addressing nicer
    draw_operations:
        mov operations(, %r12d, 8), %eax    # check if next operation starts with an empty precondition
        test %eax, %eax
        jz done_draw_operations             # if yes, you're done with drawing operations

        cmp %r15d, %r12d                    # if the current operation number matches cursor, draw cursor
        je draw_ops_cursor
        lea space, %edi                     # otherwise just print indentation
        xor %eax, %eax
        call printf
        jmp done_draw_ops_cursor
        draw_ops_cursor:
            lea ops_cursor, %edi
            xor %eax, %eax
            call printf
        done_draw_ops_cursor:

        # draw precondition of operation
        movzbl 0(%r13d, %r12d, 8), %edi
        call draw_bead
        movzbl 1(%r13d, %r12d, 8), %edi
        call draw_bead
        movzbl 2(%r13d, %r12d, 8), %edi
        call draw_bead
        movzbl 3(%r13d, %r12d, 8), %edi
        call draw_bead

        # draw arrow
        lea arrow, %edi
        xor %eax, %eax
        call printf

        # draw postcondition of operation
        movzbl 4(%r13d, %r12d, 8), %edi
        call draw_bead
        movzbl 5(%r13d, %r12d, 8), %edi
        call draw_bead
        movzbl 6(%r13d, %r12d, 8), %edi
        call draw_bead
        movzbl 7(%r13d, %r12d, 8), %edi
        call draw_bead

        mov $0x0A, %edi                     # print newline
        call putchar

        inc %r12d
        jmp draw_operations
    done_draw_operations:
    popq %r13                       # pop the number of operations used
    popq %r12                       # pop the number of current beads

    lea score, %rdi
    mov %r13d, %esi
    xor %eax, %eax
    call printf

input:
    # figure out input from player
    call read_char          # read the character
    lea input, %rcx         # initialize RCX with a default address (input)
    cmpb $113, %al          # input was 'q'
    mov $end, %rdx          #  -> end program
    cmove %rdx, %rcx        #  -> overwrite RCX with (end)
    cmpb $32, %al           # input was space
    mov $confirm, %rdx      #  -> confirm operation
    cmove %rdx, %rcx        #  -> overwrite RCX with (confirm)
    cmpb $10, %al           # input was newline
    cmove %rdx, %rcx        #  -> overwrite RCX with (confirm)
    cmpb $27, %al           # check if input was escape
    je escape               #  -> check known escape sequences
    jmp *%rcx               # otherwise we go to the address specified in RCX

escape:
    call read_char
    cmpb $91, %al           # make sure next char is '['
    jne input               # if not, just ignore the escape

    # get arrow key input
    call read_char
    add $-65, %eax          # https://stackoverflow.com/a/14416584/10514840
    cmp $4, %eax            # check if the character is within [65, 68] ['A', 'D']
    jae input

    shl $3, %rax                # multiply by 8
    mov direction(%rax), %rax   # use direction jumptable
    jmp *%rax

# direction jumptable
direction:
    .quad up        # <ESC>[A
    .quad down      # <ESC>[B
    .quad right     # <ESC>[C
    .quad left      # <ESC>[D

up:
    mov %r15d, %eax         # save current ops cursor to RAX
    sub $1, %r15d           # try subtracting one from ops cursor
    cmovs %eax, %r15d       # if less than zero, use saved ops cursor
    jmp tick
down:
    mov %r15d, %eax         # save current ops cursor to RAX
    inc %r15d               # try incrementing ops cursor
    movzbl (operation_num), %ecx    # move operations_num to register
    cmp %ecx, %r15d         # compare with operations_num
    cmovge %eax, %r15d      # if greater or equal, use saved ops cursor
    jmp tick
right:
    mov %r14d, %eax         # save current bead cursor
    inc %r14d               # try incrementing bead cursor
    cmp %r12d, %r14d        # compare with current bead number (in R12)
    cmovge %eax, %r14d      # if greater or equal, use saved bead cursor
    jmp tick
left:
    mov %r14d, %eax         # save current bead cursor to RAX
    sub $1, %r14d           # try subtracting one from bead cursor
    cmovs %eax, %r14d       # if less than zero, use saved bead cursor
    jmp tick

confirm:
    # TODO
    # - find out how many things are getting removed and how many are being added
    # - push beads to the right of op on the stack (including new ones and not including removed ones)
    # - adjust pointer based on how many things are removed / added
    # - write the bead chain back from the end

    lea operations(, %r15d, 8), %eax    # EAX holds start of used operation
    lea current_beads(%r14d), %ecx      # ECX holds position of first bead at cursor
    xor %esi, %esi
    mov $1, %r8
    operation_validation:
        # compare first bead
        movb (%eax), %dl
        movb (%ecx), %dil
        cmp %dl, %dil
        cmovne %r8d, %esi

        # compare second bead
        movb 1(%eax), %dl
        movb 1(%ecx), %dil
        test %dl, %dl
        jz bead_check_done          # skip other checks if operation bead is zero
        cmp %dl, %dil
        cmovne %r8d, %esi
        
        # compare third bead
        movb 2(%eax), %dl
        movb 2(%ecx), %dil
        test %dl, %dl
        jz bead_check_done          # skip other checks if operation bead is zero
        cmp %dl, %dil
        cmovne %r8d, %esi
        
        # compare fourth bead
        movb 3(%eax), %dl
        movb 3(%ecx), %dil
        test %dl, %dl
        jz bead_check_done          # skip last check if operation bead is zero
        cmp %dl, %dil
        cmovne %r8d, %esi

    bead_check_done:
        test %esi, %esi             # if the beads were ever not the same then esi is not zero
        jnz tick                    # return to start of tick if operation doesn't apply

    inc %r13d                       # operation matches so we increment used operations

    # apply operation
    # - first push all postcondition beads on the stack and count how many there are
    # - then count how many input beads there were, skip that many on current bead chain
    # - compute difference between pre and post conditions
    # - add rest of chain on the stack
    # - offset bead cursor by computed difference
    # - pop from stack to rewrite bead chain from the back
    
    xor %esi, %esi                      # ESI will hold the bead difference in the operation
    
    # add first 
    movzbw 4(%eax), %dx                 # read postcondition bead
    test %dx, %dx                       # check if it is zero
    jz postcondition_beads_on_stack     # if zero, then we're done with putting beads on stack
    pushw %dx                           # put the postcondition bead on stack
    inc %esi                            # increment bead diff count

    # add second 
    movzbw 5(%eax), %dx                 # same thing with the next bead
    test %dx, %dx
    jz postcondition_beads_on_stack
    pushw %dx
    inc %esi

    # add third 
    movzbw 6(%eax), %dx                 # same
    test %dx, %dx
    jz postcondition_beads_on_stack
    pushw %dx
    inc %esi

    # add third 
    movzbw 7(%eax), %dx                 # same
    test %dx, %dx
    jz postcondition_beads_on_stack
    pushw %dx
    inc %esi
    postcondition_beads_on_stack:
    
    # skip once 
    movb (%eax), %dh                    # load precondition bead
    test %dh, %dh                       # check if it is zero
    jz precondition_beads_counted       # if zero, then we are done counting precondition beads
    inc %ecx                            # increment temporary bead cursor
    dec %esi                            # decrement operation bead diff 

    # skip second time 
    movb 1(%eax), %dh                   # same thing with next bead
    test %dh, %dh
    jz precondition_beads_counted
    inc %ecx
    dec %esi

    # skip third time 
    movb 2(%eax), %dh                   # same again
    test %dh, %dh
    jz precondition_beads_counted
    inc %ecx
    dec %esi

    # skip fourth time 
    movb 3(%eax), %dh                   # same
    test %dh, %dh
    jz precondition_beads_counted
    inc %ecx
    dec %esi
    precondition_beads_counted:
    
    next_bead_to_stack:
        movzbw (%ecx), %dx              # load bead from current pointer (was offset by pre-condition count)
        test %dx, %dx                   # check if the bead is zero
        jz adjust_bead_cursor           # if bead is zero then we are done saving beads
        pushw %dx                       # save bead on stack
        inc %ecx                        # increment bead pointer
        jmp next_bead_to_stack          # loop

    adjust_bead_cursor:
        cmp $0, %esi                    # compare the bead difference
        jge add_to_bead_cursor          # if it is greater or equal to zero then we just add to the pointer
    erase_top:
        dec %ecx                        # decrement bead pointer
        movb $0, (%ecx)                 # overwrite bead with zero
        inc %esi                        # increment difference (so in total be zero out the number corresponding to diff)
        jnz erase_top                   # loop if difference is not zero
    add_to_bead_cursor:
        add %esi, %ecx                  # adjust pointer based on difference
        lea current_beads(%r14d), %esi  # save bead cursor to ESI to know when to stop
    restore_chain:
        dec %ecx                        # decrement bead pointer
        popw %dx                        # pop last bead from the stack
        movb %dl, (%ecx)                # copy it to the current bead pointer
        cmp %ecx, %esi                        
        jne restore_chain
    
    # check if the bead chains match
    xor %edi, %edi
    check_bead:
        mov goal_beads(%edi), %eax          # load next goal bead
        mov current_beads(%edi), %ecx       # load next current bead
        cmp %eax, %ecx                      # compare
        jne tick                            # if they aren't equal, exit loop and go back to start of tick
        test %eax, %eax                     # if the goal bead is 0 (end of chain) then they match
        jz success                          # go to success!
        inc %edi                            # increment bead pointer
        jmp check_bead                      # loop

success:
    # print congratulations message
    lea congrats, %edi
    mov %r13d, %esi
    xor %eax, %eax
    call printf

    # draw final bead chain
    xor %r12d, %r12d
    draw_final:
        movzbl goal_beads(%r12d), %edi      # get id of next bead
        test %edi, %edi
        jz done_draw_final                  # if it's zero, exit loop
        call draw_bead                      # draw the bead to stdout
        inc %r12d                           # increment bead counter
        jmp draw_final                      # loop
    done_draw_final:

    mov $0x0A, %edi                     # print newline
    call putchar

    # create the next level file
    movzbl (level_number), %edi
    test %edi, %edi
    jz end
    call create_level

end:
    call disable_raw_mode
    # restore callee-saved registers
    popq %r15
    popq %r14
    popq %r13
    popq %r12

    ret


# ************************************************* #
# draw_bead(id)                                     #
# - draws a circle on screen with the given colours #
# ************************************************* #
draw_bead:
    test %edi, %edi
    jz no_draw
    jmp do_draw
no_draw:
    lea space, %edi                    # just print spaces
    xor %eax, %eax
    call printf
    ret
do_draw:
    shl $2, %edi
    movzbl colour_lookup(%edi), %ecx    # lookup blue
    inc %edi
    movzbl colour_lookup(%edi), %edx    # lookup green
    inc %edi
    movzbl colour_lookup(%edi), %esi    # lookup red

    lea bead, %edi                      # format string
    xor %eax, %eax                      # no vector registers
    call printf
    ret
