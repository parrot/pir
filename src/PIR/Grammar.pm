#
# PIR Grammar.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Grammar is HLL::Grammar;

# Top-level rules.
method TOP() {
    my %*HEREDOC;

    my $*NAMESPACE;
    my $*HLL;
    self.top;
}

rule top {
    [ <compilation_unit> <.terminator> ]*
    [ $ || <.panic: "Confused"> ]
}

proto token compilation_unit { <...> }

rule compilation_unit:sym<sub> {
    #<?DEBUG>
    <.newpad>
    '.sub' <subname>
    [
    || [ <.ws> <sub_pragma> ]*
    || <.panic: "Unknown .sub pragma">
    ]
    <ws> <.nl>

    <param_decl>*

    [
    || <statement>
    || <!before '.end'> <.panic: "Erm... What?">
    ]*
    '.end'
}



rule compilation_unit:sym<.namespace>   { <sym> <namespace_key> }
rule compilation_unit:sym<.loadlib>     { <sym> <quote> }
rule compilation_unit:sym<.HLL>         { <sym> <quote> }
rule compilation_unit:sym<.line>        { <sym> \d+ ',' <quote> }
rule compilation_unit:sym<.include>     { <sym> <quote> }
rule compilation_unit:sym<.macro_const> { <sym> <ident> <value> }

# Macros. TODO. Args can be multilines enclosed in { }.
rule compilation_unit:sym<macro> {
    '.macro' <name=ident> [ '(' <args>* ')' ]? <.nl>
    [
    || <statement>
    || <macro_statement> <.nl>
    || <!before '.endm'> <.panic: "Can't find end of macro definition">
    ]*
    '.endm'
}

proto regex macro_statement { <...> }
rule  macro_statement:sym<.macro_local> { <sym> <pir_type> [ <ident> ] ** ',' }
token macro_statement:sym<.label> { <sym> <.ws> '$' <ident> ':' <pir_instruction>? }

#token compilation_unit:sym<pragma> { }

proto regex sub_pragma { <...> }
token sub_pragma:sym<main>       { ':' <sym> }
token sub_pragma:sym<init>       { ':' <sym> }
token sub_pragma:sym<load>       { ':' <sym> }
token sub_pragma:sym<immediate>  { ':' <sym> }
token sub_pragma:sym<postcomp>   { ':' <sym> }
token sub_pragma:sym<anon>       { ':' <sym> }
token sub_pragma:sym<method>     { ':' <sym> }
token sub_pragma:sym<lex>        { ':' <sym> }

token sub_pragma:sym<nsentry>    { ':' <sym> [ '(' <string_constant> ')' ]? }
token sub_pragma:sym<vtable>     { ':' <sym> [ '(' <string_constant> ')' ]? }
token sub_pragma:sym<outer>      { ':' <sym> '(' <subname> ')' }
token sub_pragma:sym<subid>      { ':' <sym> '(' <string_constant> ')' }

token sub_pragma:sym<multi>      { ':' <sym> '(' [ [<.ws><multi_type><.ws>] ** ',' ]? ')' }

# TODO Do more strict parsing.
token multi_type {
    | '_'               # any
    | <quote>           # "Foo"
    | <namespace_key>   # ["Foo";"Bar"]
    | <ident>           # Integer
}

rule statement_list {
    | $
    | <statement>*
}

# Don't put newline here.
rule statement {
    || <pir_directive>
    ||
        <labeled_instruction> <.nl>
        <process_heredoc>?
}

token process_heredoc {
    $<content>=[.*?] ^^ $<heredoc><ident> $$
    {
        %*HEREDOC<node><doc> := $/;
    }
}


# Combination of flags/type checked in Actions
rule param_decl {
    '.param' <pir_type> <name=ident> <param_flag>? <.nl>
}

# Various .local, .lex, etc
proto regex pir_directive { <...> }
rule pir_directive:sym<.local>      { <sym> <pir_type> [ <ident> ] ** ',' }
rule pir_directive:sym<.lex>        { <sym> <string_constant> ',' <pir_register> }
rule pir_directive:sym<.file>       { <sym> <string_constant> }
rule pir_directive:sym<.line>       { <sym> <int_constant> }
rule pir_directive:sym<.annotate>   { <sym> <string_constant> ',' <constant> }
rule pir_directive:sym<.include>    {
    <sym> <quote>
    {
        my $filename    := ~$<quote>;
        $filename       := pir::substr__ssii($filename, 1, pir::length__is($filename) -2 );
        my $include     := slurp($filename);
        my $compiler    := pir::compreg__ps('PIRATE');
        my $grammar := $compiler.parsegrammar();
        my $actions := $compiler.parseactions();
        $<include>  := $grammar.parse($include, :p<0>, :actions($actions), :rule<statement_list>);
        #_dumper($<include>);
        $<quote><statement> := $<include><statement>;
    }
}

# PCC
rule pir_directive:sym<.begin_call>     { <sym> }
rule pir_directive:sym<.end_call>       { <sym> }
rule pir_directive:sym<.begin_return>   { <sym> }
rule pir_directive:sym<.end_return>     { <sym> }
rule pir_directive:sym<.begin_yield>    { <sym> }
rule pir_directive:sym<.end_yield>      { <sym> }

rule pir_directive:sym<.call>       { <sym> <value> [',' <continuation=pir_register> ]? }
rule pir_directive:sym<.meth_call>  { <sym> <value> [',' <continuation=pir_register> ]? }
rule pir_directive:sym<.nci_call>   { <sym> <value> [',' <continuation=pir_register> ]? }

rule pir_directive:sym<.invocant>   { <sym> <value> }
rule pir_directive:sym<.set_arg>    { <sym> <value> <arg_flag>? }
rule pir_directive:sym<.set_return> { <sym> <value> <arg_flag>? }
rule pir_directive:sym<.set_yield>  { <sym> <value> <arg_flag>? }
rule pir_directive:sym<.get_result> { <sym> <value> <result_flag>? }

rule pir_directive:sym<.return>     { <sym> '(' <args>? ')' }
rule pir_directive:sym<.yield>      { <sym> '(' <args>? ')' }

rule pir_directive:sym<.tailcall>   { <sym> <call> }

# PIR Constants
rule pir_directive:sym<.const>       { <sym> <const_declaration> }
rule pir_directive:sym<.globalconst> { <sym> <const_declaration> }

proto regex const_declaration { <...> }
rule const_declaration:sym<int> {
    <sym> <ident> '=' <int_constant>
}
rule const_declaration:sym<num> {
    <sym> <ident> '=' <float_constant>
}
rule const_declaration:sym<string> {
    <sym> <ident> '=' <string_constant>
}
# .const "Sub" foo = "sub_id"
rule const_declaration:sym<pmc> {
    <string_constant> <variable> '=' <string_constant>
}


rule labeled_instruction {
    <label>? [ <pir_instruction> || <op> ]?
}

token label { <ident> ':' }

# raw pasm ops.
# TODO Check in OpLib
rule op {
    <name=ident> <op_params>?
}

rule op_params {
    <op_param> ** ','
}

token op_param {
    <value> | <namespace_key>
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

# Manual LTM
rule pir_instruction:sym<assign> {
    <variable> '=' <value> <?before <ws> \v>
}

rule pir_instruction:sym<op_assign_long_long_long_name> {
    <variable> '=' <op=ident> <op_params> <?before <ws> \v>
}

rule pir_instruction:sym<unary> {
    <variable> '=' <unary> <value>
}

# Manual LTM
rule pir_instruction:sym<binary_math> {
    <variable> '=' <lhs=value> <mathop> <rhs=value> <?before <ws> \n>
}
rule pir_instruction:sym<binary_logic> {
    <variable> '=' <lhs=value> <relop> <rhs=value> <?before <ws> \n>
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

rule pir_instruction:sym<get_keyed_sugared> {
    <lhs=variable> '=' <rhs=variable> <pir_key> <?before <ws> \v>
}

rule pir_instruction:sym<get_keyed> {
    'set' <lhs=variable> ',' <rhs=variable> <pir_key>
}

rule pir_instruction:sym<set_keyed_sugared> {
    <variable> <pir_key> '=' <value>
}

rule pir_instruction:sym<set_keyed> {
    'set' <variable> <pir_key> ',' <value>
}

#delete only has 2 args so a sugared form doesn't make sense
rule pir_instruction:sym<delete> {
    'delete' <variable> <pir_key>
}

rule pir_instruction:sym<exists_sugared> {
    <lhs=variable> '=' 'exists' <rhs=variable> <pir_key>
}

rule pir_instruction:sym<exists> {
    'exists' <lhs=variable> ',' <rhs=variable> <pir_key>
}

rule pir_instruction:sym<defined_sugared> {
     <lhs=variable> '=' 'defined' <rhs=variable> <pir_key>
}

rule pir_instruction:sym<defined> {
    'defined' <lhs=variable> ',' <rhs=variable> <pir_key>
}


# Short PCC call.
proto regex call { <...> }
rule call:sym<pmc>     { <variable> '(' <args>? ')' }
rule call:sym<sub>     { <quote> '(' <args>? ')' }
rule call:sym<ident>   { <ident> '(' <args>? ')' }
rule call:sym<dynamic> { <invocant=value> '.' <variable> '(' <args>? ')' }
rule call:sym<method>  { <invocant=value> '.' <quote> '(' <args>? ')' }

rule args {
    <arg> ** ','
}

rule arg {
    | <quote> '=>' <value>
    | <value> <arg_flag>?
}

rule results {
    <result> ** ','
}

rule result {
    <variable> <result_flag>?
}

proto token arg_flag { <...> }
token arg_flag:sym<:flat>       { <sym> <?before <ws> [ ',' | ')' ]> } # LTM...
rule  arg_flag:sym<flat named>  {
    | ':flat' ':named'
    | ':named' ':flat'
}
token arg_flag:sym<named_flag>    { <named_flag> }

proto token param_flag { <...> }
token param_flag:sym<:call_sig>     { <sym> } # TODO call_sig can be only one.
token param_flag:sym<:slurpy>       { <sym> <?before <ws> [ ',' | ')' | \v ]> } # LTM...
rule  param_flag:sym<slurpy named>  {
    | ':slurpy' ':named'
    | ':named' ':slurpy'
}
token param_flag:sym<:optional>     { <sym> }
token param_flag:sym<:opt_flag>     { <sym> }
token param_flag:sym<named_flag>    { <named_flag> }

proto token result_flag { <...> }
token result_flag:sym<:slurpy>       { <sym> <?before <ws> [ ',' | ')' | \v ]> } # LTM...
rule  result_flag:sym<slurpy named>  {
    | ':slurpy' ':named'
    | ':named' ':slurpy'
}
token result_flag:sym<:optional>     { <sym> }
token result_flag:sym<:opt_flag>     { <sym> }
token result_flag:sym<named_flag>    { <named_flag> }

rule named_flag {
    ':named' [ '(' <quote> ')' ]?
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
    '$' <type=INSP> <reg_number>
}

token INSP {
     I | N | S | P
}

token reg_number {
    <digit>+
}

token variable {
    | <pir_register>
    | <!before keyword> <ident>  # TODO Check it in lexicals
    | '.' <ident>                # Macro
}

token subname {
    | <quote>
    | <ident>
}

token terminator { $ | <.nl> }

rule namespace_key { '[' [ <quote> ** ';' ] ? ']' }

rule pir_key { '[' <value> ** ';' ']' }

token keyword {
    | goto | if | int | null
    | num | pmc | string | unless
}

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
token string_constant {
    [
    | <quote>
    | <typed_string>
    |  $<heredoc>=['<<' <heredoc_start>] # Heredoc
    ]
    { %*HEREDOC<node> := $/; $<bang> := "FOO"; }
}

token typed_string{
    [ <encoding> ':' ]?  <charset> ':' <?[\"]> <quote_EXPR: ':q'>
}

token encoding {
    [
    | 'fixed_8' | 'ucs2' | 'utf8' | 'utf16'
    ]
}

token charset {
    [
    | 'ascii' | 'binary' | 'iso-8859-1' | 'unicode'
    ]
}

token heredoc_start {
    | <ident>
    | '"' <ident> '"'
    | "'" <ident> "'"
}

proto token quote { <...> }
token quote:sym<apos> { <?[\']> <quote_EXPR: ':q'>  }
token quote:sym<dblq> { <?[\"]> <quote_EXPR: ':q'> }

token nl { \v+ }

# Any "whitespace" including pod comments
token ws {
    <!ww>
        [
        | ^^ \h* \v+ # newlines accepted only by themselfs
        | ^^ '#' \N* \n
        | '#' \N*
        | ^^ <.pod_comment>
        | \h+
        ]*
}

token pod_comment {
    ^^ '=' <pod_directive>
    .*? \n '=cut' \n
}

# Don't be very strict on pod comments (for now?)
token pod_directive { <ident> }

token newpad { <?> }

INIT {
    pir::load_bytecode("nqp-setting.pbc");
};
# vim: ft=perl6
