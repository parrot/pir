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
    '.sub' <.ws> <subname> [ <.ws> <sub_pragma> ]* <.nl>
    <statement_list>
    '.end' <.terminator>
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

#token sub_pragma:sym<multi>      { ':' <sym> '(' <key> ')' }


rule statement_list {
    | $
    | <statement>*
}

# Don't put newline here.
rule statement {
    | <pir_directive>
}

# Various .local, .lex, etc
proto regex pir_directive { <...> }
rule pir_directive:sym<local> {
    '.local' <pir_type> [<.ws><ident><.ws>] ** ',' <.nl>
}
rule pir_directive:sym<lex> {
    '.lex' <string_constant> ',' <pir_register> <.nl>
}


token pir_type {
    | int
    | number
    | pmc
    | string
}

token pir_register {
    '$' <type=INSP> <integer>
}

token INSP {
     I | N | S | P
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

# There is no iterpolation of strings in PIR
proto token string_constant { <...> }
token string_constant:sym<apos> { <?[']> <quote_EXPR: ':q'>  }
token string_constant:sym<dblq> { <?["]> <quote_EXPR: ':q'> }

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

