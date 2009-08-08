#!parrot

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
