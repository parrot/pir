module POST::Compiler;


=begin
Generate PBC file.
=end

our $OPLIB;

method pbc($post, %adverbs) {
    #pir::trace(1);
    $OPLIB := pir::new__PS('OpLib');

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

    my $bc := %context<bytecode>;

    # Packfile poop his pants...
    my $sb := pir::new__PS('StringBuilder');
    $sb.push(~$sub.name);
    my $subname := ~$sb;

    pir::say("Emitting $subname");
    %context<constants>.get_or_create_string($subname);

    my $start_offset := +$bc;
    pir::say("From $start_offset");

    # Emit ops.
    for @($sub) {
        self.to_pbc($_, %context);
    }

    # Default .return(). XXX We don't need it (probably)
    $bc.push($OPLIB<set_returns_pc>);
    $bc.push(0x001);                      # id of FIA
    $bc.push($OPLIB<returncc>);

    my $end_offset := +$bc;
    pir::say("To $end_offset");

    # Now create Sub PMC using hash of values.
    my %sub := hash(
        :start_offs( $start_offset ),
        :end_offs( $end_offset ),
        :name( $subname ),
        :subid( $subname ),
        :ns_entry_name( $subname ),
        :HLL_id<0>,
        :method<0>,
    );

    # and store it in PackfileConstantTable
    my $idx := %context<constants>.push(pir::new__PSP('Sub', %sub));

    pir::say("Fixup $subname");
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
    pir::say("Short name $fullname");

    for @($op) {
        my $type := $_.type || %context<sub>.symbol($_.name).type;
        $fullname := ~$fullname ~ '_' ~ ~$type;
    }

    pir::say("Fullname $fullname");
    %context<bytecode>.push($OPLIB{$fullname});

    for @($op) {
        self.to_pbc($_, %context);
    }
}

our multi method to_pbc(POST::Constant $op, %context) {
    # Strings for now.
    my $idx := %context<constants>.get_or_create_string($op.value);
    pir::say("Index $idx");
    %context<bytecode>.push($idx);
}

our multi method to_pbc(POST::Value $val, %context) {
    # Redirect to real value. POST::Value is just reference.
    my $orig := %context<sub>.symbol($val.name);
    self.to_pbc($orig, %context);
}

# vim: ft=perl6
