#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

my $c := pir::compreg__Ps('PIRATE');
my $res;

########## .local

for <int num string pmc> -> $type {
    $res := parse($c, qq{
    .sub "main"
        .local $type foo
    .end
    });
    ok($res, ".local $type foo");
}

$res := parse($c, q{
.sub "main"
    .local pmc foo, bar
.end
});
ok($res, ".local pmc foo, bar");

$res := parse($c, q{
.sub "main"
    .local wrongtype foo
.end
});
ok(!$res, ".local wrongtype foo not parsed");

$res := parse($c, q{
.sub "main"
    .local pmc foo, bar
    .local int foo, bar
    .local string foo, bar
    .local num foo, bar
.end
});
ok($res, "Multiple .local");

########## .lex
$res := parse($c, q{
.sub "main"
    .lex "$!", $P0
.end
});
ok($res, ".lex parsed");

########## .const
$res := parse($c, q{
.sub "main"
    .const string answer = "42"
.end
});
ok($res, ".const string");

$res := parse($c, q{
.sub "main"
    .const int answer = 42
.end
});
ok($res, ".const int");

$res := parse($c, q{
.sub "main"
    .const num answer = 42.0
.end
});
ok($res, ".const num");

$res := parse($c, q{
.sub "main"
    .const "Sub" answer = "42"
.end
});
ok($res, ".const 'Sub'");

$res := parse($c, q{
.sub "main"
    .file "test.pir"
    .line 42
.end
});
ok($res, ".file/.line");

$res := parse($c, q{
.sub "main"
    .annotate "file", "test.p6"
    .annotate "line", 42
.end
});
ok($res, ".annotate");

done_testing();

# vim: ft=perl6
