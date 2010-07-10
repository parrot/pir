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

    # For self-hosted Pirate
    .const 'Sub' pirate_build = 'pirate_build'
    register_step('pirate_build', pirate_build)
    .const 'Sub' pirate_clean = 'pirate_clean'
    register_step_after('pirate_build', pirate_clean)


    $P0 = new 'Hash'
    $P0['name'] = 'pir'
    $P0['abstract'] = 'the pir compiler'
    $P0['description'] = 'the pir for Parrot VM.'

    # build
    $P1 = new 'Hash'
    $P1['src/PIR/Actions.pir']  = 'src/PIR/Actions.pm'
    $P1['src/PIR/Grammar.pir']  = 'src/PIR/Grammar.pm'
    $P1['src/PIR/Compiler.pir'] = 'src/PIR/Compiler.pm'
    $P1['src/PIR/Patterns.pir'] = 'src/PIR/Patterns.pm'

    $P1['src/POST/Compiler.pir'] = 'src/POST/Compiler.pm'
    $P1['src/POST/File.pir']     = 'src/POST/File.pm'
    $P1['src/POST/Call.pir']     = 'src/POST/Call.pm'
    $P1['src/POST/Sub.pir']      = 'src/POST/Sub.pm'
    $P1['src/POST/Value.pir']    = 'src/POST/Value.pm'
    $P1['src/POST/Constant.pir'] = 'src/POST/Constant.pm'
    $P1['src/POST/String.pir']   = 'src/POST/String.pm'
    $P1['src/POST/Register.pir'] = 'src/POST/Register.pm'
    $P1['src/POST/Label.pir']    = 'src/POST/Label.pm'
    $P1['src/POST/Key.pir']      = 'src/POST/Key.pm'

    $P1['src/POST/VanillaAllocator.pir'] = 'src/POST/VanillaAllocator.pm'

    # Functions for testing.
    $P1['t/parse.pir'] = 't/parse.nqp'
    $P1['t/post.pir']  = 't/post.nqp'
    $P1['t/pbc.pir']   = 't/pbc.nqp'

    $P0['pir_nqp'] = $P1

    # Dynops
    $P1 = new 'Hash'
    $P1['pirate_ops'] = 'src/dynops/pirate.ops'
    $P0['dynops'] = $P1

    $P3 = new 'Hash'
    $P4 = split "\n", <<'SOURCES'
pir.pir

src/PIR/Actions.pir
src/PIR/Grammar.pir
src/PIR/Compiler.pir
src/PIR/Patterns.pir

src/POST/Compiler.pir
src/POST/File.pir
src/POST/Call.pir
src/POST/Sub.pir

src/POST/Value.pir
src/POST/Constant.pir
src/POST/Register.pir
src/POST/Key.pir
src/POST/String.pir

src/POST/Label.pir

src/POST/VanillaAllocator.pir

SOURCES
    $P3['pir.pbc'] = $P4

    $P5 = split "\n", <<'SOURCES'
t/common.pir

t/parse.pir
t/test_post.pir
t/post.pir
t/test_pbc.pir
t/pbc.pir
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

    # Build self-hosted version
    $P9 = new ['Hash']
    $P9['pirate.pbc'] = 'pirate.pir'

    $P9['src/PIR/Actions.pbc'] = 'src/PIR/Actions.pir'
    $P9['src/PIR/Grammar.pbc'] = 'src/PIR/Grammar.pir'
    $P9['src/PIR/Compiler.pbc'] = 'src/PIR/Compiler.pir'
    $P9['src/PIR/Patterns.pbc'] = 'src/PIR/Patterns.pir'

    $P9['src/POST/Compiler.pbc'] = 'src/POST/Compiler.pir'
    $P9['src/POST/File.pbc'] = 'src/POST/File.pir'
    $P9['src/POST/Call.pbc'] = 'src/POST/Call.pir'
    $P9['src/POST/Sub.pbc'] = 'src/POST/Sub.pir'

    $P9['src/POST/Value.pbc'] = 'src/POST/Value.pir'
    $P9['src/POST/Constant.pbc'] = 'src/POST/Constant.pir'
    $P9['src/POST/Register.pbc'] = 'src/POST/Register.pir'
    $P9['src/POST/Key.pbc'] = 'src/POST/Key.pir'
    $P9['src/POST/String.pbc'] = 'src/POST/String.pir'

    $P9['src/POST/Label.pbc'] = 'src/POST/Label.pir'

    $P9['src/POST/VanillaAllocator.pbc'] = 'src/POST/VanillaAllocator.pir'
    $P0['pirate__pbc_pir'] = $P9

    .tailcall setup(args :flat, $P0 :flat :named)
.end


.sub 'pirate_build' :anon
    .param pmc kv :slurpy :named
    $P0 = kv['pirate__pbc_pir']
    build_with_pirate($P0)
.end

.sub 'build_with_pirate' :anon
    .param pmc hash
    $P0 = iter hash
  L1:
    unless $P0 goto L2
    .local string pbc, pir
    pbc = shift $P0
    pir = hash[pbc]
    $I0 = newer(pbc, pir)
    if $I0 goto L1
    .local string cmd
    cmd = get_parrot()
    cmd .= " pir.pbc --target=pbc --output="
    cmd .= pbc
    cmd .= " "
    cmd .= pir
    system(cmd, 1 :named('verbose'))
    goto L1
  L2:
.end

.sub 'pirate_clean' :anon
    .param pmc kv :slurpy :named
    $P0 = kv['pirate__pbc_pir']
    clean_key($P0)
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

