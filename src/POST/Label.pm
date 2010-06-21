module POST::Label;

=item C<declared>
Set to 1 of we did see label: inside.

our multi method declared($param) { self.attr('declared', $param, 1); }
our multi method declared()       { self.attr('declared', undef,  0); }

# Position in bytecode segment.
our multi method position($param) { self.attr('position', $param, 1); }
our multi method position()       { self.attr('position', undef,  0); }


# vim: ft=perl6
