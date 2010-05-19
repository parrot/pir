class PIR::Compiler is HLL::Compiler;

INIT {
    PIR::Compiler.language('PIR');
    PIR::Compiler.parsegrammar(PIR::Grammar);
    PIR::Compiler.parseactions(PIR::Actions);
}

# vim: filetype=perl6:

