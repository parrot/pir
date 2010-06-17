class POST::Register is POST::Value;

=begin

Representation of single PIR register

=end

our multi method name($param) { self.attr('name', $param, 1); }
our multi method name()       { self.attr('name', undef,  0); }


# vim: ft=perl6
