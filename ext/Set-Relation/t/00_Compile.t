use v6;

use Test;

plan( 2 );

use Set::Relation; pass "(dummy instead of broken use_ok)";
skip( 1, q{is( Set::Relation.WHO.version, 0.0.2,
    'Set::Relation is the correct version' );} );
