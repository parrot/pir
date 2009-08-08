#!parrot

.sub "get_tests"
    .local pmc tests
    tests = new ['ResizablePMCArray']

    $P0 = 'make_test'(<<'CODE', 'simple assignments' )
.sub main			
    .local int a
    .local num b
    .local string c
    .local pmc d, e
	a = 1
	b = 1.1
	c = "hello"
	d = e
.end
CODE
    push tests, $P0

    $P0 = 'make_test'(<<'CODE', 'int/hex/bin' )
.sub main			
	a = 10
	b = 0b10
	c = 0x10	
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'get keyed assignments' )
.sub main			
	e = x[1]
	f = x[1.1]
	g = x["hello"]
	h = x[e]	
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'set keyed assignments' )
.sub main			
	x[1]        = 1
	x[1.1]      = 2.222
	x["hello"]	= "hello"
	x[e]        = f
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'simple expressions' )
.sub main			
	.local int x,y,z,a,b,c
	x = 1 + 2
	x = 1 * 2
	y = 2 / 4
	y = 2 - 4
	z = 2 ** 4
	z = 2 % 1
	a = b &  c
	a = b && c
	a = b |  c
	a = b || c
	a = b << c
	a = b >> c
	a = b >>> c
	a = - x
	a = ! x
	a = ~ x
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'assign operators' )
.sub main			
	.local int x
	x = 0
	x += 1
	x *= 5
	x /= 2
	x -= 1
	x %= 2
	x <<= 1
	x >>= 1
	x >>>= 1
.end
CODE
    push tests, $P0

    $P0 = 'make_test'( <<'CODE', 'string charset modifiers' )
.sub main			
	.local string s
	s = ascii:"Hello World"
	s = binary:"Hello WOrld"
	s = unicode:"Hello world"
	s = iso-8859-1:"Hello world"		 
	s = utf8:unicode:"Hello World"
.end
CODE
    push tests, $P0
    
    .return (tests)
.end
