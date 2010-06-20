module POST::Sub;

=item C<symtable>
Get whole symtable. Used in register allocator.

our method symtable() {
    self<symtable>;
}

=item C<symbol($name, $value?)
Get or set variable used in POST::Sub.

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

=item C<param($name, POST::Register $param)
Add Sub parameter.

our method param($name, POST::Register $param) {
    my @params := self<params>;
    unless @params {
        self<params> := list();
        @params := self<params>;
    }

    # Don't check redeclaration of register. It should be done early.

    @params.push($param);
}


INIT {
    pir::load_bytecode('nqp-setting.pbc');
}

# vim: ft=perl6
