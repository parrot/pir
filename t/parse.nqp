# nqp

# This file compiled to pir and used in tests.

Q:PIR{
    # We want Test::More features for testing. Not NQP's builtin.
    .include "test_more.pir"
    load_bytecode "pir.pbc"
};

sub parse($c, $code) {
    my $res := 0;
    try {
        $c.compile(:target('parse'), $code);
        $res := 1;
    }
    $res;
}
