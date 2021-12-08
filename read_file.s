.equ MAX_BEAD_TYPES, 32
.equ MAX_BEADS, 128
.equ MAX_OPS, 16

.data

# Each colour takes 4 bytes (r, g, b, char)
# The char is used when loading from file
colour_lookup: .skip (4*MAX_BEAD_TYPES)

# Each bead takes 1 byte (id)
# Ids start at 1 (0 is empty)
current_beads: .skip MAX_BEADS

# Same as current beads
goal_beads: .skip MAX_BEADS

# Each operation takes 8 bytes (at most 4 inputs, at most 4 outputs)
operations: .skip (8*MAX_OPS)
operation_num: .byte 0

.text

# ************************************************* #
# load_level(file_path)                             #
# - stores a zero in RAX if there was an error      #
# ************************************************* #
load_level:
    call read_file
    test %rax, %rax
    jz loading_error

    push %r12           # save callee-saved register
    mov %rax, %r12      # save string pointer to R12

    # A level file looks like this:
    #   y FDCA40        (this part defined the colours and letters which will be used)
    #   r DF2935            (whitespace matters)
    #   b 3772FF
    #   g 1A936F
    #                       (empty line marks end of colours)
    #   rrb             (goal bead chain)
    #   brr             (starting bead chain)
    #                       (another empty line here is needed)
    #   br>rb           (operations)
    #   bbb>rbr             (whitespace is ignored)
    #   .               (marks the end of operations)

    # loop 1
        # take first character
        # when the first char is newline, continue to loop 2
        # otherwise load hex colour code into memory
    # loop 2
        # for each character add to the goal chain until newline (ignore whitespace)
        # to get id look through colour_lookup
    # loop 3
        # for each character add to the current chain until newline (ignore whitespace)
        # to get id look through colour_lookup
    # loop 4
        # take beads until '>'
        # no more than 4 allowed, just skip others
        # then the rest become the postcondition (again 4 max, then ignore until newline)
        # when a . is found at the start we reached the end
    # save number of ops

    mov %rax, %rdi              # RDI will hold the string pointer
    xor %esi, %esi              # use ESI to keep track of how many colours we saved
    # RAX will hold the entry into colour lookup until it is saved
    load_colours:
        movzbl (%rdi), %eax     # copy character into RAX
        cmp $10, %al            # check if the first character is a newline
        je done_loading_colours

        shl $8, %eax
                                # skip the space
        movzbl 2(%rdi), %edx    # copy first digit into RDX

        # digit '0'-'9'
        mov %edx, %ecx          # copy character to RCX for math
        sub $48, %ecx           # '0' becomes 0
        cmpb $58, %dl           # check if char < '9'
        jl digit_2

        # capital letter 'A'-'F'
        mov %edx, %ecx          # copy character to RCX for math
        sub $55, %ecx           # 'A' becomes 10
        cmpb $71, %dl           # check if char < 'A'
        jl digit_2

        # lowercase letter 'a'-'f'
        mov %edx, %ecx          # copy character to RCX for math
        sub $87, %ecx           # 'a' becomes 10

        digit_2:
        shl $4, %ecx
        add %ecx, %eax
        # same as above ^^^
        movzbl 3(%rdi), %edx    # copy second digit into RDX
        mov %edx, %ecx          # digit '0'-'9'
        sub $48, %ecx
        cmpb $58, %dl
        jl digit_3
        mov %edx, %ecx          # capital letter 'A'-'F'
        sub $55, %ecx
        cmpb $71, %dl
        jl digit_3
        mov %edx, %ecx          # lowercase letter 'a'-'f'
        sub $87, %ecx

        digit_3:
        add %ecx, %eax
        shl $8, %eax
        movzbl 4(%rdi), %edx    # copy third digit into RDX
        mov %edx, %ecx          # digit '0'-'9'
        sub $48, %ecx
        cmpb $58, %dl
        jl digit_4
        mov %edx, %ecx          # capital letter 'A'-'F'
        sub $55, %ecx
        cmpb $71, %dl
        jl digit_4
        mov %edx, %ecx          # lowercase letter 'a'-'f'
        sub $87, %ecx

        digit_4:
        shl $4, %ecx
        add %ecx, %eax
        movzbl 5(%rdi), %edx    # copy fourth digit into RDX
        mov %edx, %ecx          # digit '0'-'9'
        sub $48, %ecx
        cmpb $58, %dl
        jl digit_5
        mov %edx, %ecx          # capital letter 'A'-'F'
        sub $55, %ecx
        cmpb $71, %dl
        jl digit_5
        mov %edx, %ecx          # lowercase letter 'a'-'f'
        sub $87, %ecx

        digit_5:
        add %ecx, %eax
        shl $8, %eax
        movzbl 6(%rdi), %edx    # copy fifth digit into RDX
        mov %edx, %ecx          # digit '0'-'9'
        sub $48, %ecx
        cmpb $58, %dl
        jl digit_6
        mov %edx, %ecx          # capital letter 'A'-'F'
        sub $55, %ecx
        cmpb $71, %dl
        jl digit_6
        mov %edx, %ecx          # lowercase letter 'a'-'f'
        sub $87, %ecx

        digit_6:
        shl $4, %ecx
        add %ecx, %eax
        movzbl 7(%rdi), %edx    # copy sixth digit into RDX
        mov %edx, %ecx          # digit '0'-'9'
        sub $48, %ecx
        cmpb $58, %dl
        jl digits_done
        mov %edx, %ecx          # capital letter 'A'-'F'
        sub $55, %ecx
        cmpb $71, %dl
        jl digits_done
        mov %edx, %ecx          # lowercase letter 'a'-'f'
        sub $87, %ecx

        digits_done:
        add %ecx, %eax
        inc %esi
        mov %rax, colour_lookup(, %esi, 4)  # save entry to colour_lookup
        add $9, %rdi            # add 9 to move to next line (character + space + 6 digits + newline)
        jmp load_colours

    done_loading_colours:
        inc %rdi                # the empty line

    xor %ecx, %ecx              # ECX will have the current bead number
    load_goal_chain:
        movzbl (%rdi), %eax     # load character into EAX
        inc %rdi                # increment string pointer
        cmp $10, %al            # check if character is newline
        je done_loading_goal_chain
        cmp $32, %al
        jle load_goal_chain     # ignore whitespace
        
        xor %edx, %edx          # reset EDX to zero
        find_goal_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg goal_bead_error      # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_goal_colour

        mov %dl, goal_beads(%ecx)   # if it matches we know the id
        inc %ecx                    # increment the number of beads
        cmp $MAX_BEADS, %ecx        # check that the number of loaded beads is not more than max
        jg goal_bead_error
        jmp load_goal_chain

    done_loading_goal_chain:

    # Pretty much the same code as above
    xor %ecx, %ecx              # ECX will have the current bead number
    load_start_chain:
        movzbl (%rdi), %eax     # load character into EAX
        inc %rdi                # increment string pointer
        cmp $10, %al            # check if character is newline
        je done_loading_start_chain
        cmp $32, %al
        jle load_goal_chain     # ignore whitespace
        
        xor %edx, %edx          # reset EDX to zero
        find_start_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg start_bead_error     # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_start_colour

        mov %dl, current_beads(%ecx)    # if it matches we know the id
        inc %ecx
        cmp $MAX_BEADS, %ecx        # check that the number of loaded beads is not more than max
        jg start_bead_error
        jmp load_start_chain

    done_loading_start_chain:
        inc %rdi                # skip empty line

    parse_operation:
        movzbl (%rdi), %eax     # load character into EAX
        cmp $46, %al            # check if character is '.' which marks the end of operations
        je done_parsing

        xor %ecx, %ecx          # ECX will store the operation until it is written
        skip_whitespace_1:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_1  

        xor %edx, %edx          # reset EDX to zero
        find_op1_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op1_colour
        mov %dl, %cl            # save id to operation
        shl $8, %ecx            # shift to make space

        skip_whitespace_2:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $62, %al            # check if it is '>'
        je shift_twice_precond
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_2  

        xor %edx, %edx          # reset EDX to zero
        find_op2_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op2_colour
        mov %dl, %cl            # save id to operation
        shl $8, %ecx            # shift to make space

        skip_whitespace_3:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $62, %al            # check if it is '>'
        je shift_once_precond
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_3  

        xor %edx, %edx          # reset EDX to zero
        find_op3_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op3_colour
        mov %dl, %cl            # save id to operation
        shl $8, %ecx            # shift to make space

        skip_whitespace_4:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $62, %al            # check if it is '>'
        je pre_condition_parsed
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_4  

        xor %edx, %edx          # reset EDX to zero
        find_op4_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op4_colour
        mov %dl, %cl            # save id to operation

        skip_until_angle_bracket:
            movzbl (%rdi), %eax     # load next character into EAX
            inc %rdi                # increment string pointer
            cmp $62, %al            # check if it is '>'
            jne skip_until_angle_bracket
        jmp pre_condition_parsed

        shift_twice_precond:
            shl $8, %ecx
        shift_once_precond:
            shl $8, %ecx
        pre_condition_parsed:
        mov (operation_num), %edx   # load number of operations
        bswap %ecx                  # reverse order of beads in rule
        mov %ecx, operations(, %edx, 8) # save first part of operation
        xor %ecx, %ecx              # zero out beads

        skip_whitespace_5:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_5  

        xor %edx, %edx          # reset EDX to zero
        find_op5_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op5_colour
        mov %dl, %cl            # save id to operation
        shl $8, %ecx            # shift to make space

        skip_whitespace_6:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $10, %al            # check if it is a newline
        je shift_twice_postcond
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_6  

        xor %edx, %edx          # reset EDX to zero
        find_op6_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op6_colour
        mov %dl, %cl            # save id to operation
        shl $8, %ecx            # shift to make space

        skip_whitespace_7:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $10, %al            # check if it is a newline
        je shift_once_postcond
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_7  

        xor %edx, %edx          # reset EDX to zero
        find_op7_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op7_colour
        mov %dl, %cl            # save id to operation
        shl $8, %ecx            # shift to make space

        skip_whitespace_8:
        movzbl (%rdi), %eax     # load next character into EAX
        inc %rdi                # increment string pointer
        cmp $10, %al            # check if it is a newline
        je post_condition_parsed
        cmp $32, %al            # check if it's whitespace
        jle skip_whitespace_8 

        xor %edx, %edx          # reset EDX to zero
        find_op8_colour:
            inc %edx
            cmp %esi, %edx          # check that we did not go beyond the number of loaded colours
            jg ops_bead_error       # did not find character
            lea colour_lookup(, %edx, 4), %r8d
            add $3, %r8d
            movzbl (%r8d), %r8d
            cmp %eax, %r8d          # compare character in lookup
            jne find_op8_colour
        mov %dl, %cl            # save id to operation

        skip_until_newline:
            movzbl (%rdi), %eax     # load next character into EAX
            inc %rdi                # increment string pointer
            cmp $10, %al            # check if it is a newline
            jne skip_until_newline
        jmp post_condition_parsed

        shift_twice_postcond:
            shl $8, %ecx
        shift_once_postcond:
            shl $8, %ecx
        post_condition_parsed:
        mov (operation_num), %edx   # get operation number
        lea operations(, %edx, 8), %eax
        add $4, %eax                # offset from operation
        bswap %ecx                  # swap order of beads
        mov %ecx, (%eax)            # save post-condition
        incb (operation_num)        # increment number of operations

        jmp parse_operation

    done_parsing:

    # check if the level is part of the main game
    mov %r12, %rdi
    call check_level

    # drop the string
    mov %r12, %rdi
    call free

    pop %r12                # restore callee-saved register

    mov $1, %eax            # no errors!
    ret


# Error exits
goal_bead_error:
    lea goal_bead_loading_err, %edi
    xor %eax, %eax
    call printf

    jmp free_and_exit_with_error

start_bead_error:
    lea start_bead_loading_err, %edi
    xor %eax, %eax
    call printf

    jmp free_and_exit_with_error

ops_bead_error:
    lea ops_bead_loading_err, %edi
    xor %eax, %eax
    call printf

free_and_exit_with_error:
    mov %r12, %rdi
    call free
    pop %r12

    pop %r12
    xor %eax, %eax
    ret

loading_error:
    lea loading_err, %edi
    xor %eax, %eax
    call printf

    xor %eax, %eax
    ret

#############################################
# BELOW IS TAKEN FROM brainfuck/read_file.s #
#############################################

# Taken from <stdio.h>
.equ SEEK_SET,  0
.equ SEEK_CUR,  1
.equ SEEK_END,  2
.equ EOF,      -1

read_file_mode: .asciz "r"

# char * read_file(char const * filename, int * read_bytes)
#
# Read the contents of a file into a newly allocated memory buffer.
# The address of the allocated memory buffer is returned and
# read_bytes is set to the number of bytes read.
#
# A null byte is appended after the file contents, but you are
# encouraged to use read_bytes instead of treating the file contents
# as a null terminated string.
#
# Technically, you should call free() on the returned pointer once
# you are done with the buffer, but you are forgiven if you do not.
read_file:
    pushq %rbp
    movq %rsp, %rbp

    # internal stack usage:
    #  -8(%rbp) saved read_bytes pointer
    # -16(%rbp) FILE pointer
    # -24(%rbp) file size
    # -32(%rbp) address of allocated buffer
    subq $32, %rsp

    # Save the read_bytes pointer.
    movq %rsi, -8(%rbp)

    # Open file for reading.
    movq $read_file_mode, %rsi
    call fopen
    testq %rax, %rax
    jz _read_file_open_failed
    movq %rax, -16(%rbp)

    # Seek to end of file.
    movq %rax, %rdi
    movq $0, %rsi
    movq $SEEK_END, %rdx
    call fseek
    testq %rax, %rax
    jnz _read_file_seek_failed

    # Get current position in file (length of file).
    movq -16(%rbp), %rdi
    call ftell
    cmpq $EOF, %rax
    je _read_file_tell_failed
    movq %rax, -24(%rbp)

    # Seek back to start.
    movq -16(%rbp), %rdi
    movq $0, %rsi
    movq $SEEK_SET, %rdx
    call fseek
    testq %rax, %rax
    jnz _read_file_seek_failed

    # Allocate memory and store pointer.
    # Allocate file_size + 1 for a trailing null byte.
    movq -24(%rbp), %rdi
    incq %rdi
    call malloc
    test %rax, %rax
    jz _read_file_malloc_failed
    movq %rax, -32(%rbp)

    # Read file contents.
    movq %rax, %rdi
    movq $1, %rsi
    movq -24(%rbp), %rdx
    movq -16(%rbp), %rcx
    call fread
    movq -8(%rbp), %rdi
    movq %rax, (%rdi)

    # Add a trailing null byte, just in case.
    movq -32(%rbp), %rdi
    movb $0, (%rdi, %rax)

    # Close file descriptor
    movq -16(%rbp), %rdi
    call fclose

    # Return address of allocated buffer.
    movq -32(%rbp), %rax
    movq %rbp, %rsp
    popq %rbp
    ret

_read_file_malloc_failed:
_read_file_tell_failed:
_read_file_seek_failed:
    # Close file descriptor
    movq -16(%rbp), %rdi
    call fclose

_read_file_open_failed:
    # Set read_bytes to 0 and return null pointer.
    movq -8(%rbp), %rax
    movq $0, (%rax)
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret
