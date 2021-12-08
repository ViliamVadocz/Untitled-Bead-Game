.text
clear: .asciz "\x1b[H\x1b[J\x1b[0m"
score: .asciz "\x1b[39m\n[%ld]\n"
congrats: .asciz "\x1b[H\x1b[J\x1b[0mYou solved the level in [%ld] operations!\n"
done_msg: .asciz "Done!\n"
loading_err: .asciz "There was an error while loading.\n"
goal_bead_loading_err: .asciz "An unexpected character appeared in the goal bead chain.\n"
start_bead_loading_err: .asciz "An unexpected character appeared in the starting bead chain.\n"
ops_bead_loading_err: .asciz "An unexpected character appeared in the operations.\n"

usage:
.ascii "Usage:\n"
.ascii "  game help                 - Show a big help message\n"
.ascii "  game new                  - Create the first level file\n"
.ascii "  game [path_to_level]      - Play a level\n"
.asciz ""

help:
.ascii "What is this?\n"
.ascii "  This is a level based puzzle game about mutating a chain of coloured beads using rules.\n"
.ascii "  Each level has a goal chain, a starting chain, and a set of operations.\n"
.ascii "  Each operation has a pre-condition and a post-condition. This determines where it can be used.\n"
.ascii "How do I play?\n"
.ascii "  Use the [ARROW KEYS] to select where to place the operation and which one to use.\n"
.ascii "  Use [SPACE|ENTER] to confirm the operation.\n"
.ascii "  You can press [q] to quit the level.\n"
.ascii "How can I make my own level?\n"
.ascii "  Each level is stored in a human-readable format.\n"
.ascii "  First the characters and colours are defined each on a separate line.\n"
.ascii "  This section ends with an empty line.\n"
.ascii "  Then we have the goal and starting bead chains. These use the characters defined above.\n"
.ascii "  Finally we have operations. The pre-condition and post-condition as separated by '>'.\n"
.ascii "  You can have a maximum of 4 pre-condition beads and a maximum of 4 post-condition beads.\n"
.ascii "  The operations should end with the character '.' on its own line.\n"
.asciz ""

bead:
    .ascii "\x1b[38;2;%u;%u;%um"
    .byte 0xE2
    .byte 0xAC
    .byte 0xA4
    .byte 0x20
    .byte 0x00

space: .asciz "  "

arrow:
    .ascii "\x1b[39m"
    .byte 0xE2
    .byte 0x87
    .byte 0x92
    .byte 0x20
    .byte 0x00

bead_cursor:
    .ascii "\x1b[39m"
    .byte 0xE2
    .byte 0xAE
    .byte 0x9D
    .byte 0x0A
    .byte 0x00

ops_cursor:
    .ascii "\x1b[39m"
    .byte 0xE2
    .byte 0xAE
    .byte 0x9E
    .byte 0x20
    .byte 0x00
