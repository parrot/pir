INIT {
    pir::load_bytecode('Tree/Optimizer.pbc');
}

module PIR::Compiler {
    method optimizepost ($post) {
        my $opt := Tree::Optimizer.new;
        $opt.register(PIR::Optimizer::eliminate_constant_conditional);
        $opt.register(PIR::Optimizer::fold_arithmetic);
        $opt.register(PIR::Optimizer::swap_gtge);
        $opt.run($post);
    }
}

module PIR::Optimizer;

sub hash (*%result) { %result; }

our sub eliminate_constant_conditional ($post) {
    my $conditional_ops :=
        / [ eq | ne | lt | le | gt | ge ] /;
    my $nonpmc := / ic | nc | sc /;
    my $pattern :=
       POST::Pattern::Op.new(:pirop($conditional_ops),
                             POST::Pattern::Constant.new(:type($nonpmc)),
                             POST::Pattern::Constant.new(:type($nonpmc)),
                             POST::Pattern::Label.new);
    my %op_funcs := hash(:eq(sub ($l, $r) { pir::iseq__IPP($l, $r) }),
                         :ne(sub ($l, $r) { pir::isne__IPP($l, $r) }),
                         :lt(sub ($l, $r) { pir::islt__IPP($l, $r) }),
                         :le(sub ($l, $r) { pir::isle__IPP($l, $r) }),
                         :gt(sub ($l, $r) { pir::isgt__IPP($l, $r) }),
                         :ge(sub ($l, $r) { pir::isge__IPP($l, $r) }));
    my &eliminate := sub ($/) {
       my $condition := %op_funcs{$<pirop>.orig}($/[0].orig.value,
                                                 $/[1].orig.value);
       if $condition {
           return POST::Op.new(:pirop<branch>, $/[2].orig);
       }
       else {
           return POST::Op.new(:pirop<noop>);
       }
       $/.orig;
    };

    $pattern.transform($post, &eliminate);
}

our sub fold_arithmetic($post) {
    my $foldable_binary := / add | sub | mul | div | fdiv | mod /;
    my $non_pmc := / ic | nc /;
    my $binary_pattern :=
        POST::Pattern::Op.new(:pirop($foldable_binary),
                              POST::Pattern::Value.new,
                              POST::Pattern::Constant.new(:type($non_pmc)),
                              POST::Pattern::Constant.new(:type($non_pmc)));
    my %binary_funcs := 
        hash(:add(sub ($l, $r, $result_type) {
                    pir::add__PPP($l, $r);
                  }),
             :sub(sub ($l, $r, $result_type) {
                    pir::sub__PPP($l, $r);
                  }),
             :mul(sub ($l, $r, $result_type) {
                    pir::mul__PPP($l, $r);
                  }),
             :div(sub ($l, $r, $result_type) {
                    $result_type eq 'nc' ??
                    pir::div__NNN($l, $r) !!
                    pir::div__III($l, $r);
                  }),
             :fdiv(sub ($l, $r, $result_type) {
                    $result_type eq 'ic' ??
                    pir::fdiv__III($l, $r) !!
                    pir::fdiv__NNN($l, $r);
                  }),
             :mod(sub ($l, $r, $result_type) {
                    pir::mod__NNN($l, $r);
                  }));
    my &binary_fold := sub ($/) {
        my $op := $/.orig.pirop;
        my $result_type := 
            ($/[1].orig.type eq 'nc' || $/[2].orig.type eq 'nc'
             ?? 'nc'
             !! 'ic');
        my $val := %binary_funcs{$op}($/[1].orig.value,
                                      $/[2].orig.value,
                                      $result_type);
        POST::Op.new(:pirop<set>,
                     $/[0].orig,
                     POST::Constant.new(:value($val),
                                        :type($result_type)));
    };

    $post := $binary_pattern.transform($post, &binary_fold);

    my $foldable_unary := / abs | neg | sqrt | ceil | floor /;
    my $unary_pattern :=
        POST::Pattern::Op.new(:pirop($foldable_unary),
                              POST::Pattern::Value.new,
                              POST::Pattern::Constant.new(:type($non_pmc)));

    my %unary_funcs :=
        hash(:abs(sub ($n) {
                      pir::abs__NN($n);
                 }),
             :neg(sub ($n) {
                      pir::abs__NN($n);
                 }),
             :sqrt(sub ($n) {
                      pir::sqrt__NN($n);
                  }),
             :ceil(sub ($n) {
                      pir::ceil__NN($n);
                  }),
             :floor(sub ($n) {
                      pir::floor__NN($n);
                   }));

    my &unary_fold := sub ($/) {
       my $op := $/.orig.pirop;
       return $/.orig if $op eq 'sqrt' && $/[1].orig.type eq 'ic';

       my $val := %unary_funcs{$/.orig.pirop}($/[1].orig.value);
       POST::Op.new(:pirop<set>,
                    $/[0].orig,
                    POST::Constant.new(:type($/[1].orig.type),
                                       :value($val)));
    };

    $unary_pattern.transform($post, &unary_fold);
}

# Swapping "gt" and "ge" with "lt" and "le"
# There is no gt_i_i_ic, so we have to swap it with lt
our sub swap_gtge($post) {
    my $gtge    := /^[ gt | ge ]$/;
    my $non_pmc := /^[ i | ic | n | nc | s | sc ]$/;
    my $pattern := POST::Pattern::Op.new(
                        :pirop($gtge),
                        POST::Pattern::Value.new(:type($non_pmc)),
                        POST::Pattern.new(),
                        POST::Pattern.new()
                   );

    my &swap := sub ($/) {
        my $op     := $/.orig.pirop;
        #pir::say("GOT $op");
        my $new_op := $op eq 'gt' ?? 'lt' !! 'le';
        POST::Op.new(:pirop($new_op),
            $/[1].orig,
            $/[0].orig,
            $/[2].orig,
        );
    };

    $post := $pattern.transform($post, &swap);

}
