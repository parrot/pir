#
# PIR Grammar.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Grammar is HLL::Grammar;

# Top-level rules.
rule TOP {
    <compilation_unit>*
    [ $ || <panic: "Confused"> ]
}

proto token compilation_unit { <...> }

token compilation_unit:sym<sub> {
    <.newpad>
    '.sub' <.ws> <subname> 
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
    '.end' <.terminator>
}



token compilation_unit:sym<namespace> {
    '.namespace' <.ws> '[' <namespace_key>? ']' <.terminator>
}

token compilation_unit:sym<loadlib> {
    '.loadlib' <.ws> <quote> <.terminator>
}

token compilation_unit:sym<HLL> {
    '.HLL' <.ws> <quote> <.terminator>
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
    || <pir_directive>
    || <labeled_instruction>
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
    '.local' <pir_type> [<.ws><ident><.ws>] ** ',' <.nl>
}

rule pir_directive:sym<lex> {
    '.lex' <string_constant> ',' <pir_register> <.nl>
}

rule pir_directive:sym<const> {
    '.const' <const_declaration> <.nl>
}

rule pir_directive:sym<globalconst> {
    '.globalconst' <const_declaration> <.nl>
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
    '.file' <string_constant> <.nl>
}
rule pir_directive:sym<line> {
    '.line' <int_constant> <.nl>
}
rule pir_directive:sym<annotate> {
    '.annotate' <string_constant> ',' <constant> <.nl>
}

token labeled_instruction {
    <.ws> [ <label=ident> ':' <.ws>]? [ <pir_instruction> | <op> ]? <.nl>
}

# raw pasm ops.
# TODO Check in OpLib
token op {
    <op=ident> [ [<.ws> [ <value> | <pir_key> ]<.ws>] ** ',']?
}

# Some syntax sugar
proto regex pir_instruction { <...> }

token pir_instruction:sym<goto> { 'goto' <.ws> <ident> }

token pir_instruction:sym<if>   {
    'if' <.ws> <variable> <.ws> 'goto' <.ws> <ident>
}
token pir_instruction:sym<unless>   {
    'unless' <.ws> <variable> <.ws> 'goto' <.ws> <ident>
}
token pir_instruction:sym<if_null>   {
    'if' <.ws> 'null' <.ws> <variable> <.ws> 'goto' <.ws> <ident>
}
token pir_instruction:sym<unless_null>   {
    'unless' <.ws> 'null' <.ws> <variable> <.ws> 'goto' <.ws> <ident>
}
token pir_instruction:sym<if_op>   {
    'if' <.ws> <lhs=value> <.ws> <relop> <.ws> <rhs=value>
         <.ws> 'goto' <.ws> <ident>
}
token pir_instruction:sym<unless_op>   {
    'unless' <.ws> <lhs=value> <.ws> <relop> <.ws> <rhs=value>
         <.ws> 'goto' <.ws> <ident>
}

token pir_instruction:sym<assign>   {
    <variable> <.ws> '=' <.ws> <value>
}

token pir_instruction:sym<unary>   {
    <variable> <.ws> '=' <.ws> <unary> <.ws> <value>
}

token pir_instruction:sym<binary_math>   {
    <variable> <.ws> '=' <.ws> <lhs=value> <.ws> <mathop> <.ws> <rhs=value>
}
token pir_instruction:sym<binary_logic>   {
    <variable> <.ws> '=' <.ws> <lhs=value> <.ws> <relop> <.ws> <rhs=value>
}


token pir_instruction:sym<inplace>   {
    <variable> <.ws> <mathop> '=' <.ws> <rhs=value>
}

token pir_instruction:sym<op_assign>   {
    <variable> <.ws> '=' <.ws> <op=ident> [ [<.ws><value><.ws>] ** ',']?
}

# TODO 
token pir_instruction:sym<call> {
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

