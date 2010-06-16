module POST::Compiler;


=begin
Generate PBC file.
=end

our $OPLIB;

method pbc($post, %adverbs) {
    #pir::trace(1);
    $OPLIB := pir::new__PS('OpLib');

    my $pf := pir::new__PS("Packfile");

    # Scaffolding
    # Packfile will be created with fresh directory
    my $pfdir := $pf.'get_directory'();

    # We need some constants
    my $pfconst := pir::new__PS('PackfileConstantTable');

    # Add PackfileConstantTable into directory.
    $pfdir<CONSTANTS_hello.pir> := $pfconst;

    # Generate bytecode
    my $pfbc := pir::new__PS('PackfileRawSegment');

    # Store bytecode
    $pfdir<BYTECODE_hello.pir> := $pfbc;

    # Dark magik. Create Fixup for Sub.
    my $pffixup := pir::new__PS('PackfileFixupTable');

    # Add it to Directory now because adding FixupEntries require Directory
    $pfdir<FIXUP_hello.pir> := $pffixup;

    # Interpreter.
    $pfconst[0] := pir::getinterp__P();

    # Empty FIA for handling returns from "hello"
    $pfconst[1] := pir::new__PS('FixedIntegerArray');

    for @($post) -> $s {
        self.to_pbc($s, $pfbc, $pfconst, $pffixup);
    }

    $pf;
};

our multi method to_pbc(POST::Sub $sub, $pfbc, $pfconst, $pffixup) {

    # Packfile poop his pants...
    my $sb := pir::new__PS('StringBuilder');
    $sb.push(~$sub.name);
    my $subname := ~$sb;


    pir::say("Emitting $subname");

    $pfconst.get_or_create_string($subname);

    my $start_offset := +$pfbc;
    pir::say("From $start_offset");


    # Emit ops.
    for @($sub) {
        self.to_pbc($_, $pfbc, $pfconst);
    }

    # Default .return()
    $pfbc.push($OPLIB<set_returns_pc>);
    $pfbc.push(0x001);                      # id of FIA
    $pfbc.push($OPLIB<returncc>);

    my $end_offset := +$pfbc;
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
    my $idx := $pfconst.push(pir::new__PSP('Sub', %sub));

    pir::say("Fixup $subname");
    my $P1 := pir::new__PSP('PackfileFixupEntry', hash(
            :name( ~$subname ),
            :type<1>,
            :offset( $idx ), # Constant 
        ));

    $pffixup.push($P1);
}

our multi method to_pbc(POST::Op $op, $pfbc, $pfconst) {
    # Generate full name
    my $fullname := $op.pirop;
    pir::say("Short name $fullname");

    for @($op) {
        $fullname := ~$fullname ~ '_' ~ ~$_.type;
    }

    pir::say("Fullname $fullname");
    $pfbc.push($OPLIB{$fullname});

    for @($op) {
        self.to_pbc($_, $pfbc, $pfconst);
    }
}

our multi method to_pbc(POST::Constant $op, $pfbc, $pfconst) {
    # Strings for now.
    my $idx := $pfconst.get_or_create_string($op.value);
    pir::say("Index $idx");
    $pfbc.push($idx);
}

# vim: ft=perl6
