#
# PIR Actions.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Actions is HLL::Actions;

has $!BLOCK;

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
    make $past;
}

method compilation_unit:sym<.HLL> ($/) {
    our $*HLL := $<quote>.ast<value>;
}

method compilation_unit:sym<.namespace> ($/) {
    our $*NAMESPACE := $<namespace_key>[0].ast;
}

method compilation_unit:sym<sub> ($/) {
    $!BLOCK := POST::Sub.new(
        :name( $<subname>.ast ),
    );

    # TODO Handle pragmas.

    #for $<param_decl> {
    #    $BLOCK[0].push( $_.ast );
    #}

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
    my $past := PAST::Var.new(
        :name($name),
        :scope('register'),
        :isdecl(1),
        :node($/),
        :multitype(~$<pir_type>),
    );

    # TODO Handle param flags. Extend PAST::Var to support all of them.

    $!BLOCK.symbol($name, :scope('lexical') );

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

method subname($/) {
    make $<ident> ?? ~$<ident> !! ~($<quote>.ast<value>);
}

method quote:sym<apos>($/) { make $<quote_EXPR>.ast; }
method quote:sym<dblq>($/) { make $<quote_EXPR>.ast; }


# vim: ft=perl6
