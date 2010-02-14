class AST::Seq extends AST::Base {
    has 'stmts' => (is=>'ro');
    has 'id' => (is=>'ro');
    has 'next' => (is=>'rw');
    method pretty {
        '{' . (defined($self->id) ? $self->id . ": " : '')
        . join("",map {AST::terminate_stmt $_->pretty} @{$self->stmts}) . '}';
    }
    method m0ld($ret) {
        my @stmts = @{$self->stmts};
        my $last = pop @stmts;
        my $m0ld = join('',map {$_->m0ld(AST::unique_id)} @stmts);
        $m0ld = $m0ld . $last->m0ld($ret) if $last;
        (defined($self->id) ? $self->id . ": " : '') . $m0ld ;
    }
    method simplified {
        die "can't call simplified on a block with id" if $self->id;
        my @stmts;
        my $value;
        for (@{$self->stmts}) {
            my @side_effects;
            ($value,@side_effects) = $_->simplified;
            push (@stmts,@side_effects);
        }
        ($value,@stmts);
    }
    method jumps {
        my $last = $self->stmts->[-1];
        if (defined $last && $last->isa('AST::Goto')) {
            $self->stmts->[-1]->block;
        } elsif (defined $last && $last->isa('AST::Branch')) {
            ($last->else,$last->then),;
        } elsif ($self->next) {
            $self->next;
        } else {
            ();
        }
    }
}
