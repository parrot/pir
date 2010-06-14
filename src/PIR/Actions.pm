#
# PIR Actions.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Actions is HLL::Actions;

INIT {
    pir::load_bytecode("nqp-setting.pbc");
}

# We can have only one .sub at time.
our $BLOCK;

method TOP($/) { make $<top>.ast; }

method top($/) {
    my $past := PAST::Stmts.new;
    for $<compilation_unit> {
        $past.push($_.ast);
    }
    #make $<compilation_unit>.ast;
    make $past;
}

method newpad($/) {
    our $BLOCK;
    our $*HLL;
    our $*NAMESPACE;
    $BLOCK := PAST::Block.new(
        hll         => $*HLL,
        namespace   => $*NAMESPACE,
    );
}

method compilation_unit:sym<.HLL> ($/) {
    our $*HLL := $<quote>.ast<value>;
}

method compilation_unit:sym<.namespace> ($/) {
    our $*NAMESPACE := $<namespace_key>[0].ast;
}

method compilation_unit:sym<sub> ($/) {
    our $BLOCK;

    my $past := $BLOCK;

    $past.name( $<subname>.ast );


    make $past;
}



method subname($/) {
    make $<ident> ?? ~$<ident> !! ~($<quote>.ast<value>);
}

method quote:sym<apos>($/) { make $<quote_EXPR>.ast; }
method quote:sym<dblq>($/) { make $<quote_EXPR>.ast; }


# vim: ft=perl6
