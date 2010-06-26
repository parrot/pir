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

# Slurpy
is( 2 + 0x20, $c.build_single_arg(POST::Register.new(:type<p>, :modifier<slurpy>), %context), "Slurpy PMC register" );

is( 2 + 0x80, $c.build_single_arg(POST::Register.new(:type<p>, :modifier<optional>), %context), "Named PMC register" );
is( 0 + 0x100, $c.build_single_arg(POST::Register.new(:type<i>, :modifier<opt_flag>), %context), "opt_flag" );

# Anonymouse :named.
# "foo"(hello :named)
my @sig := $c.build_single_arg(
    POST::Register.new(
        :type<s>,
        :name<hello>,
        :modifier(
            hash(:named(undef))
        )
    ),
    %context
);
is( +@sig, 2, "Named arg produces 2 fields");
is( @sig[0], 0x1 + 0x10 + 0x200, "... first with proper type");
is( @sig[1], 0x1,                "... second with proper type");


@args := list();
@args.push(POST::Constant.new(:type<sc>, :value<Hello, World>));

$signature := $c.build_args_signature(@args, %context);
ok($signature.elements == 1, "Single string const");

$elt := $signature[0];
ok($elt == 0x11, "... [0]");


# Named args.
@args := list(
    POST::Register.new(
        :type<s>,
        :name<hello>,
        :modifier(
            hash(:named(undef))
        )
    )
);

$signature := $c.build_args_signature(@args, %context);
ok($signature.elements == 2, ":named produce 2 'args'");

$POST::Compiler::OPLIB := pir::new__ps("OpLib");
%context<bytecode> := pir::new__ps("PackfileRawSegment");
%context<constants> := pir::new__ps("PackfileConstantTable");

# Fill constants with some values
for <foo bar baz> {
    %context<constants>.get_or_create_string($_);
}
my $hello := %context<constants>.get_or_create_string("hello");

$c.build_pcc_call("set_args_pc", @args, %context);


# 0 is "set_args_pc"
# 1 is signature
is( %context<bytecode>.at(2), $hello, ":named name stored");
is( %context<bytecode>.at(3), 0,      ":named value stored");

#$elt := $signature[0];
#ok($elt == 0x11, "... [0]");


done_testing();
# vim: ft=perl6
