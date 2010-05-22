#! /usr/bin/env parrot-nqp

Q:PIR{
    # We want Test::More features for testing. Not NQP's builtin.
    .include "test_more.pir"
    load_bytecode "pir.pbc"
};

my $c := pir::compreg__Ps('PIRATE');
ok(!pir::isnull__IP($c), "Compiler created");

my $res := parse($c, q{
.sub "main"
.end
});

ok($res, "Empty sub compiled");

$res := parse($c, q{
.sub "main" :foo
.end
});

ok(!$res, "Wrong pragma was caught");

for <main init load immediate postcomp anon method nsentry> -> $pragma {
$res := parse($c, qq{
.sub "foo" :$pragma
.end
});

ok($res, ":$pragma pragma parsed");
}

$res := parse($c, q{
.sub "foo" :init :load :anon
.end
});

ok($res, "Multiple pragmas parsed");

$res := parse($c, q{
.sub "foo" :vtable("get_string")
.end
});
ok($res, ":vtable pragma parsed");

$res := parse($c, q{
.sub "foo" :outer("outer")
.end
});
ok($res, ":outer pragma parsed");

$res := parse($c, q{
.sub "foo" :subid("subid")
.end
});
ok($res, ":subid pragma parsed");



done_testing();



sub parse($c, $code) {
    $res := 0;
    try {
        $c.compile(:target('parse'), $code);
        $res := 1;
    }
    $res;
}

