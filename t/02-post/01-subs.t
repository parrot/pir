#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');
run_post_tests_from_datafile('t/post/subs.txt', :keep_going);
run_post_tests_from_datafile('t/post/params.txt', :keep_going);
run_post_tests_from_datafile('t/post/sub-modifiers.txt', :keep_going);

done_testing();

# vim: ft=perl6
