INIT {
    pir::load_bytecode('POST/Pattern.pbc');
}

class POST::Pattern::Call is POST::Pattern {
    my @attributes := pir::clone__PP(POST::Pattern.attributes());
    for (<name params results invocant calltype>) {
        pir::push(@attributes, $_);
    }
    method attributes () { @attributes; }

    method target_class () { POST::Call; }
}

class POST::Pattern::File is POST::Pattern {
    my @attributes := pir::clone__PP(POST::Pattern.attributes());
    pir::push(@attributes, 'subs');
    method attributes() { @attributes; }

    method target_class () { POST::File; }
}

class POST::Pattern::Value is POST::Pattern {
    my @attributes := pir::clone__PP(POST::Pattern.attributes());
    for (<name type flags declared>) {
        pir::push(@attributes, $_);
    }
    method attributes () { @attributes; }

    method target_class () { POST::Value; }
}

class POST::Pattern::Constant is POST::Pattern::Value {
    my @attributes := pir::clone__PP(POST::Pattern::Value.attributes());
    pir::push(@attributes, 'value');
    method attributes () { @attributes; }
    method target_class () { POST::Constant; }
}

class POST::Pattern::Key is POST::Pattern::Value {
    my @attributes := pir::clone__PP(POST::Pattern::Value.attributes());
    method attributes () { @attributes; }
    method target_class () { POST::Key; }
}

class POST::Pattern::Register is POST::Pattern::Value {
    my @attributes := pir::clone__PP(POST::Pattern::Value.attributes());
    pir::push(@attributes, 'regno');
    pir::push(@attributes, 'modifier');
    method attributes () { @attributes; }
    method target_class () { POST::Register; }
}
