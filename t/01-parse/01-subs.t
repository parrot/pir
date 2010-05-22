#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

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

$res := parse($c, q{
.sub "foo" :multi(_)
.end
});
ok($res, ":multi(_) parsed");

$res := parse($c, q{
.sub "foo" :multi(_,_)
.end
});
ok($res, ":multi(_,_) parsed");

$res := parse($c, q{
.sub "foo" :multi("Foo")
.end
});
ok($res, ":multi('Foo') parsed");

$res := parse($c, q{
.sub "foo" :multi(Integer)
.end
});
ok($res, ":multi(Integer) parsed");

$res := parse($c, q{
.sub "foo" :multi(["Foo";"Bar"])
.end
});
ok($res, ":multi(['Foo';'Bar']) parsed");

$res := parse($c, q{
.sub "foo" :multi(_, ["Foo";"Bar"], Integer)
.end
});
ok($res, "Complex :multi");

########## .param
$res := parse($c, q{
.sub "foo"
    .param int a
    .param num b
    .param string c
    .param pmc d
.end
});
ok($res, "Simple .param");

$res := parse($c, q{
.sub "foo"
    .param pmc argv :slurpy         # slurpy array
    .param pmc key :named           # named parameter
    .param pmc value :named('key')  # named parameter
    .param string x :optional       # optional parameter
    .param int has_x :opt_flag      # flag 0/1 x was passed
    .param pmc kw :slurpy :named    # slurpy hash
.end
});
ok($res, "Complex .param");


done_testing();


# vim: ft=perl6
