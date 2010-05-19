#
# PIR Grammar.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Grammar is HLL::Grammar;

# Top-level rules.
rule TOP {
    <compilation_unit>
}

token compilation_unit {
    <.newpad>
    <statement_list>
    [ $ || <panic: "Confused"> ]
}

rule statement_list {
    | $
    | <statement>*
}

# Don't put newline here.
rule statement {
    <EXPR>
}

token terminator {
    | $
    | \n
}

token pod_comment {
    ^^ '=' <pod_directive>
    .* \n
    ^^ '=cut'
}

# Don't be very strict on pod comments (for now?)
token pod_directive { <ident> }

# Any "whitespace" including pod comments
token ws {
    <!ww>
        [ \v+
        | '#' \N*
        | ^^ <.pod_comment>
        | \h+
        ]*
}

# Special rule to push new Lexpad.
token newpad { <?> } # always match.

# vim: ft=perl6

