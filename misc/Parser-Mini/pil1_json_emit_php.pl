=pod

PIL2-JSON simple Perl 6 code emitter
by fglock

  ../../pugs -CPIL2-JSON -e ' say "hello" ' | \
    ../../pugs pil2_json_emit_p6.pl

  use v6-alpha;
  &*END () {  }
  (&say("hello"));

Other examples:

  ../../pugs -Cpil2-json -e ' my Int $x; ($x~"a")( "a",1,$x,$x+1); { say 1 } ' | \
    ../../pugs pil2_json_emit_p6.pl

The code created by this example has syntax errors, but I'm not sure if these things are
really forbidden in p6:

  ../../pugs -Cpil2-json -e 'my ($x,$y)=(1,2); sub infix:<aaa>($a,$b){$a+1} 1 aaa 2;' | \
    ../../pugs pil2_json_emit_p6.pl

=cut

use v6-alpha;

# -- Language specific

sub emit_Main ( $global, $main ) {
    "<?php\n" ~
    $global ~ $main ~
    "?>\n"
}
sub emit_Stmt ( $s ) { $s ~ ";\n" }
sub emit_Code ( $body, $is_multi, $lvalue, @params, $type ) {
    '{ ' ~ $body ~ ' }'
}	
sub emit_Assign( $to, $from ) { $to ~ ' = ' ~ $from }
sub emit_Bind( $to, $from )   { $to ~ ' := ' ~ $from }
sub emit_Sub ( $name, $body, $is_multi, $lvalue, @params, $type ) {
    if @params.elems > 1 {
        for 0 .. @params.elems-2 -> $i {
            # if there are many invocants, separate them with ',' instead of ':'
            if @params[$i+1] ~~ m:perl5 {:$} {
                @params[$i] ~~ s:perl5 {:$}{,};
            }
        }
    }
    my $param_list = @params.join(" ");
    $param_list ~~ s:perl5 {,$}{};  # remove last ','
    "function $name (" ~ $param_list ~ ") {\n" ~ $body ~ "\n\}\n"
}	
sub emit_App ( $function is rw, @args, $context, $invocant ) {   
    if $function eq '&print' { return "echo @args.join(', ')" }
    if $function eq '&say'   { return "echo @args.join(', '),\"\\n\"" }
    if $function ~~ m:perl5 {^&infix:(.*)} { return "(" ~  @args.join( $0 ) ~ ")" }
    $function ~ "(" ~  @args.join(", ") ~ ")" 
}
sub emit_Pad ( $scope, @symbols, $statements ) {
    "\{\n" ~ @symbols.map:{ "my " ~ emit_Variable($_) ~ ";\n" } ~ "$statements\n\}\n";
}
sub emit_Variable ( $s is copy ) {
    $s ~~ s:perl5 /^"(.*)"$/$0/;
    $s
}
sub emit_Int ( $s ) { $s }
sub emit_Str ( $s ) { $s }
sub emit_Rat ( $a, $b ) { "($a / $b)" }
sub emit_parameter( 
    $name, $is_invocant, $is_lvalue, $is_lazy, $is_named,
    $is_optional, $is_writable, $context, $default )
{
    #say "(param=$name, $is_invocant, $is_lvalue, $is_lazy, $is_named, ",
    #    "$is_optional, $is_writable, <", $context.perl, ">, <$default>)";
        
    # ??? - "paramDefault" 
    # ??? - what is the syntax for $is_lvalue 
    # ??? - what is the PIL for 'is copy' 

    # $context = [["CxtSlurpy", [[["MkType", ["Int"] ]]] ]]
    my $is_slurpy = $context[0][0] eq '"CxtSlurpy"';
    my $type = emit_Variable( $context[0][1][0][0][1] );
    
    my $s;
    $s ~= $type eq 'main' ?? '' !! ($type ~ ' ');
    $s ~= $is_slurpy ?? '*' !! '';

    $s ~= $is_named    eq 'true'        ?? ':' !! ''; 
    $s ~= emit_Variable( $name );
    $s ~= $is_optional eq 'true'        ?? '?' !! '';   # '!' is default
    $s ~= ' is rw '   if $is_writable eq 'true';
    $s ~= ' is lazy ' if $is_lazy     eq 'true';
    $s ~= $is_invocant eq 'true'        ?? ':' !! ',';   
    return $s; 
}
sub emit_parameter_with_default( $param, $default ) {
    return $param if $default eq '';
    # rewrite '$name,' to '$name = default,'
    my ($name, $separator) = $param ~~ m:perl5 {(.*)(.)};
    $name ~ ' = ' ~ $default ~ $separator
}

# -- Main program
# this is the same for all languages

push @*INC, "./";
require 'pil2_json_emit.pm';

# slurp stdin - xinming++ 
my $pil2 = ** $*IN.slurp;

my @b = tokenize( $pil2 );
# say "Tokens: ", @b.join('><');

my $ast = parse( << { >>, 'hash', << } >>, @b );
# say $ast.perl;

my $program = traverse_ast( $ast );
say $program;

