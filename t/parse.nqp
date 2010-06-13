# nqp

# This file compiled to pir and used in tests.

Q:PIR{
    # We want Test::More features for testing. Not NQP's builtin.
    .include "test_more.pir"
    load_bytecode "pir.pbc"
};

sub parse($c, $code) {
    my $res := 0;
    try {
        $c.compile(:target('parse'), $code);
        $res := 1;
    }
    $res;
}
#
# Helper grammar to parse test data

grammar Test {
    rule TOP {
        ^
        <testcase>+
        $ || <.panic: "Can't parse test data">
    };

    token testcase {
        <start> <name> \n
        <body>
    }

    token start { ^^ '# TEST ' }
    regex name  { \N+ }

    token body  { <line>+ }
    token line  { <!before <start> > .*? \n }
};


our sub parse_tests($file)
{
    my $data  := slurp($file);
    my $match := Test.parse($data);
    $match<testcase>;
}

# vim: ft=perl6
