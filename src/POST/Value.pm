class POST::Value is POST::Node;

=begin Description

Typed PIR value. Either Constant of Register.

=end Description

=begin Attributes

=over
=item C<type>
Type of value. One of <i n s p ic nc sc pc> for Registers and Constants.

=end Attributes

our multi method name($param) { self.attr('name', $param, 1); }
our multi method name()       { self.attr('name', undef,  0); }

our multi method type($param) { self.attr('type', $param, 1); }
our multi method type()       { self.attr('type', undef,  0); }



# vim: ft=perl6
