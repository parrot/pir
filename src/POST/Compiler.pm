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
    my %context := self.create_context($post);

    %context<pir_file> := $post;

    # Iterate over Subs and put them into POST::File table.
    # Used for discriminating find_sub_not_null vs "constant Subs" in
    # PCC call handling.
    self.enumerate_subs($post);

    for @($post) -> $s {
        self.to_pbc($s, %context);
    }

    %context<packfile>;
};

##########################################
# Emiting pbc

our multi method to_pbc($what, %context) {
    self.panic($what.WHAT);
}

our multi method to_pbc(Undef $what, %context) {
    # Do nothing.
}

our multi method to_pbc(POST::Sub $sub, %context) {
    # Store current Sub in context to resolve symbols and constants.
    %context<sub> := $sub;

    # Allocate registers.
    my @n_regs_used := $REGALLOC.process($sub);
    self.debug('n_regs_used ' ~ @n_regs_used.join('-')) if $DEBUG;
    self.dumper($sub, "sub") if $DEBUG;

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
        # PCT's Sub.subid creates it. So poke inside $sub
        :subid( $sub<subid> // $subname ),
        :ns_entry_name( $sub.nsentry // $subname ),
        :vtable_index( -1 ), # It must be -1!!!
        :HLL_id<0>,
        :method( $sub.method ),

        :n_regs_used(@n_regs_used),

        :pf_flags(self.create_sub_pf_flags($sub)),
        :comp_flags(self.create_sub_comp_flags($sub)),
    );

    if pir::defined__ip($sub.namespace) {
        my $nskey := $sub.namespace.to_pmc(%context<constants>);
        %sub<namespace_name>  := $nskey;
    }

    # and store it in PackfileConstantTable
    # We can have pre-allocated constant for this sub already.
    # XXX Use .namespace for generating full name!
    my $idx := $sub.constant_index;
    if pir::defined__ip($idx) {
        self.debug("Reusing old constant") if $DEBUG;
        %context<constants>[$idx] := pir::new__PSP('Sub', %sub);
    }
    else {
        self.debug("Allocate new constant") if $DEBUG;
        $idx := %context<constants>.push(pir::new__PSP('Sub', %sub));
        $sub.constant_index($idx);
    }

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
        my $type := $_.type || self.get_register($_.name, %context).type;
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

    my $key_pmc := $key.to_pmc(%context<constants>);

    # XXX PackfileConstantTable can't Keys equivalense it. So just push it.
    my $idx := %context<constants>.push($key_pmc);
    %context<bytecode>.push($idx);
}

our multi method to_pbc(POST::Constant $op, %context) {
    my $idx;
    my $type := $op.type;
    if $type eq 'ic' || $type eq 'kic' {
        $idx := $op.value;
    }
    elsif $type eq 'nc' {
        $idx := %context<constants>.get_or_create_number($op.value);
    }
    else {
        self.panic("NYI");
    }

    self.debug("Index $idx") if $DEBUG;
    %context<bytecode>.push($idx);
}

our multi method to_pbc(POST::String $str, %context) {
    my $idx;
    my $type := $str.type;
    if $type ne 'sc' {
        self.panic("attempt to pass a non-sc value off as a string");
    }
    if $str.encoding eq 'fixed_8' && $str.charset eq 'ascii' {
        $idx := %context<constants>.get_or_create_string($str.value);
    }
    else {
        #create a ByteBuffer and convert it to a string with the given encoding/charset
        my $bb := pir::new__ps('ByteBuffer');
        my $str_val := $str.value;
        Q:PIR{
            .local pmc str_val, bb
            .local string s
            str_val = find_lex '$str_val'
            bb      = find_lex '$bb'
            s = str_val
            bb = s
        };
        $idx := %context<constants>.get_or_create_string($bb.get_string(
            $str.charset,
            $str.encoding,
        ));
    }

    %context<bytecode>.push($idx);
}

our multi method to_pbc(POST::Value $val, %context) {
    # Redirect to real value. POST::Value is just reference.
    my $orig := self.get_register($val.name, %context);
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
    my $bc       := %context<bytecode>;
    my $calltype := $call.calltype;
    my $is_tailcall := $calltype eq 'tailcall';

    if $calltype eq 'call' || $calltype eq 'tailcall' {
        if $call.invocant {
            $call<params> := list() unless $call<params>;
            $call<params>.unshift($call.invocant);
        }

        self.build_pcc_call("set_args_pc", $call<params>, %context);

        if $call.invocant {
            if $call.name.isa(POST::Constant) {
                $bc.push($is_tailcall
                            ?? $OPLIB<tailcallmethod_p_sc>
                            !! $OPLIB<callmethodcc_p_sc>);
                self.to_pbc($call.invocant, %context);
                self.to_pbc($call.name, %context);
            }
            else {
                self.panic('NYI $P0.$S0()');
            }
        }
        else {
            my $SUB;
            my $processed := 0;
            if $call.name.isa(POST::Constant) {
                # Constant string. E.g. "foo"()
                # Avoid find_sub_not_null when Sub is constant.
                my $full_name;
                $full_name := %context<sub>.namespace.Str if %context<sub>.namespace;
                $full_name := ~$full_name ~ ~$call<name><value>;
                my $invocable_sub := %context<pir_file>.sub($full_name);
                self.debug("invocable_sub $invocable_sub") if $DEBUG;
                if $invocable_sub {
                    my $idx := $invocable_sub.constant_index;
                    unless pir::defined__ip($idx) {
                        # Allocate new space in constant table. We'll reuse it later.
                        $idx := %context<constants>.push(pir::new__ps("Integer"));
                        $invocable_sub.constant_index($idx);
                    }

                    $SUB := %context<sub>.symbol("!SUB");
                    $bc.push($OPLIB<set_p_pc>);
                    self.to_pbc($SUB, %context);
                    $bc.push($idx);

                    $processed := 1;
                }
            }

            unless $processed {
                if $call.name.isa(POST::Constant) {
                    $SUB := %context<sub>.symbol("!SUB");
                    $bc.push($OPLIB<find_sub_not_null_p_sc>);
                    self.to_pbc($SUB, %context);
                    self.to_pbc($call<name>, %context);
                }
                else {
                    self.debug("Name is " ~ $call<name>.WHAT) if $DEBUG;
                    $SUB := $call<name>;
                }
            }

            my $o := $is_tailcall ?? "tailcall_p" !! "invokecc_p";

            self.debug($o) if $DEBUG;
            $bc.push($OPLIB{ $o });
            self.to_pbc($SUB, %context);
        }

        self.build_pcc_call("get_results_pc", $call<results>, %context);
    }
    elsif $calltype eq 'return' {
        self.build_pcc_call("set_returns_pc", $call<params>, %context);
        $bc.push($OPLIB<returncc>);
    }
    else {
        self.panic("NYI { $calltype }");
    }
}

# /Emiting pbc
##########################################

##########################################
# PCC related functions

our method build_pcc_call($opname, @args, %context) {
    my $bc        := %context<bytecode>;
    my $signature := self.build_args_signature(@args, %context);
    my $sig_idx   := %context<constants>.get_or_create_pmc($signature);

    self.debug("Sig: $sig_idx") if $DEBUG;

    self.debug($opname) if $DEBUG;
    # Push signature and all args.
    $bc.push($OPLIB{ $opname });
    $bc.push($sig_idx);
    for @args -> $arg {
        # Handle :named params 
        if pir::isa__ips($arg.modifier, "Hash") {
            my $name := $arg.modifier<named> // $arg.name;
            %context<bytecode>.push(
                %context<constants>.get_or_create_string($name)
            );
        }
        self.to_pbc($arg, %context);
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

our method build_single_arg($arg, %context) {
    # Build call signature arg according to PDD03
    # POST::Value doesn't have .type. Lookup in symbols.
    my $type := $arg.type // self.get_register($arg.name, %context).type;

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
    else  { self.panic("Unknown arg type '$type'") }

    my $mod := $arg.modifier;
    if $mod {
        if pir::isa__ips($mod, "Hash")  {
            # named
            # First is string constant with :named flag
            $res := list(0x1 + 0x10 + 0x200, $res + 0x200)
        }
        elsif $mod eq 'slurpy'          { $res := $res + 0x20 }  # 5
        elsif $mod eq 'flat'            { $res := $res + 0x20 }  # 5
        elsif $mod eq 'optional'        { $res := $res + 0x80 }  # 7
        elsif $mod eq 'opt_flag'        { $res := $res + 0x100 } # 8
        elsif $mod eq 'slurpy named'    { $res := $res + 0x20 + 0x200 } # 5 + 9
        else { self.panic("Unsupported modifier $mod"); }
    }

    $res;
}

# /PCC related functions
##########################################

our method create_context($past) {
    my %context;

    %context<packfile> := pir::new__PS("Packfile");

    # Scaffolding
    # Packfile will be created with fresh directory
    my $pfdir := %context<packfile>.get_directory;

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

    # TODO pbc_disassemble crashes without proper debug.
    # Add a debug segment.
    # %context<debug> := pir::new__PS('PackfileDebug');

    # Store the debug segment in bytecode
    #$pfdir<BYTECODE_hello.pir_DB> := %context<debug>;

    %context;
}

# XXX This is required only for PAST->POST generated tree.
our method enumerate_subs(POST::File $post) {
    for @($post) -> $sub {
        # XXX Should we emit warning on duplicates?
        $post.sub($sub.full_name, $sub);
    }
}

# Declare as multi to get "static" typecheck.
our multi method create_sub_pf_flags(POST::Sub $sub) {
    # This constants aren't exposed. So keep reference here.
    # SUB_FLAG_IS_OUTER     = PObj_private1_FLAG == 0x01
    # SUB_FLAG_PF_ANON      = PObj_private3_FLAG == 0x08
    # SUB_FLAG_PF_MAIN      = PObj_private4_FLAG == 0x10
    # SUB_FLAG_PF_LOAD      = PObj_private5_FLAG == 0x20
    # SUB_FLAG_PF_IMMEDIATE = PObj_private6_FLAG == 0x40
    # SUB_FLAG_PF_POSTCOMP  = PObj_private7_FLAG == 0x80
    my $res := 0;
    $res := $res + 0x01 * $sub.outer;
    $res := $res + 0x08 * $sub.anon;
    $res := $res + 0x10 * $sub.main;
    $res := $res + 0x20 * $sub.load;
    $res := $res + 0x40 * $sub.immediate;
    $res := $res + 0x80 * $sub.postcomp;

    self.debug("pf_flags $res") if $DEBUG;

    $res;
}

our multi method create_sub_comp_flags(POST::Sub $sub) {
    #    SUB_COMP_FLAG_VTABLE    = SUB_COMP_FLAG_BIT_1   == 0x01
    #    SUB_COMP_FLAG_METHOD    = SUB_COMP_FLAG_BIT_2   == 0x02
    #    SUB_COMP_FLAG_PF_INIT   = SUB_COMP_FLAG_BIT_10  == 0x400
    #    SUB_COMP_FLAG_NSENTRY   = SUB_COMP_FLAG_BIT_11  == 0x800
    my $res := 0;
    $res := $res + 0x001 if $sub.vtable;
    $res := $res + 0x002 if $sub.method;
    $res := $res + 0x400 if $sub.is_init;
    $res := $res + 0x800 if $sub.nsentry;  # XXX Check when to set ns_entry_name in .to_pbc!

    self.debug("comp_flags $res") if $DEBUG;

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

# Get register from symbol table with validation
our method get_register($name, %context) {
    my $reg := %context<sub>.symbol($name);
    if !$reg {
        self.panic("Register '{ $name }' not predeclared in '{ %context<sub>.name }'");
    }
    $reg;
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
