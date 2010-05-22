#! /usr/bin/env parrot-nqp

Q:PIR{
    # We want Test::More features for testing. Not NQP's builtin.
    .include "test_more.pir"
    load_bytecode "pir.pbc"
};

my $c := pir::compreg__Ps('PIRATE');
my $res;

$res := parse($c, q{
.sub "foo"
    noop
.end
});
ok($res, "noop parsed");

$res := parse($c, q{
.sub "foo"
    label: noop
.end
});
ok($res, "label: noop parsed");

$res := parse($c, q{
.sub "foo"
    label:
.end
});
ok($res, "label: parsed");


done_testing();



sub parse($c, $code) {
    $res := 0;
    try {
        $c.compile(:target('parse'), $code);
        $res := 1;
    }
    $res;
}

# vim: ft=perl6
