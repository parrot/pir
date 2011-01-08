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
    register_step('pirate_clean', pirate_clean)


    $P0 = new 'Hash'
    $P0['name'] = 'pir'
    $P0['abstract'] = 'the pir compiler'
    $P0['description'] = 'PIR compiler implemented in NQP/PCT'
    $P6 = split ' ', 'pir hll compiler'
    $P0['keywords'] = $P6
    $P0['authority'] = 'http://github.com/bacek'
    $P0['license_type'] = 'Artistic License 2.0'
    $P0['license_uri'] = 'http://www.perlfoundation.org/artistic_license_2_0'
    $P0['copyright_holder'] = 'Parrot Foundation'
    $P0['checkout_uri'] = 'git://github.com/bacek/pir.git'
    $P0['browser_uri'] = 'http://github.com/bacek/pir'
    $P0['project_uri'] = 'http://github.com/bacek/pir'

    # build
    $P1 = new 'Hash'
    $P1['gen/PIR/Actions.pir']  = 'src/PIR/Actions.pm'
    $P1['gen/PIR/Grammar.pir']  = 'src/PIR/Grammar.pm'
    $P1['gen/PIR/Compiler.pir'] = 'src/PIR/Compiler.pm'
    $P1['gen/PIR/Patterns.pir'] = 'src/PIR/Patterns.pm'

    $P1['gen/POST/Compiler.pir'] = 'src/POST/Compiler.pm'
    $P1['gen/POST/File.pir']     = 'src/POST/File.pm'
    $P1['gen/POST/Call.pir']     = 'src/POST/Call.pm'
    $P1['gen/POST/Sub.pir']      = 'src/POST/Sub.pm'
    $P1['gen/POST/Value.pir']    = 'src/POST/Value.pm'
    $P1['gen/POST/Constant.pir'] = 'src/POST/Constant.pm'
    $P1['gen/POST/String.pir']   = 'src/POST/String.pm'
    $P1['gen/POST/Register.pir'] = 'src/POST/Register.pm'
    $P1['gen/POST/Label.pir']    = 'src/POST/Label.pm'
    $P1['gen/POST/Key.pir']      = 'src/POST/Key.pm'

    $P1['gen/POST/VanillaAllocator.pir'] = 'src/POST/VanillaAllocator.pm'

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
src/hacks.pir

gen/PIR/Actions.pir
gen/PIR/Grammar.pir
gen/PIR/Compiler.pir
gen/PIR/Patterns.pir

gen/POST/Compiler.pir
gen/POST/File.pir
gen/POST/Call.pir
gen/POST/Sub.pir

gen/POST/Value.pir
gen/POST/Constant.pir
gen/POST/Register.pir
gen/POST/Key.pir
gen/POST/String.pir

gen/POST/Label.pir

gen/POST/VanillaAllocator.pir

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
    $P9 = new ['OrderedHash']

    $P9['gen/POST/Compiler.pbc'] = 'gen/POST/Compiler.pir'
    $P9['gen/POST/File.pbc'] = 'gen/POST/File.pir'
    $P9['gen/POST/Call.pbc'] = 'gen/POST/Call.pir'
    $P9['gen/POST/Sub.pbc'] = 'gen/POST/Sub.pir'

    $P9['gen/POST/Value.pbc'] = 'gen/POST/Value.pir'
    $P9['gen/POST/Constant.pbc'] = 'gen/POST/Constant.pir'
    $P9['gen/POST/Register.pbc'] = 'gen/POST/Register.pir'
    $P9['gen/POST/Key.pbc'] = 'gen/POST/Key.pir'
    $P9['gen/POST/String.pbc'] = 'gen/POST/String.pir'

    $P9['gen/POST/Label.pbc'] = 'gen/POST/Label.pir'

    $P9['gen/POST/VanillaAllocator.pbc'] = 'gen/POST/VanillaAllocator.pir'

    $P9['gen/PIR/Actions.pbc'] = 'gen/PIR/Actions.pir'
    $P9['gen/PIR/Compiler.pbc'] = 'gen/PIR/Compiler.pir'
    $P9['gen/PIR/Patterns.pbc'] = 'gen/PIR/Patterns.pir'
    $P9['gen/PIR/Grammar.pbc'] = 'gen/PIR/Grammar.pir'

    $P9['pirate.pbc'] = 'pirate.pir'

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
    cmd .= " pir.pbc --stagestats --target=pbc --output="
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

