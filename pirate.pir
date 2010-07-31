# Copyright (C) 2007-2008, Parrot Foundation.
# $Id$

#.HLL 'PIRATE'

.loadlib 'pirate_ops'

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


.loadlib 'src/PIR/Actions.pbc'
.loadlib 'src/PIR/Grammar.pbc'
.loadlib 'src/PIR/Compiler.pbc'
.loadlib 'src/PIR/Patterns.pbc'
.loadlib 'src/PIR/Optimizer.pbc'

#.HLL 'parrot'
.loadlib 'src/POST/VanillaAllocator.pbc'
.loadlib 'src/POST/Compiler.pbc'
.loadlib 'src/POST/File.pbc'
.loadlib 'src/POST/Sub.pbc'
.loadlib 'src/POST/Call.pbc'
.loadlib 'src/POST/Value.pbc'
.loadlib 'src/POST/Constant.pbc'
.loadlib 'src/POST/String.pbc'
.loadlib 'src/POST/Register.pbc'
.loadlib 'src/POST/Label.pbc'
.loadlib 'src/POST/Key.pbc'

#.HLL 'PIRATE'

.namespace []
.sub 'main' :main
    .param pmc args

    .local pmc stages
    # We actually create POST tree from Parse.
    stages = split ' ', 'parse post optimizepost pbc'
    $P0 = compreg 'PIRATE'
    $P0.'stages'(stages)
    $P0.'command_line'(args)
    exit 0
.end


#.HLL 'parrot'

.namespace ['PackfileRawSegment']
.sub 'push' :method
    .param int value
    push self, value
.end

.sub 'at' :method
    .param int key
    $I0 = self[key]
    .return ($I0)
.end

.namespace ['PackfileFixupTable']
.sub 'push' :method
    .param pmc value
    $I0 = elements self
    self[$I0] = value
.end

.namespace ['PackfileConstantTable']
.sub 'push' :method
    .param pmc value
    $I0 = elements self
    self[$I0] = value
    .return($I0)
.end

.namespace ['StringBuilder']
.sub 'push' :method
    .param string value
    push self, value
.end


.namespace ['PackfileConstantTable']
.sub 'get_or_create_string' :method
    .param string str
    $I0 = self.'get_or_create_constant'(str)
    .return ($I0)
.end

.sub 'get_or_create_number' :method
    .param num n
    $I0 = self.'get_or_create_constant'(n)
    .return ($I0)
.end

.sub 'get_or_create_pmc' :method
    .param pmc p
    $I0 = self.'get_or_create_constant'(p)
    .return ($I0)
.end


.namespace ['FixedIntegerArray']
.sub 'elements' :vtable('get_number') :method
    $I0 = self
    .return ($I0)
.end

.namespace ['Key']
.sub 'set_str' :method
    .param string s
    self = s
    .return ()
.end

.sub 'set_int' :method
    .param int i
    self = i
    .return ()
.end

.sub 'push' :method
    .param pmc p
    push self, p
    .return()
.end


# We can't use NQP for dynamically loaded stuff... It's broken somehow.
.namespace []


.sub "register_hll_lib"
    .param string lib
    register_hll_lib lib
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
