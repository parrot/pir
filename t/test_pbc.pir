# There is no way to .loadlib io_ops from nqp...
.loadlib 'io_ops'

.sub "test_pbc"
    .param string test_name
    .param string code
    .param string expected
    .param pmc    adverbs

    .include "test_more.pir"
    load_bytecode "pir.pbc"
    load_bytecode "dumper.pbc"
    load_bytecode "PGE/Dumper.pbc"

    #pir::trace(4);
    .local pmc c
    c = compreg 'PIRATE'
    $P0 = split ' ', 'parse post pbc'
    c.'stages'($P0)

    .local pmc post
    push_eh fail
    post = c.'compile'(code, "target" => 'pbc', "output" => 'tmp.pbc')

    # XXX It will probably not work on Windows...
    $I0 = spawnw "parrot tmp.pbc 1>tmp.out 2>tmp.err"

    $S0 = slurp('tmp.out')

    is($S0, expected, test_name)
    .return()

  fail:
    pop_eh
    .local pmc exception
    .get_results (exception)

    $S0 = adverbs['fail_like']
    if null $S0 goto check_fail
    $S1 = exception
    $I0 = index $S1, $S0
    $I1 = $I0 != -1
    ok($I1, test_name)
    diag(exception)
    diag($S0)
    .return()

  check_fail:
    $I0 = adverbs['fail']
    ok($I0, test_name)
    .return()

#    CATCH {
#        ok(%adverbs<fail>, $test_name);
#        diag("POST failed $!");
#    };
.end

# vim: ft=pir
