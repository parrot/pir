#! /usr/bin/env parrot-nqp

Q:PIR{
    # We want Test::More features for testing. Not NQP's builtin.
    .include "test_more.pir"
    load_bytecode "pir.pbc"
};

my $c := pir::compreg__Ps('PIRATE');


my $res := parse($c, q{
.sub "main"
    .local pmc foo
.end
});
ok($res, ".local pmc foo");

$res := parse($c, q{
.sub "main"
    .local pmc foo, bar
.end
});
ok($res, ".local pmc foo, bar");

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
