#
# PIR Actions.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Actions is HLL::Actions;

has $!BLOCK;
has $!MAIN;

INIT {
    pir::load_bytecode("nqp-setting.pbc");
}

method TOP($/) { make $<top>.ast; }

method top($/) {
    my $past := POST::Node.new;
    for $<compilation_unit> {
        my $child := $_.ast;
        $past.push($child) if $child;
    }

    # Remember :main sub.
    $past<main_sub> := $!MAIN;

    make $past;
}

method compilation_unit:sym<.HLL> ($/) {
    our $*HLL := $<quote>.ast<value>;
}

method compilation_unit:sym<.namespace> ($/) {
    our $*NAMESPACE := $<namespace_key>[0] ?? $<namespace_key>[0].ast !! undef;
}

method newpad($/) {
    $!BLOCK := POST::Sub.new(
    );
}

method compilation_unit:sym<sub> ($/) {
    my $name := $<subname>.ast;
    $!BLOCK.name( $name );

    # TODO Handle pragmas.

    # TODO Handle :main pragma
    $!MAIN := $name unless $!MAIN;

    if $<statement> {
        for $<statement> {
            my $past := $_.ast;
            $!BLOCK.push( $past ) if $past;
        }
    }

    make $!BLOCK;
}

method param_decl($/) {
    my $name := ~$<name>;
    my $past := POST::Register.new(
        :name($name),
        :type(pir::substr__SSII(~$<pir_type>, 0, 1)),
        :declared(1),
    );

    $!BLOCK.symbol($name, $past);

    make $past;
}

method statement($/) {
    make $<pir_directive> ?? $<pir_directive>.ast !! $<labeled_instruction>.ast;
}

method labeled_instruction($/) {
    # TODO Handle C<label> and _just_ label.
    my $child := $<pir_instruction>[0] // $<op>[0]; # // $/.CURSOR.panic("NYI");
    make $child.ast if $child;
}

method op($/) {
    my $past := POST::Op.new(
        :pirop(~$<name>),
    );

    for $<op_params> {
        $past.push( $_.ast );
    }

    self.validate_registers($/, $past);

    # TODO Validate via OpLib

    make $past;
}

method op_params($/) { make $<value>[0] ?? $<value>[0].ast !! $<pir_key>[0].ast }

method value($/) { make $<constant> ?? $<constant>.ast !! $<variable>.ast }

method constant($/) {
    my $past;
    if $<int_constant> {
        $past := $<int_constant>.ast;
    }
    elsif $<float_constant> {
        $past := $<float_constant>.ast;
    }
    else {
        $past := $<string_constant>.ast;
    }
    make $past;
}

method string_constant($/) {
    make POST::Constant.new(
        :type<sc>,
        :value($<quote>.ast<value>),
    );
}

method variable($/) {
    my $past;
    if $<ident> {
        # Named register
        $past := POST::Register.new(
            :name(~$<ident>),
            :declared(0)
        );
    }
    else {
        # Numbered register
        my $type := ~$<pir_register><INSP>;
        my $name := '$' ~ $type ~ ~$<pir_register><digit>;
        $past := POST::Register.new(
            :name($name),
            :type(pir::downcase__SS($type)),
            :declared(1)
        );
    }

    make $past;
}

method subname($/) {
    make $<ident> ?? ~$<ident> !! ~($<quote>.ast<value>);
}

method quote:sym<apos>($/) { make $<quote_EXPR>.ast; }
method quote:sym<dblq>($/) { make $<quote_EXPR>.ast; }

method validate_registers($/, $node) {
    for @($node) -> $arg {
        my $name;
        try {
            # XXX Constants doesn't have names. But pir::isa__IPP doesn't wor either
            $name := $arg.name;
        };
        if $name {
            if $arg.declared {
                # It can be named register. Put it into symtable
                $!BLOCK.symbol($name, $arg);
            }
            elsif !$!BLOCK.symbol($name) {
                $/.CURSOR.panic("Register '" ~ $name ~ "' not predeclared");
            }
        }
    }
}

# vim: ft=perl6
