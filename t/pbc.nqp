# nqp

# This file compiled to pir and used in tests.

our sub run_pbc_tests_from_datafile($file, :$keep_going?)
{
    my @tests := parse_post_tests($file);
    for @tests -> $t {
        my %adverbs;
        if $t<adverbs> {
            for $t<adverbs>[0]<adverb> -> $a {
                %adverbs{dequote($a<name>)} := dequote($a<value>);
            }
        }
        test_pbc( $t<name>, $t<code><content>, $t<result><content>, %adverbs );
    };

    done_testing() unless $keep_going;
}

sub dequote($a) {
    my $l := pir::length__IS($a);
    pir::substr__SSII($a, 1, $l-2);
}



# vim: ft=perl6
