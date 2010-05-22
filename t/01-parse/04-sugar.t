#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

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

$res := parse($c, q{
.sub "foo"
    if null var goto label
.end
});
ok($res, "if null var goto label");

$res := parse($c, q{
.sub "foo"
    unless null $P42 goto label
.end
});
ok($res, "unless null \$P42 goto label");

# Officially constant is disallowed...
# TODO Relax it?
$res := parse($c, q{
.sub "foo"
    if 1 goto label
.end
});
ok(!$res, "if 1 goto label");

$res := parse($c, q{
.sub "foo"
    if var < $P0 goto label
.end
});
ok($res, "if var < \$P0 goto label");

$res := parse($c, q{
.sub "foo"
    unless $S0 == $P0 goto label
.end
});
ok($res, "unless \$S0 == \$P0 goto label");


done_testing();

# vim: ft=perl6
