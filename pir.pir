# Copyright (C) 2007-2008, Parrot Foundation.
# $Id$

.HLL 'PIRATE'

.namespace []

.sub '' :anon :load :init
    load_bytecode 'HLL.pbc'

    .local pmc hllns, parrotns, imports
    hllns = get_hll_namespace
    parrotns = get_root_namespace ['parrot']
    imports = split ' ', 'PAST POST PCT HLL Regex Hash ResizablePMCArray'
    parrotns.'export_to'(hllns, imports)
.end


.include 'src/PIR/Actions.pir'
.include 'src/PIR/Grammar.pir'
.include 'src/PIR/Compiler.pir'

.namespace []
.sub 'main' :main
    .param pmc args

    .local pmc stages
    # We actually create POST tree from Parse.
    stages = split ' ', 'parse postshortcut pbc'
    $P0 = compreg 'PIRATE'
    $P0.'stages'(stages)
    $P0.'command_line'(args)
    exit 0
.end



=head1 LICENSE

Copyright (C) 2007-2010, Parrot Foundation.

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
