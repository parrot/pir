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
my @args;
my $signature;
my $elt;
my %context;

$signature := $c.build_args_signature(@args, %context);
ok($signature.elements == 0, "No args produces empty signature");


# Simple registers.
is( 0, $c.build_single_arg(POST::Register.new(:type<i>), %context), "Int register" );
is( 1, $c.build_single_arg(POST::Register.new(:type<s>), %context), "Str register" );
is( 2, $c.build_single_arg(POST::Register.new(:type<p>), %context), "PMC register" );
is( 3, $c.build_single_arg(POST::Register.new(:type<n>), %context), "Num register" );

# Add constant flag
is( 0 + 0x10, $c.build_single_arg(POST::Register.new(:type<ic>), %context), "Int register" );
is( 1 + 0x10, $c.build_single_arg(POST::Register.new(:type<sc>), %context), "Str register" );
is( 2 + 0x10, $c.build_single_arg(POST::Register.new(:type<pc>), %context), "PMC register" );
is( 3 + 0x10, $c.build_single_arg(POST::Register.new(:type<nc>), %context), "Num register" );



#pir::trace(4);
@args.push(POST::Constant.new(:type<sc>, :value<Hello, World>));

$signature := $c.build_args_signature(@args, %context);
ok($signature.elements == 1, "Single string const");

$elt := $signature[0];
ok($elt == 0x11, "... [0]");


done_testing();
# vim: ft=perl6
