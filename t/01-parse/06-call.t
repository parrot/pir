#! /usr/bin/env parrot-nqp

pir::load_bytecode('nqp-setting.pbc');
pir::load_bytecode('t/common.pbc');

my $c := pir::compreg__Ps('PIRATE');
my $tests := parse_tests('t/data/call.txt');

for $tests -> $t {
    ok(parse($c, $t<body>), $t<name>);
}


done_testing();

# vim: ft=perl6
