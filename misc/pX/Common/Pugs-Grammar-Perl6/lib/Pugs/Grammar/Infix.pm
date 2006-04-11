﻿package Pugs::Grammar::Infix;
use strict;
use warnings;
#use base qw(Pugs::Grammar::Operator);
use Pugs::Grammar::Operator;
use base qw(Pugs::Grammar::BaseCategory);

sub add_rule {
    # print "add infix operator\n";
    my $self = shift;
    my %opt = @_;
    print "Infix add: @{[ %opt ]} \n";

    Pugs::Grammar::Operator::add_rule( $self, %opt,
        fixity => 'infix', 
    );
    Pugs::Grammar::Operator::add_rule( $self, %opt,
        fixity => 'infix', 
        name => 'infix:<' . $opt{name} . '>',
    );
    $self->SUPER::add_rule( 
        $opt{name}, 
        '{ return { op => "' . $opt{name} . '" ,} }' );
    $self->SUPER::add_rule( 
        "infix:<' . $opt{name} . '>",
        '{ return { op => "infix:<' . $opt{name} . '>" ,} }' );
}

BEGIN {
    __PACKAGE__->add_rule( 
        name => '+',
        assoc => 'left',
    );
    __PACKAGE__->add_rule( 
        name => '-',
        assoc => 'left',
        precedence => 'equal',
        other => '+',
    );
    __PACKAGE__->add_rule( 
        name => '*',
        assoc => 'left',
        precedence => 'tighter',
        other => '+',
    );
    __PACKAGE__->add_rule( 
        name => '/',
        assoc => 'left',
        precedence => 'equal',
        other => '*',
    );
    __PACKAGE__->recompile;
}

1;
