class POST::Key is POST::Value;

=begin Description
A POST::Key represents a single key such as ['Foo';'Bar';'Buz'].
=end Description

our multi method keys($param) { self.attr('keys', $param, 1); }
our multi method keys()       { self.attr('keys', undef,  0); }

#keys represented in PIR are constant
our multi method type()       { 'pc'; }

# vim: ft=perl6
