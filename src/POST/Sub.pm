module POST::Sub;

=begin
Same as PAST::Sub C<symbol>
=end
our method symbol($name, $value?) {
    my %symtable := self<symtable>;
    unless %symtable {
        self<symtable> := hash();
        %symtable := self<symtable>;
    }

    if $value {
        %symtable{$name} := $value;
    }

    %symtable{$name};
}

INIT {
    pir::load_bytecode('nqp-setting.pbc');
}

# vim: ft=perl6
