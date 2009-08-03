# Copyright (C) 2007-2008, Parrot Foundation.
# $Id$

class PIR::Grammar::Actions;

our $?SUB;

method TOP($/) {
    make $<program>.ast;
}

method program($/) {
    my $program := PAST::Block.new( :blocktype('declaration'), :node($/) );
    for $<compilation_unit> {
        $program.push( $_.ast );
    }
    make $program;
}

method compilation_unit($/, $key) {
    make $/{$key}.ast;
}

method sub_def($/, $key) {
    our $?SUB;
    if ($key eq 'open') {
        $?SUB := PAST::Block.new( :blocktype('declaration'), :node($/) );
        my $subname := $<sub_id>.ast;
        $?SUB.name($subname.name());

        if $<param_decl> {
            for $<param_decl> {
                $?SUB.push( $_.ast );
            }
        }
    }
    else {
        if $<labeled_pir_instr> {
            my $stmts := PAST::Stmts.new( :node($/) );
            for $<labeled_pir_instr> {
                $stmts.push( $_.ast );
            }
            $?SUB.push($stmts);
        }
        make $?SUB;
    }
}

method labeled_pir_instr($/) {
    my $instr;

    if $<instr> {
        $instr := $<instr>.ast;
    }

    if $<label> {
        my $pir := ~$<label>;
        my $label := PAST::Op.new( :inline($pir), :node($/) );
        if $<instr> {
            $instr := PAST::Stmts.new( $label, $instr, :node($/) );
        }
    }
    make $instr;
}

method instr($/, $key) {
    make $/{$key}.ast;
}

method pir_instr($/, $key) {
    make $/{$key}.ast;
}

method local_decl($/) {
    my $stmts := PAST::Stmts.new( :node($/) );
    my $type := ~$<pir_type>;

    for $<local_id> {
        my $local := $_.ast;
        my $var := PAST::Var.new(
                :node($local),
                :name($local.name),
                :returns($type),
                :scope('lexical'),
                :isdecl(1)
            );
        $?SUB.symbol($var.name, :scope('lexical'));
        $stmts.push($var);
        #my $pir := '.local ' ~ $type ~ ' ' ~ $local.name();
        #$stmts.push( PAST::Op.new( :inline($pir), :node($/) ) );
    }
    make $stmts;
}

method local_id($/) {
    my $past := $<id>.ast;
    if $<unique> {
        ## does this work?
        #$past.pirflags(':unique_reg');
    }
    make $past;
}

method sub_id($/, $key) {
    make $/{$key}.ast;
}

method param_decl($/) {
    my $param := $<parameter>.ast;
    make $param;
}

method parameter($/) {
    my $parameter := $<id>.ast;
    # is the type usable at this point (where PCT only supports P registers?)
    my $type := ~$<pir_type>;
    #$parameter.type($type);
    $parameter.scope('parameter');
    make $parameter;
}

method pir_type($/) {
    make PAST::Val.new( :type('string'), :value(~$<type>), :node($/) );
}

method assignment_stat($/, $key) {
    make $/{$key}.ast;
}

method simple_assignment($/) {
    my $lhs := $<target>.ast;
    my $rhs := $<rhs>.ast;
    make PAST::Op.new( $lhs, $rhs, :pasttype('bind'), :node($/) );
}

method rhs($/, $key) {
    make $/{$key}.ast;
}

method expression($/, $key) {
    make $/{$key}.ast;
}

method simple_expr($/, $key) {
    make $/{$key}.ast;
}

method unary_expr($/) {
     make $<simple_expr>.ast;
}

method binary_expr($/) {
    make $<simple_expr>[0].ast;
}

method constant($/, $key) {
    make $/{$key}.ast;
}

method target($/) {
    make $<normal_target>.ast;
}

method normal_target($/, $key) {
    if ($key eq 'id') {
        my $var := $<id>.ast;
        unless $?SUB.symbol($var.name) {
            $/.panic('Undeclared variable: ' ~$var.name);
        }
        make $var;
    }
    else {
        make $/{$key}.ast;
    }
}

method key($/) {
    make $<simple_expr>.ast;
}

method int_constant($/) {
    make PAST::Val.new( :value(~$/), :returns('Integer'), :node($/) );
}

method string_constant($/) {
    make PAST::Val.new( :value(~$/), :returns('String'), :node($/) );
}

method float_constant($/) {
    make PAST::Val.new( :value(~$/), :returns('Float'), :node($/) );
}

method id($/) {
    make PAST::Var.new( :name(~$/), :scope('lexical'), :node($/) );
}

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

