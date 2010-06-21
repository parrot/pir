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

our multi method to_pbc(POST::Constant $op, %context) {
    self.debug("Constant") if $DEBUG;
    # Strings for now.
    my $idx := %context<constants>.get_or_create_string($op.value);
    self.debug("Index $idx") if $DEBUG;
    %context<bytecode>.push($idx);
}

our multi method to_pbc(POST::Value $val, %context) {
    self.debug("Value") if $DEBUG;
    # Redirect to real value. POST::Value is just reference.
    my $orig := %context<sub>.symbol($val.name);
    self.to_pbc($orig, %context);
}

our multi method to_pbc(POST::Register $reg, %context) {
    self.debug("Register") if $DEBUG;
    %context<bytecode>.push($reg.regno);
}

our multi method to_pbc(POST::Label $l, %context) {
    self.debug("Label") if $DEBUG;
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

method debug(*@args) {
    if $DEBUG {
        for @args {
            pir::say($_);
        }
    }
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

INIT {
    pir::load_bytecode('nqp-setting.pbc');
}

# vim: ft=perl6
