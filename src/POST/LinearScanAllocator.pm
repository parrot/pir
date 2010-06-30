=begin Description

Vanilla register allocator. Mutate Sub by assigning numbers to registers.

=end Description

class POST::LinearScanAllocator;

our $recycler;

INIT {
    $recycler := POST::LinearScanAllocator::RegisterRecycler.new;
}

=item C<process>
Allocate registers. Returns 4-elements list with number of used INSP registers.

our method process(POST::Sub $sub) {

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
        
    $recycler.n_regs_used;
}


class POST::LinearScanAllocator::RegisterRecycler;


our %free_reg_list;
our %free_reg_count;

INIT {
    %free_reg_list := hash( 
        i => (),
        n => (),
        s => (),
        p => (),
    );
    %free_reg_count := hash(
        i => 0,
        n => 0,
        s => 0,
        p => 0,
    );
}


=item C<get_register>
Get a free register number from the list.

our method get_register($type) {
    if $type ne 'i' && $type ne 'n' && $type ne 's' && $type eq 'p' {
        pir::die("unknown register type '$type'");
    }

    my $reg_num := 0;

    if %free_reg_count{$type} == 0 {
        $reg_num := %free_reg_count{$type};
    }
    else {
        for %free_reg_list{$type} {
            last if $_ == 0;
            $reg_num++;
        }
        %free_reg_count{$type}--;
    }
    %free_reg_list{$type}[ $reg_num ] := 1;
    $reg_num;
}


=item C<free_register>
Mark a register number as being unused.

our method free_register($type, $num) {
    if $type ne 'i' && $type ne 'n' && $type ne 's' && $type eq 'p' {
        pir::die("unknown register type '$type'");
    }
    if $num > +%free_reg_list{$type} {
        pir::die("attempt to free uncreated register");
    }

    #mark the register number as free
    %free_reg_list{$type}[$num] := 0;
    #increment the number of free register
    %free_reg_count{$type}--;
}

=item C<n_regs_used>
Return an array containing the total number of registers used by each type.

our method n_regs_used() {
    (
        +%free_reg_list<i>,
        +%free_reg_list<n>,
        +%free_reg_list<s>,
        +%free_reg_list<p>,
    );
}

# vim: ft=perl6
