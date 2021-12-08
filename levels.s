.data
level_number: .byte 0

.text

name_0:
.asciz "00_starting_easy.txt"
data_0:
.ascii "r DF2935\n"
.ascii "b 3772FF\n"
.ascii "\n"
.ascii "rbrb\n"
.ascii "rrrr\n"
.ascii "\n"
.ascii "rrr>brr\n"
.ascii "br>rb\n"
.asciz ".\n"

name_1:
.asciz "01_orange_bananas.txt"
data_1:
.ascii "o cc6a08\n"
.ascii "y fcc708\n"
.ascii "b 0d9adb\n"
.ascii "\n"
.ascii "oyoyoyb\n"
.ascii "b\n"
.ascii "\n"
.ascii "b > yyb\n"
.ascii "yb > ob\n"
.ascii "yoy > oyo\n"
.ascii "oyo > yoy\n"
.asciz ".\n"

name_2:
.asciz "02_green_solitude.txt"
data_2:
.ascii "r DF2935\n"
.ascii "b 3772FF\n"
.ascii "g 1A936F\n"
.ascii "\n"
.ascii "rbgbr\n"
.ascii "rgb\n"
.ascii "\n"
.ascii "rgb > rrgb\n"
.ascii "rrg > rgb\n"
.ascii "rrr > b\n"
.ascii "bbb > r\n"
.asciz ".\n"

name_3:
.asciz "03_converter.txt"
data_3:
.ascii "y FDCA40\n"
.ascii "r DF2935\n"
.ascii "b 3772FF\n"
.ascii "g 1A936F\n"
.ascii "\n"
.ascii "rbbbgy\n"
.ascii "rbbgy\n"
.ascii "\n"
.ascii "rgy>rg\n"
.ascii "bg>gy\n"
.ascii "rg>rrg\n"
.ascii "rr>b\n"
.asciz ".\n"

name_4:
.asciz "04_pink_panther.txt"
data_4:
.ascii "g 60992D\n"
.ascii "b 3772FF\n"
.ascii "y F5B841\n"
.ascii "r DB2B39\n"
.ascii "p EF709D\n"
.ascii "\n"
.ascii "ppppppp\n"
.ascii "ggggggg\n"
.ascii "\n"
.ascii "g > r\n"
.ascii "rgg > pyr\n"
.ascii "ypy > bpb\n"
.ascii "brg > ppp\n"
.ascii "gpb > ppp\n"
.asciz ".\n"

name_5:
.asciz "05_evening_shore.txt"
data_5:
.ascii "a f72585\n"
.ascii "b b5179e\n"
.ascii "c 7209b7\n"
.ascii "d 4361ee\n"
.ascii "e 4cc9f0\n"
.ascii "f d4a373\n"
.ascii "\n"
.ascii "abcde\n"
.ascii "edcba\n"
.ascii "\n"
.ascii "a > bf\n"
.ascii "b > cf\n"
.ascii "c > df\n"
.ascii "d > ef\n"
.ascii "e > af\n"
.ascii "fd > df\n"
.ascii "df > fd\n"
.ascii "dfd > dd\n"
.ascii "dff > e\n"
.ascii ".\n"

name_6:
.asciz "06_barcode.txt"
data_6:
.ascii "- 101010\n"
.ascii "* 04471c\n"
.ascii "| 058c42\n"
.ascii "s 0582ca\n"
.ascii "r ffc857\n"
.ascii "o d8e2dc\n"
.ascii "\n"
.ascii "os*|--|*|-*-o\n"
.ascii "os----------o\n"
.ascii "\n"
.ascii "s- > -s\n"
.ascii "s- > *s\n"
.ascii "s* > |s\n"
.ascii "-r > r-\n"
.ascii "*r > r*\n"
.ascii "|r > r|\n"
.ascii "so > ro\n"
.ascii "or > os\n"
.asciz ".\n"

name_the_end:
.asciz "THE_END.txt"
data_the_end:
.ascii "You beat every single one of my levels!\n"
.ascii "I hope you enjoyed them. They were fun to make.\n"
.ascii "Feel free to make more levels and share them with friends.\n"
.ascii "If you don't have friends send the levels to me. :)\n"
.ascii "\n"
.asciz "- Viliam Vadocz\n"

.equ LEVELS, 6

levels:
.quad data_0
.quad data_1
.quad data_2
.quad data_3
.quad data_4
.quad data_5
.quad data_6
.quad data_the_end

level_names:
.quad name_0
.quad name_1
.quad name_2
.quad name_3
.quad name_4
.quad name_5
.quad name_6
.quad name_the_end

write_file_mode: .asciz "w"

# ********************* #
# create_level(number)  #
# ********************* #
create_level:
    push %rbx
    mov %rdi, %rbx      # save level id

    # Open file.
    mov level_names(, %rdi, 8), %rdi    # param1: level name
    mov $write_file_mode, %rsi          # param2: write file mode
    call fopen
    mov %rbx, %rdi                      # move level id back to rdi
    mov %rax, %rbx                      # save file descriptor

    mov levels(, %rdi, 8), %rdi         # param1: string to write
    mov %rax, %rsi                      # param2: file descriptor
    call fputs

    # Close file descriptor.
    movq %rbx, %rdi
    call fclose

    pop %rbx
    ret

# ***************************************** #
# check_level(string)                       #
# - compare string with all of the levels   #
# - if one matches, set the level number    #
# ***************************************** #
check_level:
    # AX    char from file
    # BX    char from level
    # CX    id of level
    # DX    offset from start of strings
    # DI    file string pointer
    # SI    level string pointer

    push %rbx                               # save callee-saved register

    xor %ecx, %ecx
    compare_level:
        mov levels(, %ecx, 8), %esi         # load level string pointer
        
        xor %edx, %edx
        compare_char:
            mov (%edi, %edx), %al           # get char from file
            mov (%esi, %edx), %bl           # get char from level
            test %al, %al                   # check if file file char is null
            jz same_level                   # null means end of file - they are the same

            inc %edx                        # increment string offset
            cmp %al, %bl                    # compare characters
            je compare_char

        inc %ecx
        cmp $LEVELS, %ecx
        jl compare_level

    pop %rbx                                # restore callee-saved register
    ret

    same_level:
        inc %ecx
        movb %cl, (level_number)
        pop %rbx
        ret
