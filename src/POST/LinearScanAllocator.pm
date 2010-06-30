=begin Description

Vanilla register allocator. Mutate Sub by assigning numbers to registers.

=end Description

class POST::LinearScanAllocator;

our %type2idx;

INIT {
    %type2idx := hash(
        i => 0,
        n => 1,
        s => 2,
        p => 3,
    );
}

=item C<process>
Allocate registers. Returns 4-elements list with number of used INSP registers.

our method process(POST::Sub $sub) {
    ...
}

# vim: ft=perl6
