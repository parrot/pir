#! /usr/bin/env parrot-nqp

# Tests for Sub modifiers.
pir::load_bytecode('t/common.pbc');
run_pbc_tests_from_datafile('t/pbc/imcc/syn/clash.t', :keep_going);
done_testing();

# vim: ft=perl6

