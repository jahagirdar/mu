# for extracting data from the YAPC::NA 2006 schedule
# wget -O monday http://yapcchicago.org/the-schedule/monday
# pugs yapc_schedule.pl monday

grammar yapc_schedule {
    rule schedule { <title> [ <talk> ]+ }

    token title { '<title>' .+? '</title>' }

    regex ws { .*? }

    token talk { '<small>' <speaker> '</small>' }

    token speaker { [\w|\s|\,]+ }
}

### extract.pl
use v6;

my $content = slurp @*ARGS[0];

my $match = $content ~~ m/<yapc_schedule::schedule>/;

say $match.perl;

