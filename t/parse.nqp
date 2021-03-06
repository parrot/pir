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

grammar TestDataGrammar {
    rule TOP {
        <testcase>+
        $ || <.panic: "Can't parse test data">
    };

    token testcase {
        <start> <name> \n
        <body>
    }

    token start { ^^ '# TEST ' }
    token name  { \N+ }

    token body  { <line>+ }
    token line  { <!before <start> > .*? \n }
};


our sub parse_tests($file)
{
    pir::load_bytecode('nqp-setting.pbc');
    my $data  := slurp($file);
    my $match := TestDataGrammar.parse($data);
    $match<testcase>;
}

our sub run_tests_from_datafile($file, :$keep_going?)
{
    my $c     := pir::compreg__Ps('PIRATE');
    my $tests := parse_tests($file);

    for $tests -> $t {
        ok(parse($c, $t<body>), $t<name>);
    }

    done_testing() unless $keep_going;
}

# vim: ft=perl6
