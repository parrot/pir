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

########## .return
$res := parse($c, q{
.sub "foo"
    .return ()
.end
});
ok($res, ".return ()");

$res := parse($c, q{
.sub "foo"
    .return ("42")
.end
});
ok($res, ".return ('42')");

$res := parse($c, q{
.sub "foo"
    .return (42, "42", 41.9999)
.end
});
ok($res, ".return (42, '42', 41.9999)");

$res := parse($c, q{
.sub "foo"
    .local pmc array, hash
    .return ("42" :named, array :flat, hash :flat :named)
.end
});
ok($res, ".return (42, '42', 41.9999)");

########## .tailcall
$res := parse($c, q{
.sub "foo"
    .tailcall "bar"()
.end
});
ok($res, ".tailcall 'bar'()");

$res := parse($c, q{
.sub "foo"
    .local pmc foo
    .tailcall foo()
.end
});
ok($res, ".tailcall foo()");

$res := parse($c, q{
.sub "foo"
    .local pmc foo
    .tailcall foo(42, array :flat, hash :flat :named)
.end
});
ok($res, ".tailcall foo(42...)");

$res := parse($c, q{
.sub "foo"
    .local pmc foo
    .tailcall foo.'bar'()
.end
});
ok($res, ".tailcall foo.'bar'()");

$res := parse($c, q{
.sub "foo"
    .local pmc foo
    .local string method
    .tailcall foo.method()
.end
});
ok($res, ".tailcall foo.method()");

$res := parse($c, q{
.sub "foo"
    .local pmc foo, array, hash
    .local string method
    .tailcall foo.'method'(42, array :flat, hash :flat :named)
.end
});
ok($res, ".tailcall foo.'method'(...)");

########## .call

$res := parse($c, q{
.sub "foo"
    .local pmc foo, array, hash
    .local string method
    foo.'method'()
.end
});
ok($res, "foo.'method'()");

$res := parse($c, q{
.sub "foo"
    .local pmc foo, array, hash
    .local string method
    array = foo.'method'()
.end
});
ok($res, "array = foo.'method'()");

$res := parse($c, q{
.sub "foo"
    .local pmc foo, array, hash
    .local string method
    (array :slurpy, hash :slurpy :named, method :optional, $I0 :opt_flag) = foo.'method'()
.end
});
ok($res, "array = foo.'method'()");



done_testing();


# vim: ft=perl6
