# There is no way to .loadlib io_ops from nqp...
.loadlib 'io_ops'

.sub "test_post"
    .param string test_name
    .param string code
    .param string expected
    .param pmc    adverbs   :slurpy :named

    .include "test_more.pir"
    load_bytecode "pir.pbc"
    load_bytecode "dumper.pbc"
    load_bytecode "PGE/Dumper.pbc"

    #pir::trace(4);
    .local pmc c
    c = compreg 'PIRATE'
    $P0 = split ' ', 'parse postshortcut pbc'
    c.'stages'($P0)

    .local pmc post
    push_eh fail
    post = c.'compile'(code, "target" => 'postshortcut')

    # XXX dumper always dump to stdout...
    .local pmc o, n
    o = getstdout
    n = new ['StringHandle']
    n.'open'('foo', "w")
    setstdout n
    c.'dumper'(post, "postshortcut")
    setstdout o

    $S0 = n.'readall'()

    is($S0, expected, test_name)
    .return()

  fail:
    pop_eh
    $I0 = adverbs['fail']
    ok($I0, test_name)

#    CATCH {
#        ok(%adverbs<fail>, $test_name);
#        diag("POST failed $!");
#    };
.end

