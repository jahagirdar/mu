use v6-alpha;

# This visitor is a plugin for the perl5 emitter.
# It emits p6-regex as p5-regex.

# XXX - It only specify "token" code

# See: temp/backtracking-recursive-subrule.pl
    
class KindaPerl6::Visitor::Emit::Perl5Regex {

    # 'Emit::Perl5' predefines all nodes, except 'Token'
    use KindaPerl6::Visitor::Emit::Perl5;

    method visit ( $node ) {
        $node.emit_perl5;
    };

}

class Token {    
    method emit_perl5 {
        my $regex_source := ($.regex).emit_perl5;
        my $source := 
          'do { ' ~ Main::newline()
            ~ 'use vars qw($_rule_' ~ $.name ~ '); ' ~ Main::newline()
            ~ 'INIT { ' ~ Main::newline()
                ~   Main::indent(
                      '$_rule_' ~ $.name ~ ' = qr' ~ chr(0)  ~ Main::newline()
                    
                    ~ '(?{ ' ~ Main::newline()
                    ~   Main::indent(
                              'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; ' ~ Main::newline() 
                            ~ '$GLOBAL::_M2 = $GLOBAL::_M; ' 
                        )
                    ~ '})' ~ Main::newline()

                    ~ $regex_source ~ Main::newline()
                    
                    ~ '(?{ ' ~ Main::newline()
                    ~   Main::indent(
                              'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; ' ~ Main::newline() 
                            ~ '$GLOBAL::_M2 = $GLOBAL::_M; '
                        )
                    ~ '})' ~ Main::newline()

                    ~ chr(0) ~ 'x; '  
                )
            ~ '}' ~ Main::newline() 

            # create the method, using the OO metamodel
            # OUTER::<$_> := string to match
            # OUTER::<$/> := match result
            ~ '::DISPATCH(::DISPATCH($::' ~ $KindaPerl6::Visitor::Emit::Perl5::current_compunit ~ ',"HOW"),'         
                ~ '"add_method", '
                ~ '::DISPATCH( $::Str, "new", "' ~ $.name ~ '" ), '

                ~ '::DISPATCH( $::Method, "new", '
                    ~ '{ code => '
                        ~ 'sub { '
                        ~    'local $GLOBAL::_Class = shift; '
                        ~    'undef $GLOBAL::_M2; '
                        ~    '( ref($_) ? ::DISPATCH( $_, "Str" )->{_value} : $_ ) =~ '
                        ~      '/$' ~ Main::mangle_perl5rx_metasyntax( $.name ) ~ '/; '
                        
                        ~    'if ( $GLOBAL::_M2->[1] eq \'to\' ) { '
                        ~        'Match::from_global_data( $GLOBAL::_M2 ); '
                        # XXX TODO - modify outer $/
                        ~        '$MATCH = $GLOBAL::MATCH = pop @Match::Matches; '
                        ~    '} '
                        ~    'else { '
                        ~        '$MATCH = $GLOBAL::MATCH = Match->new(); '
                        ~    '} '
                        
                        ~    '@Match::Matches = (); '   # discard outer matches, if any
                        ~    'return $MATCH; '
                        ~ '} '
                    # TODO Signature and AST
                    ~ '} '
                ~ '), '

            ~ '); '
          ~ '} '
          ~ Main::newline();  # /do
                        
        return $source;
    }
}

class P5Token {
    method emit_perl5 {
        # XXX this should be parsed to detect captures !!!
        $.regex
        # 'do { my $m2 = match_p5rx("' ~ $.regex ~ '",$str,($pos+0)); if ($m2) { $MATCH.to = $m2.to + 0; 1 } else { 0 } }';
    }
}

class Rule::Quantifier {
    method emit_perl5 {
        # TODO
        $.term.emit_perl5 ~ $.quant ~ $.greedy;
    }
}

class Rule::Or {
    method emit_perl5 {
          '(?:' ~ (@.or.>>emit_perl5).join('|') ~ ')';
    }
}

class Rule::Concat {
    method emit_perl5 {
        '(?:' ~ (@.concat.>>emit_perl5).join('') ~ ')';
    }
}

class Rule::Var {
    method emit_perl5 {
        # Normalize the sigil here into $
        # $x    => $x
        # @x    => $List_x
        # %x    => $Hash_x
        # &x    => $Code_x
        my $table := {
            '$' => '$',
            '@' => '$List_',
            '%' => '$Hash_',
            '&' => '$Code_',
        };
        $table{$.sigil} ~ $.name
    }
}

class Rule::Constant {
    method emit_perl5 {
        my $str := $.constant; 
        if $str eq ' ' {
            return '\\ ';
        };
        if $str eq '...' {
            return '\\.\\.\\.';
        };

        if $str eq '#' {
            return '\\#';
        };
        if $str eq '$' {
            return '\\$';
        };
        if $str eq '$<' {
            return '\\$<';
        };
        if $str eq '@' {
            return '\\@';
        };
        if $str eq '%' {
            return '\\%';
        };

        if $str eq '?' {
            return '\\?';
        };
        if $str eq '+' {
            return '\\+';
        };
        if $str eq '*' {
            return '\\*';
        };

        if $str eq '??' {
            return '\\?\\?';
        };
        if $str eq '++' {
            return '\\+\\+';
        };
        if $str eq '**' {
            return '\\*\\*';
        };

        if $str eq '(' {
            return '\\(';
        };
        if $str eq ')' {
            return '\\)';
        };
        if $str eq '[' {
            return '\\[';
        };
        if $str eq ']' {
            return '\\]';
        };
        if $str eq '{' {
            return '\\{';
        };
        if $str eq '}' {
            return '\\}';
        };

        if $str eq '/' {
            return '\\/';
        };
        if $str eq '\\' {
            return '\\\\';
        };
        if $str eq '\'' {
            return '\\\'';
        };
        $str;
    }
}

class Rule::Dot {
    method emit_perl5 {
        '(?:\n\r?|\r\n?|\X)';
    }
}

class Rule::SpecialChar {
    method emit_perl5 {
        my $char := $.char;
        #say 'CHAR ',$char;
        if $char eq 'n' {
            return '(?:\n\r?|\r\n?)';
        };
        if $char eq 'N' {
            return '(?:(?!\n\r?|\r\n?)\X)';
        };
        if $char eq '\\' {
            return '\\\\';
        };
        if $char eq '\'' {
            return '\\\'';
        };
        return '\\' ~ $char;  # ???
    }
}

class Rule::Block {
    method emit_perl5 {
        '(?{ ' ~ Main::newline()
            ~ Main::indent(
                 'local $GLOBAL::_M = [ $GLOBAL::_M, "to", pos() ]; ' ~ Main::newline()  # "finish" & shallow copy

            # construct a $/ view from what we already have
            ~    'Match::from_global_data( $GLOBAL::_M ); ' ~ Main::newline()
            ~    '$MATCH = '   # ???                    
            ~    '$GLOBAL::MATCH = pop @Match::Matches; ' ~ Main::newline()
            ~    '@Match::Matches = (); ' ~ Main::newline()  # discard outer matches, if any
            # ~ ' use Data::Dumper; print "Rule::Block current match: ",Dumper($MATCH),"\n"; '

            ~    $.closure.emit_perl5 ~ '; '
            
            ~    'if ( ::DISPATCH( $GLOBAL::Code_defined, "APPLY", $GLOBAL::_REGEX_RETURN_ )->{_value} ) { '
                 ~   '$GLOBAL::_M = [ [ @$GLOBAL::_M ], "result", ::DISPATCH( $GLOBAL::_REGEX_RETURN_, "FETCH" ) ]; '
            ~    '}'             
            ) 
        ~ ' })'
    }
}

# TODO
class Rule::InterpolateVar {
    method emit_perl5 {
        say '# TODO: interpolate var ' ~ $.var.emit_perl5 ~ '';
        die();
    };
}

class Rule::After {
    method emit_perl5 {

        # XXX - p5 "after" only works with fixed-width matches
        
        if $.assertion_modifier eq '!' {
            # XXX - create a new lexical context and discard captures ?
            return '(?<!' ~ $.rule.emit_perl5 ~ ')';
        }
        if $.assertion_modifier eq '?' {
            # XXX - create a new lexical context and discard captures ?
            return '(?<=' ~ $.rule.emit_perl5 ~ ')';
        }
    
        if $.capture_to_array {
              '(?<='
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture_to_array", "after" ]; '
                ~ '})'
            ~ ')'
        }
        else {    
              '(?<='
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture", "after" ]; '
                ~ '})'
            ~ ')'
        }
    }
}

class Rule::Before {
    method emit_perl5 {

        if $.assertion_modifier eq '!' {
            # XXX - create a new lexical context and discard captures ?
            return '(?!' ~ $.rule.emit_perl5 ~ ')';
        }
        if $.assertion_modifier eq '?' {
            # XXX - create a new lexical context and discard captures ?
            return '(?=' ~ $.rule.emit_perl5 ~ ')';
        }
    
        if $.capture_to_array {
              '(?='
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture_to_array", "before" ]; '
                ~ '})'
            ~ ')'
        }
        else {    
              '(?='
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture", "before" ]; '
                ~ '})'
            ~ ')'
        }
    }
}

class Rule::NegateCharClass {
    # unused
    method emit_perl5 {
        say "TODO NegateCharClass";
        die();
    }
}

class Rule::CharClass {
    # unused
    method emit_perl5 {
        say "TODO CharClass";
        die();
    }
}

class Rule::SubruleNoCapture {
    method emit_perl5 {
        # TODO
        #my $meth := ( 1 + index( $.metasyntax, '.' ) )
        #    ?? $.metasyntax ~ ' ... TODO '
        #    !! ( '\'$\'.$GLOBAL::_Class.\'::_rule_' ~ $.metasyntax ~ '\'' );
        
        # XXX - Temporary hack
        my $meth := '$' ~ Main::mangle_perl5rx_metasyntax( $.metasyntax );

        # XXX - param passing
        
          '(?:'
            ~ '(??{ ' ~ $meth ~ ' })'
            ~ '(?{ '
            ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "discard_capture" ]; '
            ~ '})'
        ~ ')'
    }
}

class Rule::Subrule {
    method emit_perl5 {
        # TODO
        #my $meth := ( 1 + index( $.metasyntax, '.' ) )
        #    ?? $.metasyntax ~ ' ... TODO '
        #    !! ( '\'$\'.$GLOBAL::_Class.\'::_rule_' ~ $.metasyntax ~ '\'' );
        
        # XXX - Temporary hack
        my $meth := '$' ~ Main::mangle_perl5rx_metasyntax( $.metasyntax );

        # XXX - named capture; param passing
        
        if $.capture_to_array {
              '(?:'
                ~ '(??{ ' ~ $meth ~ ' })'
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture_to_array", "' ~ $.metasyntax ~ '" ]; '
                ~ '})'
            ~ ')'
        }
        else {    
              '(?:'
                ~ '(??{ ' ~ $meth ~ ' })'
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture", "' ~ $.metasyntax ~ '" ]; '
                ~ '})'
            ~ ')'
        }
    }
}

class Rule::NamedCapture {
    method emit_perl5 {

        if $.capture_to_array {
              '(?:'
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture_to_array", "' ~ $.ident ~ '" ]; '
                ~ '})'
            ~ ')'
        }
        else {    
              '(?:'
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "named_capture", "' ~ $.ident ~ '" ]; '
                ~ '})'
            ~ ')'
        }
    }
}

class Rule::Capture {
    method emit_perl5 {
    
        if $.capture_to_array {
              '(?:'
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "positional_capture_to_array", ' ~ $.position ~ ' ]; '
                ~ '})'
            ~ ')'
        }
        else {    
              '(?:'
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'create\', pos(), \\$_ ]; '
                ~ '})'
                ~ $.rule.emit_perl5 
                ~ '(?{ '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, \'to\', pos() ]; '
                ~   'local $GLOBAL::_M = [ $GLOBAL::_M, "positional_capture", ' ~ $.position ~ ' ]; '
                ~ '})'
            ~ ')'
        }
    }
}

=begin

=head1 NAME 

KindaPerl6::Visitor::Token - AST processor for P6-Regex to P5-Regex transformation

=head1 SYNOPSIS

    my $visitor_token := KindaPerl6::Visitor::Emit::Perl5Regex.new();
    $ast = $ast.emit( $visitor_token );

=head1 DESCRIPTION

This module transforms regex AST into plain-perl5-regex code.

=head1 AUTHORS

The Pugs Team E<lt>perl6-compiler@perl.orgE<gt>.

=head1 SEE ALSO

The Perl 6 homepage at L<http://dev.perl.org/perl6>.

The Pugs homepage at L<http://pugscode.org/>.

=head1 COPYRIGHT

Copyright 2007 by Flavio Soibelmann Glock and others.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=end
