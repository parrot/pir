#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

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


$res := parse($c, q{
.sub "foo"
    .local string foo
    trace 0
.end
});
ok($res, "trace 0");

$res := parse($c, q{
.sub "foo"
    .local string foo
    substr $S0, foo, 0, 1
.end
});
ok($res, "substr \$S0, foo, 0, 1");

$res := parse($c, q{
.sub "foo"
    .local pmc foo
    new foo, "Hash"
.end
});
ok($res, "new foo, 'Hash'");

$res := parse($c, q{
.sub "foo"
    .local pmc foo
    new foo, ["parrot";"Hash"]
.end
});
ok($res, "new foo, ['parrot';'Hash']");


done_testing();

# vim: ft=perl6
