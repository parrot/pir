#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

my $c := pir::compreg__Ps('PIRATE');
my $res;

$res := parse($c, q{
.sub "main"
	a = - x
	a = ! x
	a = ~ x
.end
});
ok($res, "Unary operations");

$res := parse($c, q{
.sub main
	.local int x,y,z,a,b,c
	x = 1 + 2
	x = 1 * 2
	y = 2 / 4
	y = 2 - 4
	z = 2 ** 4
	z = 2 % 1
	a = b &  c
	a = b && c
	a = b |  c
	a = b || c
	a = b << c
	a = b >> c
	a = b >>> c
.end
});
ok($res, "Binary operations");

$res := parse($c, q{
.sub main
	.local int x,y,z,a,b,c
	a = b <  c
	a = b <= c
	a = b == c
	a = b != c
	a = b >= c
	a = b >  c
.end
});
ok($res, "Binary logical operations");


$res := parse($c, q{
.sub main
	.local int x
	x = 0
	x += 1
	x *= 5
	x /= 2
	x -= 1
	x %= 2
	x <<= 1
	x >>= 1
	x >>>= 1
.end
});
ok($res, "In-place assign");

$res := parse($c, q{
.sub main
	.local pmc x
	x = new "Hash"
.end
});
ok($res, "Assign reorder");



done_testing();

# vim: ft=perl6
