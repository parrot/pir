#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');
run_pbc_tests_from_datafile('t/pbc/call.txt');

# vim: ft=perl6
