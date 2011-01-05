# Copyright (C) 2007-2008, Parrot Foundation.
# $Id$

#.HLL 'PIRATE'

.namespace []

.sub '' :anon :load :init
    load_bytecode 'HLL.pbc'
    load_bytecode 'nqp-setting.pbc'

    .local pmc hllns, parrotns, imports
    hllns = get_hll_namespace
    parrotns = get_root_namespace ['parrot']
    imports = split ' ', 'PAST POST PCT HLL Regex Hash ResizablePMCArray'
    parrotns.'export_to'(hllns, imports)
.end


.include 'src/PIR/Actions.pir'
.include 'src/PIR/Grammar.pir'
.include 'src/PIR/Compiler.pir'
.include 'src/PIR/Patterns.pir'

#.HLL 'parrot'
.include 'src/POST/VanillaAllocator.pir'
.include 'src/POST/Compiler.pir'
.include 'src/POST/File.pir'
.include 'src/POST/Sub.pir'
.include 'src/POST/Call.pir'
.include 'src/POST/Value.pir'
.include 'src/POST/Constant.pir'
.include 'src/POST/String.pir'
.include 'src/POST/Register.pir'
.include 'src/POST/Label.pir'
.include 'src/POST/Key.pir'
.include 'src/hacks.pir'

#.HLL 'PIRATE'

.namespace []
.sub 'main' :main
    .param pmc args

    .local pmc stages
    # We actually create POST tree from Parse.
    stages = split ' ', 'parse post pbc'
    $P0 = compreg 'PIRATE'
    $P0.'stages'(stages)
    $P0.'addstage'('eliminate_constant_conditional', 'before'=>'pbc')
    $P0.'addstage'('fold_arithmetic', 'before'=>'pbc')
    $P0.'addstage'('swap_gtge', 'before'=>'pbc')
    $P0.'command_line'(args)
    exit 0
.end

=head1 LICENSE

Copyright (C) 2007-2011, Parrot Foundation.

This is free software; you may redistribute it and/or modify
it under the same terms as Parrot.

=head1 AUTHOR

Klaas-Jan Stol <parrotcode@gmail.com>

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
