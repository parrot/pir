#!parrot

.sub "get_tests"
    .local pmc tests
    tests = new ['ResizablePMCArray']

    $P0 = 'make_test'( <<'CODE', 'globalconst' )

.sub main
	.globalconst int x = 42
	.globalconst num pi = 3.14
	.globalconst string hi = "hello"	
.end

CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'const' )

.sub main
	.const int x = 42
	.const num pi = 3.14
	.const string hi = "hello"
.end

CODE
    push tests, $P0
    
    .return (tests)
.end


