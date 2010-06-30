=begin Description

Linear Scan Register Allocator

=end Description

class POST::LinearScanAllocator;

our $recycler;

=item C<process>
Allocate registers. Returns 4-elements list with number of used INSP registers.

our method process(POST::Sub $sub) {

    #breaks if in an INIT block
    unless pir::defined($recycler) {
        $recycler := POST::LinearScanAllocator::RegisterRecycler.new;
    }
    $recycler.reset;

    my $op_num := 0;

    for @($sub) -> $op {
        for @($op) -> $arg {
            pir::say("found a thing with type { $arg<type>} name d { $arg<name> }");
            unless pir::defined($sub.symtable{ $arg<name> }<start>) {
                $sub.symtable{ $arg<name> }<start> := $op_num;
            }
            $sub.symtable{ $arg<name> }<end> := $op_num;
        }
        $op_num++;
    }

    #walk the liveness range list
        #if you hit a starting position
            #grab a register from the recycler
            #assign it to the symbol
        #if you hit an end position
            #give that number back to the recycler
        
    $recycler.n_regs_used;
}


class POST::LinearScanAllocator::RegisterRecycler;


our %reg_usage_list;
our %free_reg_count;

=item C<reset>
Clear all internal state.

our method reset() {
    %reg_usage_list := hash( 
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
        for %reg_usage_list{$type} {
            last if $_ == 0;
            $reg_num++;
        }
        %free_reg_count{$type}--;
    }
    %reg_usage_list{$type}[ $reg_num ] := 1;
    $reg_num;
}


=item C<free_register>
Mark a register number as being unused.

our method free_register($type, $num) {
    if $type ne 'i' && $type ne 'n' && $type ne 's' && $type eq 'p' {
        pir::die("unknown register type '$type'");
    }
    if $num > +%reg_usage_list{$type} {
        pir::die("attempt to free uncreated register");
    }

    #mark the register number as free
    %reg_usage_list{$type}[$num] := 0;
    #increment the number of free register
    %free_reg_count{$type}++;
}

=item C<n_regs_used>
Return an array containing the total number of registers used by each type.

our method n_regs_used() {
    (
        +%reg_usage_list<i>,
        +%reg_usage_list<n>,
        +%reg_usage_list<s>,
        +%reg_usage_list<p>,
    );
}

# vim: ft=perl6
