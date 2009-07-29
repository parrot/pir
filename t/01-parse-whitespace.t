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

    $P0 = 'make_test'( <<'CODE', 'comments before code' )
#
# pre-code comment
#
.sub main			
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'comments after code' )
.sub main			
.end
#
# comments after code
#
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'comments in code' )
.sub main			
#
# in-code comment
#
.end
CODE
    push tests, $P0


    $P0 = 'make_test'( <<'CODE', 'comments after code' )
.sub main			

	x = 1 # this is an assignment!
	# this is comment # this is even more comment
	
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'pre-code whitespace' )











































































































.sub main			
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'in-code whitespace' )
.sub main			















































































































































































.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'after-code whitespace' )
.sub main			
.end










































































































CODE
    push tests, $P0


    $P0 = 'make_test'( <<'CODE', 'pre-code pod comments' )
=pod

hi there

documentation rocks!








=cut



.sub main			
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'in-code pod comments' )
.sub main			

=pod 

hello!!

Parrot rocks too!

=cut
.end
CODE
    push tests, $P0


    $P0 = 'make_test'( <<'CODE', 'after-code pod comments' )
.sub main			
.end

=pod

Don't forget to hit enter after typing last OUT marker in the test file!

=cut

CODE
    push tests, $P0
    
    .return (tests)
.end

