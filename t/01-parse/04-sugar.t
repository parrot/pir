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
    goto label
.end
});
ok($res, "goto label");

$res := parse($c, q{
.sub "foo"
    if $P0 goto label
.end
});
ok($res, "if \$P0 goto label");

$res := parse($c, q{
.sub "foo"
    if var goto label
.end
});
ok($res, "if var goto label");

# Officially constant is disallowed...
# TODO Relax it?
$res := parse($c, q{
.sub "foo"
    if 1 goto label
.end
});
ok(!$res, "if 1 goto label");



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
