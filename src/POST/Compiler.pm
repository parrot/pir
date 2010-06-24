module POST::Compiler;


=begin
Generate PBC file.
=end

=begin Labels

Labels are handled in two passes:
=item Generate todolist.
Todolist is hash of (position=>(name, op_start)), where C<position> is offset
in bytecode where label with C<name> used.
=item Populate labels.
Iterate over todolist and replace labels with offset of Sub start.

=end Labels

our $OPLIB;
our $DEBUG;

our $REGALLOC;
INIT {
    $REGALLOC := POST::VanillaAllocator.new;
}

method pbc($post, %adverbs) {
    #pir::trace(1);
    $OPLIB := pir::new__PS('OpLib');
    $DEBUG := %adverbs<debug>;

    # Emitting context. Contains fixups, consts, etc.
    my %context;

    my $pf := pir::new__PS("Packfile");

    # Scaffolding
    # Packfile will be created with fresh directory
    my $pfdir := $pf.get_directory;

    # We need some constants
    %context<constants> := pir::new__PS('PackfileConstantTable');


    # Add PackfileConstantTable into directory.
    $pfdir<CONSTANTS_hello.pir> := %context<constants>;

    # Generate bytecode
    %context<bytecode> := pir::new__PS('PackfileRawSegment');

    # Store bytecode
    $pfdir<BYTECODE_hello.pir> := %context<bytecode>;

    # Dark magik. Create Fixup for Sub.
    %context<fixup> := pir::new__PS('PackfileFixupTable');

    # Add it to Directory now because adding FixupEntries require Directory
    $pfdir<FIXUP_hello.pir> := %context<fixup>;

    # Interpreter.
    %context<constants>[0] := pir::getinterp__P();

    # Empty FIA for handling returns from "hello"
    %context<constants>[1] := pir::new__PS('FixedIntegerArray');

    for @($post) -> $s {
        self.to_pbc($s, %context);
    }

    $pf;
};

our multi method to_pbc(POST::Sub $sub, %context) {
    # Store current Sub in context to resolve symbols and constants.
    %context<sub> := $sub;

    # Allocate registers.
    my @n_regs_used := $REGALLOC.process($sub);
    self.debug('n_regs_used ' ~ @n_regs_used.join('-')) if $DEBUG;
    self.dumper($sub.symtable, "regs") if $DEBUG;

    my $bc := %context<bytecode>;

    # Todo-list of Labels.
    %context<labels_todo> := hash();

    # Packfile poop his pants...
    my $sb := pir::new__PS('StringBuilder');
    $sb.push(~$sub.name);
    my $subname := ~$sb;

    self.debug("Emitting $subname") if $DEBUG;
    %context<constants>.get_or_create_string($subname);

    my $start_offset := +$bc;
    self.debug("From $start_offset") if $DEBUG;

    # Handle params
    if $sub<params> {
        self.build_pcc_call("get_params_pc", $sub<params>, %context);
    }

    # Emit ops.
    for @($sub) {
        self.to_pbc($_, %context);
    }

    # Default .return(). XXX We don't need it (probably)
    $bc.push($OPLIB<set_returns_pc>);
    $bc.push(0x001);                      # id of FIA
    $bc.push($OPLIB<returncc>);

    my $end_offset := +$bc;
    self.debug("To $end_offset") if $DEBUG;

    # Fixup labels to set real offsets
    self.fixup_labels($sub, %context<labels_todo>, %context<bytecode>);

    # Now create Sub PMC using hash of values.
    my %sub := hash(
        :start_offs( $start_offset ),
        :end_offs( $end_offset ),
        :name( $subname ),
        :subid( $subname ),
        :ns_entry_name( $subname ),
        :vtable_index( -1 ), # It must be -1!!!
        :HLL_id<0>,
        :method<0>,

        :n_regs_used(@n_regs_used),
    );

    # and store it in PackfileConstantTable
    my $idx := %context<constants>.push(pir::new__PSP('Sub', %sub));

    self.debug("Fixup $subname") if $DEBUG;
    my $P1 := pir::new__PSP('PackfileFixupEntry', hash(
            :name( ~$subname ),
            :type<1>,
            :offset( $idx ), # Constant 
        ));

    %context<fixup>.push($P1);
}

our multi method to_pbc(POST::Op $op, %context) {
    # Generate full name
    my $fullname := $op.pirop;
    self.debug("Short name $fullname") if $DEBUG;

    for @($op) {
        my $type := $_.type || %context<sub>.symbol($_.name).type;
        $fullname := ~$fullname ~ '_' ~ ~$type;
    }

    self.debug("Fullname $fullname") if $DEBUG;

    # Store op offset. It will be needed for calculating labels.
    %context<opcode_offset> := +%context<bytecode>;

    %context<bytecode>.push($OPLIB{$fullname});
    for @($op) {
        self.to_pbc($_, %context);
    }
}

our multi method to_pbc(POST::Key $key, %context) {

    my $key_pmc;

    for @($key) {
        my $k := pir::new__ps('Key');

        if $_.type eq 'sc' {
            $k.set_str(~$_.value);
            %context<constants>.get_or_create_string($_.value);
            self.debug("added {$_.value} to const table at idx $idx");
        }
        elsif $_.type eq 'ic' {
            $k.set_int(+$_.value);
        }
        else {
            pir::die("unknown key type: {$_.type}");
        }

        if !pir::defined__ip($key_pmc) {
            $key_pmc := $k;
        }
        else {
            $key_pmc.push($k);
        }
    }

    # XXX PackfileConstantTable can't Keys equivalense it. So just push it.
    my $idx := %context<constants>.push($key_pmc);
    %context<bytecode>.push($idx);
}

our multi method to_pbc(POST::Constant $op, %context) {
    my $idx;
    my $type := $op.type;
    if $type eq 'sc' {
        $idx := %context<constants>.get_or_create_string($op.value);
    }
    elsif $type eq 'ic' || $type eq 'kic' {
        $idx := $op.value;
    }
    else {
        pir::die("NYI");
    }

    self.debug("Index $idx") if $DEBUG;
    %context<bytecode>.push($idx);
}

our multi method to_pbc(POST::Value $val, %context) {
    # Redirect to real value. POST::Value is just reference.
    my $orig := %context<sub>.symbol($val.name);
    self.to_pbc($orig, %context);
}

our multi method to_pbc(POST::Register $reg, %context) {
    %context<bytecode>.push($reg.regno);
}

# Some PIR sugar produces nested Nodes.
our multi method to_pbc(POST::Node $node, %context) {
    for @($node) {
        self.to_pbc($_, %context);
    }
}

our multi method to_pbc(POST::Label $l, %context) {
    my $bc := %context<bytecode>;
    if $l.declared {
        my $pos := +$bc;
        self.debug("Declare label '{ $l.name }' at $pos") if $DEBUG;
        # Declaration of Label. Update offset in Sub.labels.
        $l.position($pos);
        # We can have "enclosed" ops. Process them now.
        for @($l) {
            self.to_pbc($_, %context);
        }
    }
    else {
        # Usage of Label. Put into todolist and reserve space.
        my $pos := +$bc;
        $bc.push(0);
        %context<labels_todo>{$pos} := list($l.name, %context<opcode_offset>);
        self.debug("Todo label '{ $l.name }' at $pos, { %context<opcode_offset> }") if $DEBUG;
    }
}

our multi method to_pbc(POST::Call $call, %context) {
    my $bc := %context<bytecode>;

    if $call.calltype eq 'call' {
        self.build_pcc_call("set_args_pc", $call<params>, %context);

        my $SUB;
        if $call<name>.isa(POST::Constant) {
            # Constant string. E.g. "foo"()
            $SUB := %context<sub>.symbol("!SUB");
            # XXX We can avoid find_sub_not_null when Sub is constant.
            $bc.push($OPLIB<find_sub_not_null_p_sc>);
            self.to_pbc($SUB, %context);
            self.to_pbc($call<name>, %context);
        }
        else {
            $SUB := %context<sub>.symbol($call<name><name>);
            $bc.push($OPLIB<find_sub_not_null_p_s>);
            self.to_pbc($SUB, %context);
            self.to_pbc($call<name>, %context);
        }

        self.debug("invokecc_p") if $DEBUG;
        $bc.push($OPLIB<invokecc_p>);
        self.to_pbc($SUB, %context);
    }
    elsif $call.calltype eq 'return' {
        self.build_pcc_call("set_returns_pc", $call<params>, %context);
        $bc.push($OPLIB<returncc>);
    }
    else {
        pir::die("NYI { $call.calltype }");
    }
}

our method build_pcc_call($opname, @args, %context) {
    my $bc        := %context<bytecode>;
    my $signature := self.build_args_signature(@args, %context);
    my $sig_idx   := %context<constants>.get_or_create_pmc($signature);

    self.debug("Sig: $sig_idx") if $DEBUG;

    self.debug($opname) if $DEBUG;
    # Push signature and all args.
    $bc.push($OPLIB{ $opname });
    $bc.push($sig_idx);
    for @args {
        # XXX Handle :named params properly.
        self.to_pbc($_, %context);
    }
}

our method build_args_signature(@args, %context) {
    my @sig;
    for @args -> $arg {
        # build_single_arg can return 2 values, but @a.push can't handle it
        my $s := self.build_single_arg($arg, %context);
        if pir::isa__ips($s, 'Integer') {
            @sig.push($s);
        }
        else {
            for $s { @sig.push($_); }
        }
    }

    # Copy @sig into $signature
    my $elements  := +@sig;
    my $signature := Q:PIR{
        %r = find_lex '$elements'
        $I99 = %r
        %r = find_lex '$signature'
        %r = new ['FixedIntegerArray'], $I99
    };

    # TODO Update nqp-setting to support .kv
    my $idx := 0;
    for @sig -> $val {
        $signature[$idx] := $val;
        $idx++;
    }

    $signature;
}

my %flags;
INIT {
    %flags := (
        flat    => pir::shl__iii(1, 5),
        slurpy  => pir::shl__iii(1, 5),

        optional  => pir::shl__iii(1, 7),
        opt_flag  => pir::shl__iii(1, 8),

        named   => pir::shl__iii(1, 9),
    );
}

our method build_single_arg($arg, %context) {
    # XXX Build call signature arg according to PDD03
    my $type := $arg.type;
    my $res;

    # Register types.
    if $type eq 'i'     { $res := 0 }
    elsif $type eq 's'  { $res := 1 }
    elsif $type eq 'p'  { $res := 2 }
    elsif $type eq 'n'  { $res := 3 }
    # Constants
    elsif $type eq 'ic' { $res := 0 + 0x10 }
    elsif $type eq 'sc' { $res := 1 + 0x10 }
    elsif $type eq 'pc' { $res := 2 + 0x10 }
    elsif $type eq 'nc' { $res := 3 + 0x10 }


    $res;
}

our method fixup_labels($sub, $labels_todo, $bc) {
    self.debug("Fixup labels") if $DEBUG;
    for $labels_todo -> $kv {
        my $offset := $kv.key;
        my @pair   := $kv.value;
        self.debug("Fixing '{ @pair[0] }' from op { @pair[1] } at { $offset }") if $DEBUG;
        my $delta  := $sub.label(@pair[0]).position - @pair[1];
        $bc[$offset] := $delta;
    }
}

method debug(*@args) {
    if $DEBUG {
        for @args {
            pir::say($_);
        }
    }
}

INIT {
    pir::load_bytecode('nqp-setting.pbc');
}

# vim: ft=perl6
