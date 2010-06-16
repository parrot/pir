class POST::Register is POST::Node;

=begin

Representation of single PIR register

=end

our method name($value?) { self.attr('name', $value, pir::defined($value)); }

# vim: ft=perl6
