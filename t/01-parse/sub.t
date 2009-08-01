#!parrot

.include 't/common.pir'
.sub "main" :main
    .local pmc tests

    load_bytecode 'pir.pbc'
    .include 'test_more.pir'

    tests = 'get_tests'()
    'test_parse'(tests)
.end

.sub "get_tests"
    .local pmc tests
    tests = new ['ResizablePMCArray']

    $P0 = 'make_test'( <<'CODE', 'basic sub' )
.sub main
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'main flag' )
.sub main :main
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'load flag' )
.sub main :load
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'init flag' )
.sub main :init
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'immediate flag' )
.sub main :immediate
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'lex flag' )
.sub main :lex
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'anon flag' )
.sub main :anon
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'outer flag' )

.sub outer_sub
.end

.sub bar :outer(outer_sub)
.end

.sub main :outer('outer_sub')
.end

CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 1' )
.sub main :multi(int)
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 2' )
.sub main :multi(int, num)
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 3' )
.sub main :multi(_, int, num, string, pmc)
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 4' )
.sub main :multi(int, _, num, string, _)
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 5' )
.sub main :multi(_)
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 6' )
.sub main :multi(int, int, int, int)
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 7' )
.sub main :multi(_, _, _, _, _, _)
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'multi flag 8' )
.sub main :multi('Integer', 'Foo')
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'vtable flag' )
.sub main :vtable('__set_int')
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'combine flags without commas' )
.sub main :main :load :immediate :init
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'parameters' )
.sub main
	.param pmc pargs
	.param int iarg
	.param string sarg
	.param num narg
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'parameter flags' )
.sub main
	.param pmc args1 :slurpy
	.param pmc args2 :named
	.param pmc args3 :optional
	.param int arg3  :opt_flag
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'sub' )
.sub x
	.param int i                    # positional parameter
  .param pmc argv :slurpy         # slurpy array
  .param pmc value :named('key')  # named parameter
  .param int x :optional          # optional parameter
  .param int has_x :opt_flag          # flag 0/1 x was passed
  .param pmc kw :slurpy :named    # slurpy hash
.end
CODE
    push tests, $P0
    
    .return (tests)
.end



