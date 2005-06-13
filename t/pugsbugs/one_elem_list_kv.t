#!/usr/bin/pugs

use v6;
use Test;

plan(5);

# once it works, just remove the previous 2 lines, set plan to 4 and uncomment the code bits below:

# (1,).kv works correctly
my @a = ();
@a = (1,).kv; # commented out - hangs forever
is(@a[0],0, "first element is 0");
is(@a[1],1, "second element is 1");

# ('a',).kv works correctly
@a = ('a',).kv; # commented out - hangs forever
is(@a[0],0, "first element is 0");
is(@a[1],'a', "second element is 'a'");

# Check that (42).kv does *not* work, as this it the same as $some_int.kv:
dies_ok { (42).kv }, "(42).kv should not and does not work";
