.include "raw_mode.s"
.include "strings.s"
.include "read_file.s"
.include "levels.s"
.include "game.s"
.global main

main:
    cmp $2, %edi            # make sure than number of arguments matches 2
    jne error

    mov 8(%rsi), %rdi       # take argv[1]

    # check if we want to start a new game 
    movb (%rdi), %al
    cmp $110, %al           # compare first character to 'n'
    jne maybe_its_help
    movb 1(%rdi), %al       
    cmp $101, %al           # compare second character to 'e'
    jne play_level
    movb 2(%rdi), %al       
    cmp $119, %al           # compare second character to 'w'
    jne play_level

    # create first level file (id: 0)
    xor %edi, %edi
    call create_level

    lea done_msg, %edi
    xor %eax, %eax
    call printf
    jmp done

maybe_its_help:
    cmp $104, %al           # compare first character to 'h'
    jne play_level
    movb 1(%rdi), %al       
    cmp $101, %al           # compare second character to 'e'
    jne play_level
    movb 2(%rdi), %al       
    cmp $108, %al           # compare second character to 'l'
    jne play_level
    movb 3(%rdi), %al       
    cmp $112, %al           # compare second character to 'p'
    jne play_level

    lea help, %edi
    xor %eax, %eax
    call printf
    jmp done

play_level:
    movq 8(%rsi), %rdi      # file path is in argv[1]
    call load_level         # load level file
    test %eax, %eax         # check if there was an error
    jz error                # if load_level returned zero then there was an erro

    call game               # we have successfully loaded and can start the game!

done:
    # exit with code 0
    xor %edi, %edi
    call exit

error:
    lea usage, %edi
    xor %eax, %eax
    call printf
    jmp done
