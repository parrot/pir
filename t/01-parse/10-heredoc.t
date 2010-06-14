#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');
run_tests_from_datafile('t/data/heredoc.txt');

# vim: ft=perl6
