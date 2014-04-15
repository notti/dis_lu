#!/usr/bin/python

import sys
import ply.lex as lex
import ply.yacc as yacc

reserved = {
    'HLT'  : (0xF0, ('none',),),
    'MOV'  : (0x00, ('reg_imm', 'reg_reg'),),
    'ADD'  : (0x40, ('reg_imm', 'reg_reg'),),
    'SUB'  : (0x80, ('reg_imm', 'reg_reg'),),
    'SHL'  : (0xC0, ('reg',),),
    'SHR'  : (0xC8, ('reg',),),
    'JZ'   : (0xE1, ('imm', 'label'),),
    'JNZ'  : (0xE2, ('imm', 'label'),),
    'JC'   : (0xE4, ('imm', 'label'),),
    'JNC'  : (0xE8, ('imm', 'label'),),
    'JMP'  : (0xE0, ('imm', 'label'),),
    'OUTL' : (0xD0, ('reg',),),
    'OUTH' : (0xD8, ('reg',),),
    'OUT'  : (0xF8, ('imm',),),
}

register = {
    'A' : 0x0,
    'B' : 0x1,
    'C' : 0x2,
    'D' : 0x3,
    'ZERO' : 0x4,
    'ONE' : 0x5,
    'SWR' : 0x6,
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

lex.lex()

code = []
labels = {}

class CompilerError(Exception):
    pass

def syntax_error(text, lineno=None):
    x = CompilerError(text)
    x.lineno = lineno
    raise x

def p_statements(p):
    '''statements : 
                  | statements statement'''

def p_statement(p):
    '''statement : expression NL
                 | label
                 | address'''

def p_address(p):
    'address : IMMEDIATE DP'
    if len(code) > p[1]:
        syntax_error("Address %d already taken (now: @%d)" % (p[1], len(code)), p.lineno(1))
    code.extend([0] * (p[1] - len(code)))

def p_label(p):
    'label : LABEL DP'
    if p[1] in labels:
        syntax_error("Label %s already defined (original on line %d)" % (p[1], labels[p[1]][1]), p.lineno(1))
    labels[p[1]] = (len(code), p.lineno(1))

def p_empty_expression(p):
    'expression :'

def p_expression(p):
    'expression : OP'
    if 'none' not in p[1][1]:
        syntax_error("Wrong arguments to OP", p.lineno(1))
    code.append(p[1][0])

def p_expression_imm(p):
    'expression : OP IMMEDIATE'
    if 'imm' not in p[1][1]:
        syntax_error("Wrong arguments to OP", p.lineno(1))
    code.extend((p[1][0], p[2]))

def p_expression_label(p):
    'expression : OP LABEL'
    if 'label' not in p[1][1]:
        syntax_error("Wrong arguments to OP", p.lineno(1))
    code.extend((p[1][0], p[2]))

def p_expression_reg(p):
    'expression : OP REGISTER'
    if 'reg' not in p[1][1]:
        syntax_error("Wrong arguments to OP", p.lineno(1))
    code.append(p[1][0] | p[2])

def p_expression_reg_reg(p):
    'expression : OP REGISTER COLON REGISTER'
    if 'reg_reg' not in p[1][1]:
        syntax_error("Wrong arguments to OP", p.lineno(1))
    code.append(p[1][0] | p[2] | (p[4] << 3))

def p_expression_reg_imm(p):
    'expression : OP REGISTER COLON IMMEDIATE'
    if 'reg_imm' not in p[1][1]:
        syntax_error("Wrong arguments to OP", p.lineno(1))
    code.extend((p[1][0] | p[2] | (0x07 << 3), p[4]))

def p_error(p):
    syntax_error("Syntax error. Unexpected %s(%s)" % (p.type, p.value), p.lineno)

parser = yacc.yacc()

import argparse
argparser = argparse.ArgumentParser()
argparser.add_argument('infile', nargs='?', type=argparse.FileType('r'), default=sys.stdin, help='Input file')
argparser.add_argument('outfile', nargs='?', type=argparse.FileType('w'), default=sys.stdout, help='Output file')
argparser.add_argument('--coe', dest='coe', action='store_true', help='Write coe file')
argparser.add_argument('--template', dest='template', type=argparse.FileType('r'), help='Template vhd to embedd Memory')
args = argparser.parse_args()

for line in args.infile:
    try:
        parser.parse(line)
    except CompilerError as e:
        print(str(e), file=sys.stderr)
        sys.exit(-1)

def out(x):
    num = hex(x)[2:]
    if len(num) == 1:
        num = "0" + num
    return num

if args.coe:
    print("""memory_initialization_radix=16;
memory_initialization_vector=""", file=args.outfile)
else:
    if args.template:
        for line in args.template:
            if line == '%%\n':
                break
            print(line, file=args.outfile, end='')
    print("        (", file=args.outfile)

binary = []
for x in code:
    if isinstance(x, str):
        if x not in labels:
            print("Label %s undefined!" % x, file=sys.stderr)
            sys.exit(-1)
        binary.append(out(labels[x][0]))
    else:
        binary.append(out(x))

if args.coe:
    print(',\n'.join(binary), file=args.outfile, end=';\n')
else:
    print('\n'.join(['         x"%s",' % num for num in binary]), file=args.outfile)
    print("         others => (others => '0'));", file=args.outfile)
    if args.template:
        for line in args.template:
            print(line, file=args.outfile, end='')
print("""%d octets written.""" % len(code), file=sys.stderr)
