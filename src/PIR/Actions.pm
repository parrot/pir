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

    if $!BLOCK.symbol($name) {
        $/.CURSOR.panic("Redeclaration of varaible '$name'");
    }

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

method pir_directive:sym<.local>($/) {
    my $type := pir::substr__SSII(~$<pir_type>, 0, 1);
    for $<ident> {
        my $name := ~$_;
        if $!BLOCK.symbol($name) {
            $/.CURSOR.panic("Redeclaration of varaible '$name'");
        }

        my $past := POST::Register.new(
            :name($name),
            :type($type),
            :declared(1),
        );
        $!BLOCK.symbol($name, $past);
    }

}
#rule pir_directive:sym<.lex>        { <sym> <string_constant> ',' <pir_register> }
#rule pir_directive:sym<.file>       { <sym> <string_constant> }
#rule pir_directive:sym<.line>       { <sym> <int_constant> }
#rule pir_directive:sym<.annotate>   { <sym> <string_constant> ',' <constant> }
#rule pir_directive:sym<.include>    { <sym> <quote> }

# PCC
#rule pir_directive:sym<.begin_call>     { <sym> }
#rule pir_directive:sym<.end_call>       { <sym> }
#rule pir_directive:sym<.begin_return>   { <sym> }
#rule pir_directive:sym<.end_return>     { <sym> }
#rule pir_directive:sym<.begin_yield>    { <sym> }
#rule pir_directive:sym<.end_yield>      { <sym> }

#rule pir_directive:sym<.call>       { <sym> <value> [',' <continuation=pir_register> ]? }
#rule pir_directive:sym<.meth_call>  { <sym> <value> [',' <continuation=pir_register> ]? }
#rule pir_directive:sym<.nci_call>   { <sym> <value> [',' <continuation=pir_register> ]? }

#rule pir_directive:sym<.invocant>   { <sym> <value> }
#rule pir_directive:sym<.set_arg>    { <sym> <value> <arg_flag>* }
#rule pir_directive:sym<.set_return> { <sym> <value> <arg_flag>* }
#rule pir_directive:sym<.set_yield>  { <sym> <value> <arg_flag>* }
#rule pir_directive:sym<.get_result> { <sym> <value> <result_flag>* }

#rule pir_directive:sym<.return>     { <sym> '(' <args>? ')' }
#rule pir_directive:sym<.yield>      { <sym> '(' <args>? ')' }

method pir_directive:sym<.tailcall>($/) {
    my $past := $<call>.ast;
    $past.calltype('tailcall');
    make $past;
}

method pir_directive:sym<.const>($/) {
    my $past := $<const_declaration>.ast;
    my $name := $past.name;
    if $!BLOCK.symbol($name) {
        $/.CURSOR.panic("Redeclaration of varaible '$name'");
    }
    $!BLOCK.symbol($name, $past);
}

#rule pir_directive:sym<.globalconst> { <sym> <const_declaration> }

method const_declaration:sym<int>($/) {
    my $past := $<int_constant>.ast;
    $past.name(~$<ident>);
    make $past;
}

method const_declaration:sym<num>($/) {
    my $past := $<float_constant>.ast;
    $past.name(~$<ident>);
    make $past;
}

method const_declaration:sym<string>($/) {
    my $past := $<string_constant>.ast;
    $past.name(~$<ident>);
    make $past;
}

method pir_instruction_call($/) {
    make $<call>.ast;
}

method pir_instruction:sym<call>($/) {
    self.pir_instruction_call($/);
}

method pir_instruction:sym<call_assign>($/) {
    my $past := self.pir_instruction_call($/);

    # Store params (if any)
    my $results := POST::Node.new;
    $results.push( $<variable>.ast );
    self.validate_registers($/, $results);
    $past.results($results);

    make $past;
}

method pir_instruction:sym<call_assign_many>($/) {
    my $past := self.pir_instruction_call($/);

    # Store params (if any)
    if $<results>[0] {
        my $results := POST::Node.new;
        for $<results>[0]<result> {
            $results.push( $_.ast );
        }
        self.validate_registers($/, $results);
        $past.results($results);
    }

    make $past;
}


# Short PCC call.
#proto regex call { <...> }
method call_sym_pmc($/) {
    my $past := POST::Call.new(
        :calltype('call'),
        :name($<variable>.ast),
    );
    self.handle_pcc_args($/, $past);
    make $past;
}

method call:sym<pmc>($/) {
    make self.call_sym_pmc($/);
}

method call_sym_sub($/) {
    my $past := POST::Call.new(
        :calltype('call'),
        :name($<quote>.ast),
    );
    self.handle_pcc_args($/, $past);
    make $past;
}

method call:sym<sub>($/) {
    make self.call_sym_sub($/);
}

method call:sym<dynamic>($/) {
    my $past := self.call_sym_pmc($/);
    $past.invocant($<invocant>.ast);
    make $past;
}

method call:sym<method>($/) {
    my $past := self.call_sym_sub($/);
    $past.invocant($<invocant>.ast);
    make $past;
}

method handle_pcc_args($/, $past) {
    if $<args>[0] {
        # Store params (if any)
        my $params := POST::Node.new;
        for $<args>[0]<arg> {
            $params.push( $_.ast );
        }
        self.validate_registers($/, $params);

        $past.params($params);
    }
}

#rule args { <arg> ** ',' }

#rule arg {
#    | <quote> '=>' <value>
#    | <value> <arg_flag>*
#}

method arg($/) {
    # TODO Handle flags, fatarrow
    make $<value>.ast;
}

method result($/) {
    # TODO Handle flags
    make $<variable>.ast;
}

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

method int_constant($/) {
    make POST::Constant.new(
        :type<ic>,
        :value(~$/),
    );
}

method float_constant($/) {
    make POST::Constant.new(
        :type<nc>,
        :value(~$/),
    );
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
        $past := POST::Value.new(
            :name(~$<ident>),
        );
    }
    else {
        # Numbered register
        my $type := ~$<pir_register><INSP>;
        my $name := '$' ~ $type ~ ~$<pir_register><reg_number>;
        $type := pir::downcase__SS($type);
        $past := POST::Value.new(
            :name($name),
            :type($type),
        );

        # Register it in symtable right now to simplify check in validate_registers
        $!BLOCK.symbol($name, POST::Register.new(
            :name($name),
            :type($type),
        ));
    }

    make $past;
}

method subname($/) {
    make $<ident> ?? ~$<ident> !! ~($<quote>.ast<value>);
}

method quote:sym<apos>($/) {
    make POST::Constant.new(
        :type("sc"),
        :value(dequote(~$/))
    );
}

method quote:sym<dblq>($/) {
    make POST::Constant.new(
        :type("sc"),
        :value(dequote(~$/))
    );
}

method validate_registers($/, $node) {
    for @($node) -> $arg {
        my $name;
        try {
            # XXX Constants doesn't have names. But pir::isa__IPP doesn't wor either
            $name := $arg.name;
        };
        if $name {
            if !$!BLOCK.symbol($name) {
                $/.CURSOR.panic("Register '" ~ $name ~ "' not predeclared");
            }
        }
    }
}

sub dequote($a) {
    my $l := pir::length__IS($a);
    pir::substr__SSII($a, 1, $l-2);
}

# vim: ft=perl6
