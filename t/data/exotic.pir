#!parrot

.sub "get_tests"
    .local pmc tests
    tests = new ['ResizablePMCArray']


    $P0 = 'make_test'( <<'CODE', '' )
.sub main
    .local pmc x,y

    x = y[x;y;x;y]

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


