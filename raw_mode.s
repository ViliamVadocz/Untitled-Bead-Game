.equ SYS_READ, 0
.equ SYS_WRITE, 1
.equ SYS_IOCTL, 16

.equ STDIN, 0
.equ STDOUT, 1

.equ TCGETS, 0x5401
.equ TCSETS, 0x5402
.equ ICANON, 0x00000002
.equ ECHO, 0x00000008

# https://stackoverflow.com/a/62939804/10514840
# https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html
# https://man7.org/linux/man-pages/man2/ioctl.2.html
.bss
termios:
    c_iflag: .long  0   # input mode flags
    c_oflag: .long  0   # output mode flags
    c_cflag: .long  0   # control mode flags
    c_lflag: .long  0   # local mode flags
    c_line:  .byte  0   # line discipline
    c_cc:    .skip 19   # control characters

.text

# ************************************************* #
# enable_raw_mode()                                 #
# - Disables canonical mode (waiting for enter)     #
# - Disables echo (printing the things you type)    #
# ************************************************* #
enable_raw_mode:
    # get current settings
    mov $SYS_IOCTL, %eax
    mov $STDIN, %edi
    mov $TCGETS, %esi
    lea termios, %rdx
    syscall

    andl $~ICANON, (c_lflag)        # clear ICANON to disable canonical mode
    andl $~ECHO, (c_lflag)          # clear ECHO to disable printing the character you type
    
    jmp write_termios

disable_raw_mode:
    # get current settings
    mov $SYS_IOCTL, %eax
    mov $STDIN, %edi
    mov $TCGETS, %esi
    lea termios, %rdx
    syscall

    orl $ICANON, (c_lflag)          # set ICANON to enable canonical mode
    orl $ECHO, (c_lflag)            # set ECHO to enable typing echo

write_termios:
    # write termios struct back
    mov $SYS_IOCTL, %eax
    mov $STDIN, %edi
    mov $TCSETS, %esi
    lea termios, %rdx
    syscall
    ret

# ************************************* #
# read_char() -> char                   #
# - reads a single character from STDIN #
# ************************************* #
read_char:
    sub $1, %rsp            # make space on stack for a single character    
    mov $SYS_READ, %eax
    mov $STDIN, %edi
    lea (%rsp), %rsi
    mov $1, %edx
    syscall

    movzbl (%rsp), %eax     # read single byte from stack
    add $1, %rsp            # restore stack pointer
    ret
