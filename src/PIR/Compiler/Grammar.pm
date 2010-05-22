#
# PIR Grammar.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Grammar is HLL::Grammar;

# Top-level rules.
rule TOP {
    [ <compilation_unit> <.terminator> ]*
    [ $ || <panic: "Confused"> ]
}

proto token compilation_unit { <...> }

rule compilation_unit:sym<sub> {
    <.newpad>
    '.sub' <subname> 
    [
    || [ <.ws> <sub_pragma> ]*
    || <panic: "Unknown .sub pragma">
    ]
    \h* <.nl>

    <param_decl>*

    [
    || <statement>
    || <!before '.end'> <panic: "Erm... What?">
    ]*
    '.end'
}



rule compilation_unit:sym<namespace> {
    '.namespace' '[' <namespace_key>? ']'
}

rule compilation_unit:sym<loadlib> {
    '.loadlib' <quote>
}

rule compilation_unit:sym<HLL> {
    '.HLL' <quote>
}

#token compilation_unit:sym<pragma> { }

proto regex sub_pragma { <...> }
token sub_pragma:sym<main>       { ':' <sym> }
token sub_pragma:sym<init>       { ':' <sym> }
token sub_pragma:sym<load>       { ':' <sym> }
token sub_pragma:sym<immediate>  { ':' <sym> }
token sub_pragma:sym<postcomp>   { ':' <sym> }
token sub_pragma:sym<anon>       { ':' <sym> }
token sub_pragma:sym<method>     { ':' <sym> }
token sub_pragma:sym<nsentry>    { ':' <sym> }

token sub_pragma:sym<vtable>     { ':' <sym> '(' <string_constant> ')' }
token sub_pragma:sym<outer>      { ':' <sym> '(' <string_constant> ')' }
token sub_pragma:sym<subid>      { ':' <sym> '(' <string_constant> ')' }

token sub_pragma:sym<multi>      { ':' <sym> '(' [<.ws><multi_type><.ws>] ** ',' ')' }

# TODO Do more strict parsing.
token multi_type {
    | '_'               # any
    | <quote>           # "Foo"
    | '[' <namespace_key> ']' # ["Foo";"Bar"]
    | <ident>           # Integer
}

rule statement_list {
    | $
    | <statement>*
}

# Don't put newline here.
rule statement {
    [
    || <pir_directive>
    || <labeled_instruction>
    ]
    <.nl>
}

# TODO Some of combination of flags/type doesn't make any sense
rule param_decl {
    '.param' <pir_type> <name=ident> <get_flags>* <.nl>
}

token get_flags {
    | ':slurpy'
    | ':optional'
    | ':opt_flag'
    | <named_flag>
}

rule named_flag {
    ':named' [ '(' <quote> ')' ]?
}

# Various .local, .lex, etc
proto regex pir_directive { <...> }
rule pir_directive:sym<local> {
    '.local' <pir_type> [ <ident> ] ** ','
}

rule pir_directive:sym<lex> {
    '.lex' <string_constant> ',' <pir_register>
}

rule pir_directive:sym<const> {
    '.const' <const_declaration>
}

rule pir_directive:sym<globalconst> {
    '.globalconst' <const_declaration>
}

proto regex const_declaration { <...> }
rule const_declaration:sym<int> {
    <sym> <variable> '=' <int_constant>
}
rule const_declaration:sym<num> {
    <sym> <variable> '=' <float_constant>
}
rule const_declaration:sym<string> {
    <sym> <variable> '=' <string_constant>
}
# .const "Sub" foo = "sub_id"
rule const_declaration:sym<pmc> {
    <string_constant> <variable> '=' <string_constant>
}

rule pir_directive:sym<file> {
    '.file' <string_constant>
}
rule pir_directive:sym<line> {
    '.line' <int_constant>
}
rule pir_directive:sym<annotate> {
    '.annotate' <string_constant> ',' <constant>
}

rule labeled_instruction {
    <label>? [ <pir_instruction> | <op> ]?
}

token label { <ident> ':' }

# raw pasm ops.
# TODO Check in OpLib
rule op {
    <op=ident> <op_params>?
}

rule op_params {
    [ <value> | <pir_key> ] ** ','
}

# Some syntax sugar
proto regex pir_instruction { <...> }

rule pir_instruction:sym<goto> { 'goto' <ident> }

rule pir_instruction:sym<if> {
    'if' <variable> 'goto' <ident>
}
rule pir_instruction:sym<unless> {
    'unless' <variable> 'goto' <ident>
}
rule pir_instruction:sym<if_null> {
    'if' 'null' <variable> 'goto' <ident>
}
rule pir_instruction:sym<unless_null> {
    'unless' 'null' <variable> 'goto' <ident>
}
rule pir_instruction:sym<if_op> {
    'if' <lhs=value> <relop> <rhs=value> 'goto' <ident>
}
rule pir_instruction:sym<unless_op> {
    'unless' <lhs=value> <relop> <rhs=value> 'goto' <ident>
}

# XXX Conflicting with "op_assign"
rule pir_instruction:sym<assign> {
    <variable> '=' <value>
}

rule pir_instruction:sym<op_assign> {
    <variable> '=' <op=ident> <op_params>
}

rule pir_instruction:sym<unary> {
    <variable> '=' <unary> <value>
}

rule pir_instruction:sym<binary_math> {
    <variable> '=' <lhs=value> <mathop> <rhs=value>
}
rule pir_instruction:sym<binary_logic> {
    <variable> '=' <lhs=value> <relop> <rhs=value>
}


rule pir_instruction:sym<inplace> {
    <variable> <mathop> '=' <rhs=value>
}


rule pir_instruction:sym<call> {
    <call>
}

rule pir_instruction:sym<call_assign> {
    <variable> '=' <call>
}

rule pir_instruction:sym<call_assign_many> {
    '(' <results>? ')' '=' <call>
}

rule pir_instruction:sym<get_keyed> {
    <variable> '=' <keyed_var>
}
rule pir_instruction:sym<set_keyed> {
    <keyed_var> '=' <value>
}

token keyed_var {
    <variable> <pir_key>
}


rule pir_instruction:sym<return> {
    '.return' '(' <params>? ')'
}

rule pir_instruction:sym<tailcall> {
    '.tailcall' <call>
}

proto regex call { <...> }
token call:sym<pmc>     { <variable> '(' <params>? ')' }
token call:sym<sub>     { <quote> '(' <params>? ')' }
token call:sym<dynamic> { <value> '.' <variable> '(' <params>? ')' }
token call:sym<method>  { <value> '.' <quote> '(' <params>? ')' }

rule params {
    <param> ** ','
}

rule param {
    <value> <param_flag>*
}

token param_flag {
    | ':flat'
    | <named_flag>
}

rule results {
    <result> ** ','
}

rule result {
    <variable> <result_flag>*
}

token result_flag {
    | ':slurpy'
    | ':optional'
    | ':opt_flag'
    | <named_flag>
}

token unary {
    '!' | '-' | '~'
}

token binary {
    | <mathop>
    | <relop>
}

token mathop {
    | '+' | '-' | '**' | '/' | '%' | '*'    # maths
    | '.'                                   # for strings only
    | '>>>'                                 # logical shift
    | '<<' | '>>'                           # arithmetic shift
    | '&&' | '||' | '~~'                    # logical
    | '&' | '|' | '~'                       # bitwise
}

token relop {
    '<=' | '<' | '==' | '!=' | '>=' | '>'
}


token value {
    | <constant>
    | <variable>
}

token pir_type {
    | int
    | num
    | pmc
    | string
}

# Up to 100 registers
token pir_register {
    '$' <type=INSP> <digit>+
}

token INSP {
     I | N | S | P
}

token variable {
    | <pir_register>
    | <ident>  # TODO Check it in lexicals
}

token subname {
    | <string_constant>
    | <ident>
}

token pod_comment {
    ^^ '=' <pod_directive>
    .* \n
    ^^ '=cut'
}

token terminator { $ | <.nl> }

rule namespace_key { <quote> ** ';' }

rule pir_key { '[' <value> ** ';' ']' }

token constant {
    | <float_constant>
    | <string_constant>
    | <int_constant>
}

token int_constant {
      '0b' \d+
    | '0x' \d+
    | ['-']? \d+
}

token float_constant {
    ['-']? \d+\.\d+
}

# There is no iterpolation of strings in PIR
# TODO charset/encoding handling.
token string_constant { <quote> }

proto token quote { <...> }
token quote:sym<apos> { <?[']> <quote_EXPR: ':q'>  }
token quote:sym<dblq> { <?["]> <quote_EXPR: ':q'> }

# Don't be very strict on pod comments (for now?)
token pod_directive { <ident> }

token nl { \v+ }

# Any "whitespace" including pod comments
token ws {
    <!ww>
        [
        | ^^ \v+ # newlines accepted only by themselfs
        | '#' \N*
        | ^^ <.pod_comment>
        | \h+
        ]*
}

# Special rule to push new Lexpad.
token newpad { <?> } # always match.

# vim: ft=perl6
