#! /usr/bin/env parrot-nqp

Q:PIR{
    # We want Test::More features for testing. Not NQP's builtin.
    .include "test_more.pir"
    load_bytecode "pir.pbc"
};

my $c := pir::compreg__Ps('PIRATE');
my $res;

$res := parse($c, q{
.HLL "PIR"
});
ok($res, ".HLL");

$res := parse($c, q{
.namespace []
});
ok($res, ".namespace []");

$res := parse($c, q{
.namespace ["Foo";"Bar"]
});
ok($res, ".namespace ['Foo';'Bar']");

$res := parse($c, q{
.loadlib "pir.pbc"
});
ok($res, ".loadlib");



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
