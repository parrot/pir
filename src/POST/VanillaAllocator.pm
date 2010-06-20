=begin Description

Vanilla register allocator. Mutate Sub by assigning numbers to registers.

=end Description

class POST::VanillaAllocator;

our %type2idx := hash(
    i => 0,
    n => 1,
    s => 2,
    p => 3,
);

=item C<process>
Allocate registers. Returns 4-elements list with number of used INSP registers.

our method process(POST::Sub $sub) {
    my @n_regs_used := (0, 0, 0, 0);
    for $sub.symtable {
        # TODO Skip constants.
        my $idx := %type2idx{$_.key};
        $_.value.regno(@n_regs_used[$idx]);
        @n_regs_used[$idx]++;
    }

    @n_regs_used;
}

# vim: ft=perl6
