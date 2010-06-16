class POST::Constant is POST::Node;

=begin

Representation of single PIR constant.

=end

our method type($value?)  { self.attr('type', $value, pir::defined($value)); }
our method value($value?) { self.attr('value', $value, pir::defined($value)); }

# vim: ft=perl6

