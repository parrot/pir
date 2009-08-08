#!parrot

.sub "get_tests"
    .local pmc tests
    tests = new ['ResizablePMCArray']

    $P0 = 'make_test'( <<'CODE', 'if statement' )
.sub main			
	
	if 1 < 2 goto L1
L1:
	if 2 > 3 goto L2
L2:
	if 1 <= 2 goto L3
L3:
	if 2 >= 2 goto L4
L4:
	if 3 == 3 goto L5
L5:
	if 3 != 4 goto L6
L6:

.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'unless statement' )
.sub main			
	
	unless 1 < 2 goto L1
L1:
	unless 2 > 3 goto L2
L2:
	unless 1 <= 2 goto L3
L3:
	unless 2 >= 2 goto L4
L4:
	unless 3 == 3 goto L5
L5:
	unless 3 != 4 goto L6
L6:

.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'goto statement' )
.sub main			
	
	goto L1
L1:

.end
CODE
    push tests, $P0
    
    .return (tests)
.end

