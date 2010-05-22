#! /usr/bin/env parrot-nqp

Q:PIR{
    # We want Test::More features for testing. Not NQP's builtin.
    .include "test_more.pir"
    load_bytecode "pir.pbc"
};

my $c := pir::compreg__Ps('PIRATE');
my $res;

for <int number string pmc> -> $type {
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
    .local number foo, bar
.end
});
ok($res, "Multiple .local");


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
