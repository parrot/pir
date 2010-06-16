class POST::Constant is POST::Node;

=begin

Representation of single PIR constant.

=end


our multi method type($param)  { self.attr('type', $param, 1); }
our multi method type()        { self.attr('type', undef,  0); }

our multi method value($param) { self.attr('value', $param, 1); }
our multi method value()       { self.attr('value', undef,  0); }

# vim: ft=perl6

