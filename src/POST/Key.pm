class POST::Key is POST::Value;

=begin Description
This stub class (almost) exists to give a unique class for mmd in POST::Compiler::to_pbc.

A POST::Key represents a single (possibly compound) key such as [1] or ['Foo';'Bar';'Buz'].
=end Description

our method Str() {
    '[' ~ @(self).map(sub($p) { $p<value> }).join(';') ~ ']';
}

# vim: ft=perl6
