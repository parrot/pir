#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

my @tests := parse_post_tests('t/post/subs.txt');
for @tests -> $t {
    test_post( $t<name>, $t<code><content>, $t<result><content>, |$t<adverbs> );
};

done_testing();

# vim: ft=perl6
