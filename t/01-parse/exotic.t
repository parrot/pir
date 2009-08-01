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


    $P0 = 'make_test'( <<'CODE', '' )
.sub main

    x = y[x,y;x,y]

.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', '' )

.sub main
    x.hello()
    x.'hello'()
.end

CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', '' )
.sub main


.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', '' )
.sub main


.end
CODE
    push tests, $P0
    
    .return (tests)
.end


