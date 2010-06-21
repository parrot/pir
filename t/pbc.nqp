# nqp

# This file compiled to pir and used in tests.

# Helper grammar to parse test data
grammar PBCTestDataGrammar is HLL::Grammar {
    rule TOP {
        #<?DEBUG>
        <testcase>+
        $ || <.panic: "Can't parse test data">
    };

    rule testcase {
        'test_pbc' '(' <name> ',' "<<'CODE'" [ ',' <adverbs> ]? ');'
        <code>
        <result>
    }

    token name   { <quote> }
    token code   { $<content>=[.*? \n] 'CODE' \n  }
    token result { $<content>=[.*? \n] 'RESULT' \n  }

    rule adverbs { <adverb> ** ',' }
    rule adverb  { <name=quote> '=>' <value=quote> }

    proto token quote { <...> }
    token quote:sym<apos> { <?[']> <quote_EXPR: ':q'>  }
    token quote:sym<dblq> { <?["]> <quote_EXPR: ':q'> }

    token ws {
        <!ww>
            [
            | '#' \N*
            | \h+
            | \v
            ]*
    }
};

our sub parse_pbc_tests($file)
{
    pir::load_bytecode('nqp-setting.pbc');
    my $data  := slurp($file);
    my $match := PBCTestDataGrammar.parse($data);
    $match<testcase>;
}

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
