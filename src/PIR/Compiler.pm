class PIR::Compiler is HLL::Compiler;

INIT {
    PIR::Compiler.language('PIRATE');
    PIR::Compiler.parsegrammar(PIR::Grammar);
    PIR::Compiler.parseactions(PIR::Actions);
}

=begin
Emit PBC file.

Long explanation about it:
Currently there is no way in Parrot to generate Packfile and attach it
to Interp via existing API. This function is partially hack to generate
serialized PBC, load it back and execute it (modulus fix for TT#1685).

Best way to deal with such issues is:
1. Switch Interp to use Packfile* PMC internally.
2. Add API calls to attach freshly generated Packfile to current Interp.

Quick "fix" can be:
1. Add "PackFile_unpack_string" function which will accept STRING.
2. Expose this function via Interp (or Packfile PMC method).

Kind of wishful thinking, but we can fix it.

=end

our method pbc($post, *%adverbs) {
    #pir::trace(4);
    my $packfile := POST::Compiler.pbc($post, %adverbs);

    my $main_sub := $post<main_sub>;

    my $unlink;
    my $filename := ~%adverbs<output>;
    if !$filename {
        # TODO Add mkstemp into OS PMC.
        $filename := "/tmp/temp.pbc";
        $unlink   := 1;
    }

    my $handle := pir::new__Ps('FileHandle');
    $handle.open($filename, 'w');
    $handle.print(~$packfile);
    $handle.close();

    return sub() {
        #pir::trace(1);
        pir::load_bytecode($filename);

        #if $unlink {
        #    my $os := pir::new__PS("OS");
        #    $os.rm($filename);
        #}

        Q:PIR<
            %r = find_lex '$main_sub'
            $S99 = %r
            %r = find_sub_not_null $S99
            %r()
        >;
    };
}

our method postshortcut($source, *%adverbs) {
    $source.ast;
}

# vim: filetype=perl6:
