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
    my @n_regs_used := (0, 0, 0, 0);

    #for each instruction in the sub
        #for each symbol
            #if it hasn't been seen,
                #store its starting position
            #update its last position

    #walk the liveness range list
        #if you hit a starting position
            #grab a register from the recycler
            #assign it to the symbol
        #if you hit an end position
            #give that number back to the recycler

    @n_regs_used;
}

# vim: ft=perl6
