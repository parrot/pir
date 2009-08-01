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

    $P0 = 'make_test'(<<'CODE', '.tailcall syntax')
.sub 'foo'			
    .tailcall foo()
.end
CODE
    push tests, $P0

    $P0 = 'make_test'(<<'CODE', '.tailcall method syntax' )
.sub 'foo'
    .tailcall self."foo"()
.end
CODE
    push tests, $P0

    .return (tests)
.end
