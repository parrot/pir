#!/usr/bin/env parrot-nqp

INIT {
    pir::load_bytecode("nqp-setting.pbc");
    pir::load_bytecode("pir.pbc");
    Q:PIR{ .include "test_more.pir" };
}

# Tests for POST::Compiler functions.
my $c := POST::Compiler.new;

ok(pir::defined__ip($c), "Compiler created");

# Test build_args_signature
my $tree;
my $signature;
my $elt;
my %context;

$signature := $c.build_args_signature($tree, %context);
ok($signature.elements == 0, "No args produces empty signature");


$tree := POST::Node.new(
    POST::Constant.new(:type<sc>)
);

$signature := $c.build_args_signature($tree, %context);
ok($signature.elements == 1, "Single string const");

$elt := $signature[0];
ok($elt == 0x1, "... [0]");

done_testing();
# vim: ft=perl6
