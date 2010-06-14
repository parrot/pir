#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');
run_tests_from_datafile('t/data/macro.txt');

# vim: ft=perl6
