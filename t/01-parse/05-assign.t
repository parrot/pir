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


$res := parse($c, q{
.sub main
	.local pmc x
	x = new ["Hash"]
.end
});
ok($res, "Assign reorder with key");

$res := parse($c, q{
.sub main
	.local pmc x
	x = get_root_global ["Hash"], "bang"
.end
});
ok($res, "Assign reorder with key and param");

########## keyed
$res := parse($c, q{
.sub main
	.local pmc x, y
	x = y["Foo";"Bar";"Baz"]
.end
});
ok($res, "get keyed");

$res := parse($c, q{
.sub main
	.local pmc x, y
	y["Foo";"Bar";"Baz"] = 42
.end
});
ok($res, "set keyed");


$res := parse($c, q{
.sub main			
	.local string s
	s = ascii:"Hello World"
	s = binary:"Hello WOrld"
	s = unicode:"Hello world"
	s = iso-8859-1:"Hello world"		 
	s = utf8:unicode:"Hello World"
.end
});
todo($res, "String encodings");

done_testing();

# vim: ft=perl6
