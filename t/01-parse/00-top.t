#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

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


# vim: ft=perl6
