#!parrot

.sub "main"
    .local pmc tests

    tests = 'get_tests'()
    'test_parse'(tests)
.end

.include 't/common.pir'
.include 't/data/tail.pir'

