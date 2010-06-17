class POST::Register is POST::Value;

=begin

Representation of single PIR register

=end

our multi method name($param) { self.attr('name', $param, 1); }
our multi method name()       { self.attr('name', undef,  0); }

=begin
=item C<declared>
Boolean flag which set when register declared.

Always set to 1 for "numbered" registers.
=end
our multi method declared($param) { self.attr('declared', $param, 1); }
our multi method declared()       { self.attr('declared', undef,  0); }


# vim: ft=perl6
