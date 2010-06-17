#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

my @tests := parse_post_tests('t/post/subs.txt');
for @tests -> $t {
    my %adverbs;
    if $t<adverbs> {
        for $t<adverbs>[0]<adverb> -> $a {
            %adverbs{dequote($a<name>)} := dequote($a<value>);
        }
    }
    test_post( $t<name>, $t<code><content>, $t<result><content>, %adverbs );
};

done_testing();

sub dequote($a) {
    my $l := pir::length__IS($a);
    pir::substr__SSII($a, 1, $l-2);
}
# vim: ft=perl6
