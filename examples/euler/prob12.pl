#!/usr/bin/env pugs

# vim: filetype=perl6

=begin Problem
The sequence of triangle numbers is generated by adding the natural
numbers. So the 7th triangle number would be 1 + 2 + 3 + 4 + 5 + 6 + 7 =
28. The first ten terms would be:

1, 3, 6, 10, 15, 21, 28, 36, 45, 55, ...

Let us list the factors of the first seven triangle numbers:

1: 1
3: 1,3
6: 1,2,3,6
10: 1,2,5,10
15: 1,3,5,15
21: 1,3,7,21
28: 1,2,4,7,14,28

We can see that the 7th triangle number,
28, is the first triangle number to have
over five divisors.

Which is the first triangle number to
have over five-hundred divisors?
=end Problem

use v6;
use Benchmark <timeit>;

sub divisors($n) {
    my %divisors;

    for 1..sqrt($n) -> $i {
        if $n % $i == 0 {
            %divisors{$i} = 0;
            %divisors{$n / $i} = 0;
        }
    }

    +%divisors.keys;
}

sub main {
    my $triangle = 0;

    for 1..* -> $i {
        $triangle += $i;
        if +divisors($triangle) > 500 {
            say $triangle;
            last;
        }
    }
}

my @t = timeit(1, &main);
say "execution time: @t[0]";
