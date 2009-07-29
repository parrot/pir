# Common functions for tests
# Test with F<prove -e parrot t/common.pir>

# "Main" sub for self testing.
.sub "main"
    .local pmc tests
    tests = 'get_parse_tests'()
    "test_parse"(tests)
.end

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
    
    .local pmc t
    .local int result

    $I0 = tests
    'plan'($I0)

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
    goto loop
  parse_fail:
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
