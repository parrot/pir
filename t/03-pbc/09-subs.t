#! /usr/bin/env parrot-nqp

# Tests for Sub modifiers.
pir::load_bytecode('t/common.pbc');
run_pbc_tests_from_datafile('t/pbc/subs.txt');

# vim: ft=perl6
