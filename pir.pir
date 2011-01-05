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


.include 'gen/PIR/Actions.pir'
.include 'gen/PIR/Grammar.pir'
.include 'gen/PIR/Compiler.pir'
.include 'gen/PIR/Patterns.pir'

#.HLL 'parrot'
.include 'gen/POST/VanillaAllocator.pir'
.include 'gen/POST/Compiler.pir'
.include 'gen/POST/File.pir'
.include 'gen/POST/Sub.pir'
.include 'gen/POST/Call.pir'
.include 'gen/POST/Value.pir'
.include 'gen/POST/Constant.pir'
.include 'gen/POST/String.pir'
.include 'gen/POST/Register.pir'
.include 'gen/POST/Label.pir'
.include 'gen/POST/Key.pir'

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
