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

=item C<labels>
Get all labels.

our method labels() {
    self<labels>;
}

=item C<symbol($name, $value?)
Get or set variable used in POST::Sub.

our method label($name, $value?) {
    my %labels := self<labels>;
    unless %labels {
        self<labels> := hash();
        %labels := self<labels>;
    }

    if $value {
        %labels{$name} := $value;
    }

    %labels{$name};
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


=item C<constant_index>($idx?)
Get or set Sub index in PackfileConstantTable

our multi method constant_index() { self<constant_index>; }
our multi method constant_index($idx) { self<constant_index> := $idx; $idx }

INIT {
    pir::load_bytecode('nqp-setting.pbc');
}

# vim: ft=perl6
