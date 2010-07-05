#
# PIR Actions.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Actions is HLL::Actions;

has $!FILE;
has $!BLOCK;
has $!MAIN;

has $!OPLIB;
has %!MACRO_CONST;

INIT {
    pir::load_bytecode("nqp-setting.pbc");
}

method TOP($/) {
    make $<top>.ast;
}

method top($/, $key?) {
    if $key eq 'begin' {
        $!FILE := POST::File.new;
    }
    else {
        my $past := $!FILE;
        for $<compilation_unit> {
            my $child := $_.ast;
            $past.push($child) if $child;
        }

        # Remember :main sub.
        # XXX I'm too lazy to fix _ALL_ post test on storing $!MAIN as $!BLOCK.
        # XXX Sub.name isn't sufficient because of namespaces.
        $past<main_sub> := $!MAIN.name if $!MAIN;

        make $past;
    }
}

method compilation_unit:sym<.HLL> ($/) {
    $*HLL := $<quote>.ast<value>;
}

method compilation_unit:sym<.namespace> ($/) {
    $*NAMESPACE := $<namespace_key>.ast;
}

method compilation_unit:sym<.loadlib>($/) {
    # We have to load it right now because of dynops semantic.
    my $name    := ~$<quote>.ast<value>;
    my $library := pir::loadlib__ps($name);
    pir::die("Can't load $name") unless $library;

    register_hll_lib($name);
}

method newpad($/) {
    $!BLOCK := POST::Sub.new;
    $!BLOCK.hll($*HLL) if $*HLL;
    $!BLOCK.namespace($*NAMESPACE) if $*NAMESPACE;
}

method compilation_unit:sym<sub> ($/) {
    my $name := $<subname>.ast;
    $!BLOCK.name( $name );

    # Handle modifiers.
    if $<sub_modifier> {
        for $<sub_modifier> {
            my $name := $_<sym>;
            $!BLOCK.set_flag($name, $_.ast // 1);
        }
    }

    # Handle :main modifier
    $!MAIN := $!BLOCK if !$!MAIN || ($!BLOCK.main && !$!MAIN.main);

    if $<statement> {
        for $<statement> {
            my $past := $_.ast;
            $!BLOCK.push( $past ) if $past;
        }
    }

    self.validate_labels($/, $!BLOCK);

    # Store self in POST::File constants to be used during PBC emiting.
    $!FILE.sub($name, $!BLOCK);

    make $!BLOCK;
}

# Parametrized modifiers
method sub_modifier:sym<nsentry>($/)    { $<string_constant>.ast }
# TODO validate vtable name for existence
method sub_modifier:sym<vtable>($/)     { $<string_constant>.ast }
method sub_modifier:sym<outer>($/)      { $<subname>.ast }
method sub_modifier:sym<subid>($/)      { $<string_constant>.ast }
#token sub_modifier:sym<multi>      { ':' <sym> '(' [ [<.ws><multi_type><.ws>] ** ',' ]? ')' }

method compilation_unit:sym<.include>($/) {
    my $past := POST::Node.new;
    for $<quote><compilation_unit> {
        my $child := $_.ast;
        $past.push( $child ) if $child;
    }
    make $past;
}

method compilation_unit:sym<.macro_const>($/) {
    my $name  := ~$<ident>.ast;
    my $value := $<value>.ast;
    %!MACRO_CONST{ $name } := $value;
}

method statement($/) {
    make $<pir_directive> ?? $<pir_directive>.ast !! $<labeled_instruction>.ast;
}

method labeled_instruction($/) {
    my $child := $<pir_instruction>[0] // $<op>[0];
    my $past;
    $past := $child.ast if $child;

    # Create wrapping Label.
    my $label;
    if $<label>[0] {
        my $name := ~$<label>[0]<ident>;
        $label   := $!BLOCK.label($name);
        if pir::defined__IP($label) && $label.declared {
             $/.CURSOR.panic("Redeclaration of label '$name'");
        }

        $label := POST::Label.new(
            :name($name),
            :declared(1),
        );

        $!BLOCK.label($name, $label);

        $label.push($past) if $past;
        $past := $label;
    }

    make $past if $past;
}

method op($/) {
    my $past := POST::Op.new(
        :pirop(~$<name>),
    );

    # TODO We need 2 way passing here to create proper opname.
    my $oplib := self.oplib;
    my $op_family := $oplib.op_family(~$<name>);
    my $pirop     := $op_family.shift;

    if $<op_params>[0] {
        my $labels := pir::iter__PP($pirop.labels);
        for $<op_params>[0]<op_param> {
            my $label;
            # See TODO
            try {
                $label := pir::shift__IP($labels);
            };
            if $label {
                my $name  := ~$_;
                my $label := self.create_label($name);
                $past.push($label);
            }
            else {
                $past.push( $_.ast );
            }
        }
    }

    make $past;
}

method op_param($/) {
    make $<value> ?? $<value>.ast !! $<namespace_key>.ast
}

method namespace_key($/) {
    my $past;
    $past := POST::Key.new( :type('pc') );
    for $<quote> {
        $past.push($_.ast);
    }
    make $past;
}

method pir_key($/) {
    my $past;
    # Optimize for ki and kic type keys.
    if +$<value> == 1 {
        my $elt := $<value>[0].ast;
        if $elt.type eq 'ic' {
            $past := $elt;
            $past.type('kic');
        }
        elsif $elt.type eq 'i' {
            $past := $elt;
            $past.type('ki');
        }
        else {
            $past := POST::Key.new(
                :type('kc'),
                $elt,
            );
        }
    }
    else {
        $past := POST::Key.new( :type('kc') );
        for $<value> {
            $past.push($_.ast);
        }
    }
    make $past;
}

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
method pir_directive:sym<.include>($/) { 
    my $past := POST::Node.new;
    for $<quote><statement> {
        my $child := $_.ast;
        $past.push( $_.ast ) if $child;
    }
    make $past;
}

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

method pir_directive:sym<.return>($/) {
    my $past := POST::Call.new(
        :calltype('return'),
    );
    self.handle_pcc_args($/, $past);
    make $past;
}

method pir_directive:sym<.yield>($/) {
    my $past := POST::Call.new(
        :calltype('yield'),
    );
    self.handle_pcc_args($/, $past);
    make $past;
}


method pir_directive:sym<.tailcall>($/) {
    my $past := $<call>.ast;
    $past.calltype('tailcall');
    make $past;
}

method pir_directive:sym<.const>($/) {
    my $past := $<const_declaration>.ast;
    my $name := $past.name;
    # XXX NQP invoke this method too early!
    #if $!BLOCK.symbol($name) {
    #    $/.CURSOR.panic("Redeclaration of variable '$name'");
    #}
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

# XXX It's wrong. We have to store PMC type and use it appropriately.
method const_declaration:sym<pmc>($/) {
    make POST::Constant.new(
        :type('pc'),
        :name(~$<variable>),
        :value(~$<value>.ast),
    );
}

# Sugarized ops.
method pir_instruction:sym<goto>($/) {
    make POST::Op.new(
        :pirop('branch'),
        self.create_label(~$<ident>),
    );
}

method pir_instruction:sym<if>($/) {
    make POST::Op.new(
        :pirop('if'),
        $<variable>.ast,
        self.create_label(~$<ident>),
    );
}

method pir_instruction:sym<unless>($/) {
    make POST::Op.new(
        :pirop('unless'),
        $<variable>.ast,
        self.create_label(~$<ident>),
    );
}

method pir_instruction:sym<if_null>($/) {
    # TODO Check variable type for "p" or "s".
    make POST::Op.new(
        :pirop('if_null'),
        $<variable>.ast,
        self.create_label(~$<ident>),
    );
}

method pir_instruction:sym<unless_null>($/) {
    # TODO Check variable type for "p" or "s".
    make POST::Op.new(
        :pirop('unless_null'),
        $<variable>.ast,
        self.create_label(~$<ident>),
    );
}

method pir_instruction:sym<if_op>($/) {
    my $cmp_op;
    if    $<relop> eq '<=' { $cmp_op := 'le'; }
    elsif $<relop> eq '<'  { $cmp_op := 'lt'; }
    elsif $<relop> eq '==' { $cmp_op := 'eq'; }
    elsif $<relop> eq '!=' { $cmp_op := 'ne'; }
    elsif $<relop> eq '>'  { $cmp_op := 'gt'; }
    elsif $<relop> eq '>=' { $cmp_op := 'ge'; }
    else { $/.CURSOR.panic("Unhandled relative op $<relop>"); }

    make POST::Op.new(
        :pirop($cmp_op),
        $<lhs>.ast,
        $<rhs>.ast,
        self.create_label(~$<ident>),
    );
}

method pir_instruction:sym<unless_op>($/) {
    my $cmp_op;
    # do the opposite of if_op
    if    $<relop> eq '<=' { $cmp_op := 'gt'; }
    elsif $<relop> eq '<'  { $cmp_op := 'ge'; }
    elsif $<relop> eq '==' { $cmp_op := 'ne'; }
    elsif $<relop> eq '!=' { $cmp_op := 'eq'; }
    elsif $<relop> eq '>'  { $cmp_op := 'le'; }
    elsif $<relop> eq '>=' { $cmp_op := 'lt'; }
    else { $/.CURSOR.panic("Unhandled relative op $<relop>"); }

    make POST::Op.new(
        :pirop($cmp_op),
        $<lhs>.ast,
        $<rhs>.ast,
        self.create_label(~$<ident>),
    );
}

method pir_instruction:sym<assign>($/) {
    my $past;
    # It can be either assign to value or syntax sugar for something like "$I0 = err" op.
    my $variable := $<variable>.ast;
    my $value    := $<value>.ast;
    my $name     := ~$<value>;
    if $value.declared || $!BLOCK.symbol($name) {
        $past := POST::Op.new(
            :pirop('set'),
            $variable,
            $value,
        );
    }
    else {
        # Or it can be op.
        my $oplib := self.oplib;
        try {
            # OpLib throws exception leaving $past uninitialized
            my $type  := $variable.type // $!BLOCK.symbol($variable.name).type;
            my $op    := $oplib{$name ~ '_' ~ $type};
            $past := POST::Op.new(
                :pirop($name),
                $variable
            );
        }
    }

    unless $past {
        $/.CURSOR.panic("Register '" ~ $name ~ "' not predeclared");
    }

    make $past;
}

method pir_instruction:sym<op_assign_long_long_long_name>($/) {
    # TODO Check in OpLib for first argument. It should be "out" or "inout"
    my $past := POST::Op.new(
        :pirop(~$<op>),
        $<variable>.ast,
    );

    for $<op_params><op_param> {
        # Don't check "labels". We can't have them here.
        $past.push( $_.ast );
    }

    make $past;
}

method pir_instruction:sym<get_keyed_sugared> ($/) {
    make self.pir_instruction:sym<get_keyed>($/);
}

method pir_instruction:sym<get_keyed> ($/) {
    make POST::Op.new(
        :pirop('set'),
        $<lhs>.ast,
        $<rhs>.ast,
        $<pir_key>.ast,
    );
}

method pir_instruction:sym<set_keyed_sugared> ($/) {
    make self.pir_instruction:sym<set_keyed>($/);
}

method pir_instruction:sym<set_keyed> ($/) {
    make POST::Op.new(
        :pirop('set'),
        $<variable>.ast,
        $<pir_key>.ast,
        $<value>.ast,
    );
}

method pir_instruction:sym<delete>($/) {
    make POST::Op.new(
        :pirop('delete'),
        $<variable>.ast,
        $<pir_key>.ast,
    );
}

method pir_instruction:sym<exists_sugared>($/) {
    make self.pir_instruction:sym<exists>($/);
}

method pir_instruction:sym<exists>($/) {
    make POST::Op.new(
        :pirop('exists'),
        $<lhs>.ast,
        $<rhs>.ast,
        $<pir_key>.ast,
    );
}

method pir_instruction:sym<defined_sugared>($/) {
    make self.pir_instruction:sym<defined>($/);
}

method pir_instruction:sym<defined>($/) {
    make POST::Op.new(
        :pirop('defined'),
        $<lhs>.ast,
        $<rhs>.ast,
        $<pir_key>.ast,
    );
}


method pir_instruction:sym<unary>($/) {
    my $op;
    if    $<unary> eq '!' { $op := 'not'; }
    elsif $<unary> eq '-' { $op := 'neg'; }
    #don't care about '~' for bnot
    else { $/.CURSOR.panic("Unhandled unary op $<unary>"); }

    make POST::Op.new(
        :pirop($op),
        $<variable>.ast,
        $<value>.ast,
    );
}

sub get_math_op($mathop) {
    my $op;
    if    $mathop eq '+'   { $op := 'add'; }
    elsif $mathop eq '-'   { $op := 'sub'; }
    elsif $mathop eq '**'  { $op := 'pow'; } #parrot may not generate pow_x_x_x
    elsif $mathop eq '/'   { $op := 'div'; }
    elsif $mathop eq '%'   { $op := 'mod'; }
    elsif $mathop eq '*'   { $op := 'mul'; }
    elsif $mathop eq '.'   { $op := 'concat'; } #TODO: strings only
    elsif $mathop eq '>>>' { $op := 'lsr'; }
    elsif $mathop eq '<<'  { $op := 'shl'; }
    elsif $mathop eq '>>'  { $op := 'shr'; }
    elsif $mathop eq '&&'  { $op := 'and'; }
    elsif $mathop eq '||'  { $op := 'or'; }
    elsif $mathop eq '~~'  { $op := 'xor'; }
    elsif $mathop eq '&'   { $op := 'band'; }
    elsif $mathop eq '|'   { $op := 'bor'; }
    elsif $mathop eq '~'   { $op := 'bxor'; }
    $op;
}

method pir_instruction:sym<binary_math>($/) {
    my $op := get_math_op(~$<mathop>)
              // $/.CURSOR.panic("Unhandled binary math op $<mathop>");

    make POST::Op.new(
        :pirop($op),
        $<variable>.ast,
        $<lhs>.ast,
        $<rhs>.ast,
    );
}

method pir_instruction:sym<binary_logic>($/) {
    my $cmp_op;
    if    $<relop> eq '<=' { $cmp_op := 'isle'; }
    elsif $<relop> eq '<'  { $cmp_op := 'islt'; }
    elsif $<relop> eq '==' { $cmp_op := 'iseq'; }
    elsif $<relop> eq '!=' { $cmp_op := 'isne'; }
    elsif $<relop> eq '>'  { $cmp_op := 'isgt'; }
    elsif $<relop> eq '>=' { $cmp_op := 'isge'; }
    else { $/.CURSOR.panic("Unhandled relative op $<relop>"); }

    make POST::Op.new(
        :pirop($cmp_op),
        $<variable>.ast,
        $<lhs>.ast,
        $<rhs>.ast,
    );
}


method pir_instruction:sym<inplace>($/) {
    my $op := get_math_op(~$<mathop>)
              // $/.CURSOR.panic("Unhandled binary math op $<mathop>");
    make POST::Op.new(
        :pirop($op),
        $<variable>.ast,
        $<rhs>.ast,
    );
}


method pir_instruction:sym<call>($/) { make $<call>.ast; }

method pir_instruction:sym<call_assign>($/) {
    my $past := self.pir_instruction:sym<call>($/);

    # Store params (if any)
    my $results := list();
    $results.push( $<variable>.ast );
    $past.results($results);

    make $past;
}

method pir_instruction:sym<call_assign_many>($/) {
    my $past := self.pir_instruction:sym<call>($/);

    # Store params (if any)
    if $<results>[0] {
        my $results := list();
        for $<results>[0]<result> {
            $results.push( $_.ast );
        }
        $past.results($results);
    }

    make $past;
}


# Short PCC call.
#proto regex call { <...> }
method call:sym<pmc>($/) {
    my $variable := $<variable>.ast;
    if $variable.type ne 'p' {
        $/.CURSOR.panic("Sub '{ $variable.name }' isn't a PMC");
    }

    my $past := POST::Call.new(
        :calltype('call'),
        :name($variable),
    );
    self.handle_pcc_args($/, $past);
    make $past;
}

method call:sym<sub>($/) {
    # We need register to store Sub PMC. Either constant or from find_sub_not_null
    $!BLOCK.symbol('!SUB', POST::Register.new(:name('!SUB'), :type('p')));

    my $past := POST::Call.new(
        :calltype('call'),
        :name($<quote>.ast),
    );
    self.handle_pcc_args($/, $past);
    make $past;
}

method call:sym<ident>($/) {
    # We need register to store Sub PMC. Either constant or from find_sub_not_null
    $!BLOCK.symbol('!SUB', POST::Register.new(:name('!SUB'), :type('p')));

    my $past := POST::Call.new(
        :calltype('call'),
        :name(POST::String.new(
            :type<sc>,
            :value(~$<ident>),
            :encoding<fixed_8>,
            :charset<ascii>,
        )),
    );
    self.handle_pcc_args($/, $past);
    make $past;
}


method call:sym<dynamic>($/) {
    my $past := self.call:sym<pmc>($/);
    $past.invocant($<invocant>.ast);
    make $past;
}

method call:sym<method>($/) {
    my $past := POST::Call.new(
        :calltype('call'),
        :name($<quote>.ast),
    );
    self.handle_pcc_args($/, $past);
    $past.invocant($<invocant>.ast);
    make $past;
}

method handle_pcc_args($/, $past) {
    if $<args>[0] {
        # Store params (if any)
        my $params := list();
        for $<args>[0]<arg> {
            $params.push( $_.ast );
        }

        $past.params($params);
    }
}

#rule args { <arg> ** ',' }

#rule arg {
#    | <quote> '=>' <value>
#    | <value> <arg_flag>*
#}

method arg($/) {
    my $past := $<value>.ast;

    if $<arg_flag>[0] {
        my $modifier := $<arg_flag>[0].ast;
        # Check (.type, .modifier) combination
        if $modifier eq 'flat' || $modifier eq 'flat named' {
            if $past.type ne 'p' {
                $/.CURSOR.panic("Flat param '{ $past.name }' isn't a PMC");
            }
        }

        $past.modifier( $modifier );
    }
    elsif $<quote> {
        # fatarrow
        $past.modifier( hash( :named(~$<quote>.ast<value>) ) );
    }

    make $past;
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

    if $<param_flag>[0] {
        self.param_result_flags($/, $past, $<param_flag>[0]);
    }

    $!BLOCK.param($name, $past);
    $!BLOCK.symbol($name, $past);

    make $past;
}

method result($/) {
    # TODO Handle flags
    my $past := $<variable>.ast;
    if $<result_flag>[0] {
        self.param_result_flags($/, $past, $<result_flag>[0]);
    }
    make $past;
}

method param_result_flags($/, $past, $flag) {
    my $modifier := $flag.ast;
    # Check (.type, .modifier) combination
    if $modifier eq 'slurpy' || $modifier eq 'slurpy named' {
        if $past.type ne 'p' {
            $/.CURSOR.panic("Slurpy param '{ $past.name }' isn't a PMC");
        }
    }
    elsif $modifier eq 'opt_flag' {
        if $past.type ne 'i' {
            $/.CURSOR.panic(":opt_flag param '{ $past.name }' isn't a INT");
        }
    }

    $past.modifier( $modifier );
}

method arg_flag:sym<:flat>($/)              { make 'flat' }
method arg_flag:sym<flat named>($/)         { make 'flat named' }
method arg_flag:sym<named_flag>($/)         { make $<named_flag>.ast }

method param_flag:sym<:call_sig>($/)        { make 'call_sig' }
method param_flag:sym<:slurpy>($/)          { make 'slurpy'   }
method param_flag:sym<slurpy named>($/)     { make 'slurpy named' }
method param_flag:sym<:optional>($/)        { make 'optional' }
method param_flag:sym<:opt_flag>($/)        { make 'opt_flag' }
method param_flag:sym<named_flag>($/)       { make $<named_flag>.ast }

method result_flag:sym<:slurpy>($/)         { make 'slurpy'   }
method result_flag:sym<slurpy named>($/)    { make 'slurpy named' }
method result_flag:sym<:optional>($/)       { make 'optional' }
method result_flag:sym<:opt_flag>($/)       { make 'opt_flag' }
method result_flag:sym<named_flag>($/)      { make $<named_flag>.ast }

method named_flag($/) {
    make hash( named => ($<quote>[0] ?? ~$<quote>[0].ast<value> !! undef) )
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
    if $<quote> {
        make POST::String.new(
            :type<sc>,
            :value($<quote>.ast<value>),
            :encoding<fixed_8>,
            :charset<ascii>,
        );
    }
    elsif $<typed_string> {
        my $encoding := +$<typed_string><encoding>
                     ?? ~$<typed_string><encoding>[0]
                     !! 'fixed_8';
        my $charset  := ~$<typed_string><charset>;
        make POST::String.new(
            :type<sc>,
            :value($<typed_string><quote_EXPR>.ast<value>),
            :encoding($encoding),
            :charset($charset),
        );
    }
    elsif $<heredoc> {
        pir::die("NYI");
    }
    else {
        $/.CURSOR.panic("unknown string constant type");
    }
}

method variable($/) {
    my $past;
    if $<ident> {
        # Named register
        $past := POST::Value.new(
            :name(~$<ident>),
        );
    }
    elsif $<pir_register> {
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
    else {
        $past := %!MACRO_CONST{ ~$<ident> }
                 ; #// $/.CURSOR.panic("Undefined macro { ~$<ident> }");
    }

    make $past;
}

method subname($/) {
    make $<ident> ?? ~$<ident> !! ~($<quote>.ast<value>);
}

method quote:sym<apos>($/) {
    make POST::String.new(
        :type<sc>,
        :value(~$<quote_EXPR>.ast<value>),
        :encoding<fixed_8>,
        :charset<ascii>,
    );
}

method quote:sym<dblq>($/) {
    make POST::String.new(
        :type<sc>,
        :value(~$<quote_EXPR>.ast<value>),
        :encoding<fixed_8>,
        :charset<ascii>,
    );
}

###################################################################

method validate_labels($/, $node) {
    for $node.labels {
        unless $_.value.declared {
            $/.CURSOR.panic("Label '" ~ $_.value.name ~ "' not declared");
        }
    }
}

method create_label($name) {
    my $label := POST::Label.new( :name($name) );
    $!BLOCK.label($name, $label) unless $!BLOCK.label($name);
    $label;
}

method oplib() {
    $!OPLIB := pir::new__ps('OpLib') unless pir::defined__ip($!OPLIB);
    $!OPLIB;
}

# vim: ft=perl6
