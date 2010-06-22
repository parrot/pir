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
my %context;

$signature := $c.build_args_signature($tree, %context);
ok($signature.elements == 0, "No args produces empty signature");


done_testing();
# vim: ft=perl6
