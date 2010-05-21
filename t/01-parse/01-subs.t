#! parrot-nqp

Q:PIR{
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

$res := parse($c, q{
.sub "foo" :main
.end
});

ok($res, ":main pragma parsed");

done_testing();



sub parse($c, $code) {
    $res := 0;
    try {
        $c.compile(:target('parse'), $code);
        $res := 1;
    }
    $res;
}

