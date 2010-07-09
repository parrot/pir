=begin Description

Linear Scan Register Allocator

=end Description

class POST::LinearScanAllocator;

my $recycler;

=item C<process>
Allocate registers. Returns 4-elements list with number of used INSP registers.

our method process(POST::Sub $sub) {

    #breaks if in an INIT block
    unless pir::defined($recycler) {
        $recycler := POST::LinearScanAllocator::RegisterRecycler.new;
    }
    $recycler.reset;

    my $op_num := 0;
    my %liveness;
    %liveness<start> := ();
    %liveness<end>   := ();
    pir::say("# starting linear scan");

    for @($sub) -> $op {
        my @starts := ();

        #catch POST::Call and POST::Op
        my $op_type := pir::typeof__sp($op);
        my @arg_list;
        pir::say("# op is of type $op_type");

        if $op_type eq 'POST;Label' {
            next unless +@($op);
            $op := $op[0];
            $op_type := pir::typeof__sp($op);
        }

        if $op_type eq 'POST;Op' {
            @arg_list := @($op);
        } elsif $op_type eq 'POST;Call' {
            @arg_list := $op<params>;
        } else {
            pir::die("don't know how to get args from $op_type");
        }

        for @arg_list -> $arg {

            my $sym;
            my $sym_type := pir::typeof__sp($arg);

            if $sym_type eq 'POST;String'
            || $sym_type eq 'POST;Label'
            || $sym_type eq 'POST;Constant' {
                next;
            } elsif $sym_type eq 'POST;Register' {
                $sym := $sub.symtable{ $arg<name> };
                pir::say("# looked up {$arg<name>} in the symtable");
            } elsif $sym_type eq 'POST;Value' {
                $sym := $arg;
            } else {
                pir::die("# don't know what to do with $sym_type");
            }

            #_dumper($arg);

            pir::say("# found a thing with type { $sym<type>} named { $sym<name> }");
            next unless self._is_insp_reg($sym);
            pir::say("# looks like it's a register");

            unless pir::defined($sub.symtable{ $sym<name> }<start>) {
                $sub.symtable{ $sym<name> }<start>:= +$op_num;
                pir::say("# {$sym<name>} starts at $op_num");
                @starts.push( $sym<name> );
            }
            $sub.symtable{ $sym<name> }<end> := +$op_num;
            #_dumper( $sub.symtable{ $sym<name> });
        }
        %liveness<start>.push( @starts );
        %liveness<end>.push( () );
        $op_num++;
    }

    #_dumper($sub.symtable);
    #for $sub.symtable {
    #    pir::say("found symbol {$_}, range is {$sub.symtable{$_}<start>} -> {$sub.symtable{$_}<end>}");
    #}
    my $n := 0;
    while ($n < +%liveness<start>) {
        pir::say("# liveness analysis: n = $n");        
        for %liveness<start>[$n] -> $sym_name {
            my $sym := $sub.symtable{ $sym_name };
            pir::say("# found a live symbol: {$sym<name>}");
            pir::say("# symbol {$sym<name>} will become dead at {$sym<end>}");
            $sym.regno( $recycler.get_register( $sym<type> ));
            %liveness<end>[ $sym<end> ].push($sym_name);
        }
        for %liveness<end>[$n] -> $sym_name {
            #give that number back to the recycler
            my $sym := $sub.symtable{ $sym_name };
            pir::say("# found a dead symbol {$sym<name>}: will return regno {$sym.regno}");
            $recycler.free_register( $sym<type>, $sym.regno );
        }
        $n++;
    }
        
    $recycler.n_regs_used;
}

our multi method _is_insp_reg($obj) { 0 }
our multi method _is_insp_reg(POST::Register $reg) {
    $reg<type> eq 'i' || $reg<type> eq 'n' || $reg<type> eq 's' || $reg<type> eq 'p'
}
our multi method _is_insp_reg(POST::Value $val) {
    $val<type> eq 'i' || $val<type> eq 'n' || $val<type> eq 's' || $val<type> eq 'p'
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
    unless ($type eq 'i') || ($type eq 'n') || ($type eq 's') || ($type eq 'p') {
        pir::die("unknown register type in get_register: '$type'");
    }

    my $reg_num := 0;

    if %free_reg_count{$type} == 0 {
        $reg_num := +%reg_usage_list{$type};
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
    unless ($type eq 'i') || ($type eq 'n') || ($type eq 's') || ($type eq 'p') {
        pir::die("unknown register type in free_register: '$type'");
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
