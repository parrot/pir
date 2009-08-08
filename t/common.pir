# Common functions for tests
# Test with F<prove -e parrot t/common.pir>

# "Main" sub for self testing.
.sub "self_test"
    .local pmc tests
    
    load_bytecode 'pir.pbc'
    .include 'test_more.pir'

    'plan'(7)
    tests = 'get_parse_tests'()
    "test_parse"(tests, 1)
    "test_past"(tests, 1)
.end
# Expected result from "self_test" is
# 1..5
# ok 1 - First test
# ok 2 - Second test
# ok 3 - Fail test
# not ok 4 # TODO Todo test
# ok 5 # TODO Unexpected passed todo test
# 1..5
# ok 6 - First test
# ok 7 - Second test


# Test parsers.
# Accept array of hashes.
# Hash must contains:
#   test - PIR to parse
#   desc - Description of test
# Hash may contains:
#   fail - expected parse failure
#   todo - unimplemented parser bit
.sub "test_parse"
    .param pmc tests
    .param int no_plan      :optional
    .param int has_no_plan  :opt_flag
    
    if no_plan goto run
    $I0 = tests
    'plan'($I0)

  run:
    .local pmc t
    .local int result

    .local pmc compiler
    compiler = compreg 'languages-PIR'
    
    $P0 = iter tests
  loop:
    unless $P0 goto done
    result = 0
    t = shift $P0
    $S0 = t['test']
    $S1 = t['desc']
    push_eh parse_fail
    # Compile throws exception in case of failure
    $P2 = compiler.'compile'($S0, 'target'=>'parse')
    result = 1
    $I0 = exists t['todo']
    if $I0 goto check_todo
    'ok'(result, $S1)
    pop_eh
    goto loop
  parse_fail:
    pop_eh
    # Check that is expected or todoed failure
    $I0 = defined t['todo']
    unless $I0 goto check_fail
  check_todo:
    $S2 = t['todo']
    'todo'(result, $S1, $S2)
    goto loop

  check_fail:
    # At this point we fail parse. But it can be expected failure
    result = defined t['fail']
    'ok'(result, $S1)
    goto loop

  done:
.end

# Test parsers for PAST.
# Accept array of hashes.
# Hash must contains:
#   test - PIR to parse
#   desc - Description of test
# Hash may contains:
#   fail - expected parse failure
#   todo - unimplemented parser bit
# Difference from test_parse that we will skip todoed and failed tests.
.sub "test_past"
    .param pmc tests
    .param int no_plan      :optional
    .param int has_no_plan  :opt_flag
    
    if no_plan goto run
    'plan'('no_plan')

  run:
    .local pmc t
    .local int result

    .local pmc compiler
    compiler = compreg 'languages-PIR'
    
    $P0 = iter tests
  loop:
    unless $P0 goto done
    result = 0
    t = shift $P0
    $I0 = exists t['todo']
    if $I0 goto loop
    $I0 = exists t['fail']
    if $I0 goto loop

    $S0 = t['test']
    $S1 = t['desc']
    push_eh past_fail
    # Compile throws exception in case of failure
    $P2 = compiler.'compile'($S0, 'target'=>'past')
    'ok'(1, $S1)
    pop_eh
    goto loop
  past_fail:
    pop_eh
    'ok'(0, $S1)
    goto loop

  done:
.end
# Helper for make single test
.sub 'make_test'
    .param string test
    .param string desc
    .param pmc options :slurpy :named

    .local pmc t
    t = options
    t['test'] = test
    t['desc'] = desc

    .return (t)
.end


# Tests to test _test_parse
.sub "get_parse_tests"
    .local pmc tests
    tests = new ['ResizablePMCArray']

    $P0 = new ['Hash']
    tests[0] = $P0
    tests[0;'desc'] = 'First test'
    tests[0;'test'] = <<'END'
    .sub "bar"
    .end
END

    $P0 = new ['Hash']
    tests[1] = $P0
    tests[1;'desc'] = 'Second test'
    tests[1;'test'] = <<'END'
    .sub "bar" :multi()
    .end
END

    $P0 = new ['Hash']
    tests[2] = $P0
    tests[2;'desc'] = 'Fail test'
    tests[2;'fail'] = 1
    tests[2;'test'] = <<'END'
    .sub "bar" :multi()
END

    $P0 = new ['Hash']
    tests[3] = $P0
    tests[3;'desc'] = 'Todo test'
    tests[3;'todo'] = 'Mega todoed test'
    tests[3;'test'] = <<'END'
    .sub "bar" :multi()
END

    $P0 = new ['Hash']
    tests[4] = $P0
    tests[4;'desc'] = 'Unexpected passed todo test'
    tests[4;'todo'] = 'Todo that passed'
    tests[4;'test'] = <<'END'
    .sub "bar"
    .end
END

    .return (tests)
.end
