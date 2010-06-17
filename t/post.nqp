# nqp

# This file compiled to pir and used in tests.

# Helper grammar to parse test data
grammar POSTTestDataGrammar is HLL::Grammar {
    rule TOP {
        #<?DEBUG>
        <testcase>+
        $ || <.panic: "Can't parse test data">
    };

    rule testcase {
        'test_post' '(' <name> ',' "<<'CODE'" ',' "<<'RESULT'" [ ',' <adverbs> ]? ');'
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


our sub parse_post_tests($file)
{
    pir::load_bytecode('nqp-setting.pbc');
    my $data  := slurp($file);
    my $match := POSTTestDataGrammar.parse($data);
    $match<testcase>;
}

# vim: ft=perl6
