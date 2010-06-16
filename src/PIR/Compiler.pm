class PIR::Compiler is HLL::Compiler;

INIT {
    PIR::Compiler.language('PIRATE');
    PIR::Compiler.parsegrammar(PIR::Grammar);
    PIR::Compiler.parseactions(PIR::Actions);
}

=begin
our method pbc($post, *%adverbs) {
    pir::say(%adverbs<output>);
    my $pbc := "World";

    # Closure to invoke PBC.
    sub() {
        pir::say("Aloha, " ~ $pbc);
    }
}
=end

our method postshortcut($source, *%adverbs) {
    pir::say("hi");
    my $astgrammar_name := self.astgrammar();
    my $typeof := pir::typeof__SP($astgrammar_name);
    pir::say($typeof);
    pir::say($astgrammar_name);
    my $post := $source.ast;
    $post;
}

# vim: filetype=perl6:
