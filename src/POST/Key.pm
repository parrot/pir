class POST::Key is POST::Value;

=begin Description
This stub class (almost) exists to give a unique class for mmd in POST::Compiler::to_pbc.

A POST::Key represents a single (possibly compound) key such as [1] or ['Foo';'Bar';'Buz'].
=end Description

our method Str() {
    '[' ~ @(self).map(sub($p) { $p<value> }).join(';') ~ ']';
}

=item C<to_pmc>
Convert POST::Key to Key PMC. C<$constants> is C<PackfileConstantTable> for storing
string parts.

# Key flags:
# KEY_integer_FLAG        = PObj_private0_FLAG == 0x01
# KEY_number_FLAG         = PObj_private1_FLAG == 0x02
# KEY_string_FLAG         = PObj_private2_FLAG == 0x04
# KEY_pmc_FLAG            = PObj_private3_FLAG == 0x08
# KEY_register_FLAG       = PObj_private4_FLAG == 0x10

our method to_pmc(%context) {
    my $key_pmc;
    my $constants := %context<constants>;

    for @(self) -> $part {
        my $k := pir::new__ps('Key');

        if $part.type eq 'sc' {
            $k.set_str(~$part.value);
            $constants.get_or_create_string($part.value);
        }
        elsif $part.type eq 'ic' {
            $k.set_int(+$part.value);
        }
        else {
            pir::die("unknown key type: { $part.type }");
        }

        if !pir::defined__ip($key_pmc) {
            $key_pmc := $k;
        }
        else {
            $key_pmc.push($k);
        }
    }

    $key_pmc;
}

# vim: ft=perl6
