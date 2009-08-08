#!parrot

.sub "get_tests"
    .local pmc tests
    tests = new ['ResizablePMCArray']

    $P0 = 'make_test'( <<'CODE', 'local decls 1' )

.sub main
	.local int a
	.local string b
	.local num c
	.local pmc d
.end

CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'local decls 2' )

.sub main
	.local int a, k, l, m
	.local string b, n, o, p
	.local num c, q, r, s
	.local pmc d, t, u
.end

CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'local decls - unique_reg' )

.sub main
	.local int a :unique_reg, b, c
	.local num e, f :unique_reg, g
	.local pmc h, i, j :unique_reg
.end

CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'lexicals' )

.sub main
	.local pmc a
	.lex "x", $P0
	.lex "y", a
.end

CODE
    push tests, $P0
    
    .return (tests)
.end
