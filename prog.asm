; SWR switch register
; A,B,C,D gp register
; PC

; 00 start
; 08 left
; 10 right
; 18 push

    OUT '?'
    HLT

0x08:               ; left interrupt
    SHR SWR
    JC LEFT_A
    SUB B, 1
    JMP OUT_NUM
LEFT_A:
    SUB A, 1
    JMP OUT_NUM

0x10:               ; right interrupt
    SHR SWR
    JC RIGHT_A
    ADD B, 1
    JMP OUT_NUM
RIGHT_A:
    ADD A, 1
    JMP OUT_NUM

0x18:               ; push interrupt
    OUT '='
    SUB B, 0
    JNZ DIVIDE
    OUT 'E'
    OUT 'r'
    OUT 'r'
    OUT 'o'
    OUT 'r'
    HLT
DIVIDE:
    MOV C, A
    MOV D, 0
DIV_CONT:
    SUB C, B
    JZ DIV_NO_RESIDUE ; no division residue
    JC DIV_RESIDUE ; division residue
    ADD D, 1
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
