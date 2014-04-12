#!/usr/bin/python

import sys

reserved = {
    'HLT'  : 0xF0,
    'MOV'  : 0x00,
    'ADD'  : 0x40,
    'SUB'  : 0x80,
    'SHL'  : 0xC0,
    'SHR'  : 0xC8,
    'JZ'   : 0xE1,
    'JNZ'  : 0xE2,
    'JC'   : 0xE4,
    'JNC'  : 0xE8,
    'JMP'  : 0xE0,
    'OUTL' : 0xD0,
    'OUTH' : 0xD8,
    'OUT'  : 0xF8,
}

register = {
    'A' : 0x0,
    'B' : 0x1,
    'C' : 0x2,
    'D' : 0x3,
    'SWR' : 0x4
}
def t_IMMEDIATE(t):
    r'(0[xX][0-9a-fA-F]+|[0-9]+)'
    t.value = int(t.value, 0)
    return t

def t_CHAR(t):
    r"'.'"
    t.value = ord(t.value[1])
    t.type = 'IMMEDIATE'
    return t


def t_LABEL(t):
    r'[A-Za-z][A-Za-z0-9_]*'
    if t.value in reserved:
        t.type = 'OP'
        t.value = reserved[t.value]
    if t.value in register:
        t.type = 'REGISTER'
        t.value = register[t.value]
    return t

t_COLON = r','
t_DP = r':'

def t_COMMENT(t):
    r';.*'
    pass

def t_NL(t):
    r'\n+'
    t.lexer.lineno += len(t.value)
    return t

t_ignore = ' \t'

def t_error(t):
    print("Illegal character '%s' on line %d" % (t.value[0], t.lexer.lineno))

tokens = ['OP', 'IMMEDIATE', 'REGISTER', 'LABEL', 'COLON', 'DP', 'NL']

import ply.lex as lex
lex.lex()

code = []
labels = {}

def p_statements(p):
    '''statements : 
                  | statements statement'''

def p_statement(p):
    '''statement : expression NL
                 | label
                 | address'''

def p_address(p):
    'address : IMMEDIATE DP'
    if len(code) >= p[1]:
        print("Address %d already taken on line %d (now: %d)" % (p[1], p.lineno(1), len(code)), file=sys.stderr)
        raise SyntaxError
    code.extend([0] * (p[1] - len(code)))

def p_label(p):
    'label : LABEL DP'
    if p[1] in labels:
        print("Label %s already defined on line %d" % (p[1], p.lineno(1)), file=sys.stderr)
        raise SyntaxError
    labels[p[1]] = len(code)

def p_empty_expression(p):
    'expression :'

def p_expression(p):
    'expression : OP'
    code.append(p[1])

def p_expression_imm(p):
    'expression : OP IMMEDIATE'
    code.extend((p[1], p[2]))

def p_expression_label(p):
    'expression : OP LABEL'
    code.extend((p[1], p[2]))

def p_expression_reg(p):
    'expression : OP REGISTER'
    code.append(p[1] | p[2])

def p_expression_reg_reg(p):
    'expression : OP REGISTER COLON REGISTER'
    code.append(p[1] | p[2] | (p[4] << 3))

def p_expression_reg_imm(p):
    'expression : OP REGISTER COLON IMMEDIATE'
    code.extend((p[1] | p[2] | (0x07 << 3), p[4]))

def p_error(p):
    print("Syntax error on line %d col %d; unexpected %s(%s)" % (p.lineno, p.lexpos, p.type, p.value), file=sys.stderr)
    raise SyntaxError

import ply.yacc as yacc

parser = yacc.yacc()

for line in sys.stdin:
    try:
        parser.parse(line)
    except:
        break

def out(x):
    num = hex(x)[2:]
    if len(num) == 1:
        num = "0" + num
    print('x"%s",' % num)

print("(")

for x in code:
    if isinstance(x, str):
        if x not in labels:
            print("Label %s undefined!" % x, file=sys.stderr)
            break
        out(labels[x])
    else:
        out(x)
print(" others => (others => '0'))")
