#!/usr/bin/env parrot

=head1 NAME

setup.pir - Python distutils style

=head1 DESCRIPTION

No Configure step, no Makefile generated.

=head1 USAGE

    $ parrot setup.pir build
    $ parrot setup.pir test
    $ sudo parrot setup.pir install

=cut

.sub 'main' :main
    .param pmc args
    $S0 = shift args
    load_bytecode 'distutils.pbc'

    $P0 = new 'Hash'
    $P0['name'] = 'pir'
    $P0['abstract'] = 'the pir compiler'
    $P0['description'] = 'the pir for Parrot VM.'

    # build
    $P1 = new 'Hash'
    $P1['src/PIR/Actions.pir']  = 'src/PIR/Actions.pm'
    $P1['src/PIR/Grammar.pir']  = 'src/PIR/Grammar.pm'
    $P1['src/PIR/Compiler.pir'] = 'src/PIR/Compiler.pm'

    $P1['src/POST/Compiler.pir'] = 'src/POST/Compiler.pm'
    $P1['src/POST/Sub.pir']      = 'src/POST/Sub.pm'
    $P1['src/POST/Value.pir']    = 'src/POST/Value.pm'
    $P1['src/POST/Constant.pir'] = 'src/POST/Constant.pm'
    $P1['src/POST/Register.pir'] = 'src/POST/Register.pm'

    # Functions for testing.
    $P1['t/parse.pir'] = 't/parse.nqp'
    $P1['t/post.pir']  = 't/post.nqp'

    $P0['pir_nqp'] = $P1

    $P3 = new 'Hash'
    $P4 = split "\n", <<'SOURCES'
pir.pir

src/PIR/Actions.pir
src/PIR/Grammar.pir
src/PIR/Compiler.pir

src/POST/Compiler.pir
src/POST/Sub.pir

src/POST/Value.pir
src/POST/Constant.pir
src/POST/Register.pir

SOURCES
    $P3['pir.pbc'] = $P4

    $P5 = split "\n", <<'SOURCES'
t/common.pir

t/parse.pir
t/test_post.pir
t/post.pir
SOURCES

    $P3['t/common.pbc'] = $P5

    $P0['pbc_pir'] = $P3

    $P7 = new 'Hash'
    $P7['parrot-pir'] = 'pir.pbc'
    $P0['installable_pbc'] = $P7

    # Test
    $S0 = get_nqp()
    $P0['test_exec'] = $S0
    $P0['test_files'] = 't/*/*.t'

    .tailcall setup(args :flat, $P0 :flat :named)
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

