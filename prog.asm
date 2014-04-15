; SWR switch register
; A,B,C,D gp register
; PC

; 00 start
; 08 left
; 10 right
; 18 push

    OUT '?'
    HLT

0x03:               ; left interrupt
    SHR SWR
    JC LEFT_A
    SUB B, ONE
    JMP OUT_NUM
LEFT_A: SUB A, ONE
    JMP OUT_NUM

0x0C:               ; right interrupt
    SHR SWR
    JC RIGHT_A
    ADD B, ONE
    JMP OUT_NUM
RIGHT_A:
    ADD A, ONE
    JMP OUT_NUM

0x15:               ; push interrupt
    OUT '='
    SUB B, ZERO
    JNZ DIVIDE
    OUT 'E'
    OUT 'r'
    OUT 'r'
    OUT 'o'
    OUT 'r'
    HLT
DIVIDE:
    MOV C, A
    MOV D, ZERO
DIV_CONT:
    SUB C, B
    JZ DIV_NO_RESIDUE ; no division residue
    JC DIV_RESIDUE ; division residue
    ADD D, ONE
    JMP DIV_CONT
DIV_RESIDUE:
    ADD C, B
    JMP DIV_OUT
DIV_NO_RESIDUE:
    MOV C, ZERO
DIV_OUT:
    OUTH D
    OUTL D
    OUT '+'
    OUTH C
    OUTL C
    HLT
OUT_NUM:
    ; AA/BB
    OUT 0x0C ; Clear display
    OUT 0x0D ; goto display begin
    OUTH A
    OUTL A
    OUT '/'
    OUTH B
    OUTL B
    HLT
