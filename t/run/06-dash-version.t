use v6;

use Test;

=begin pod

Test that the C<--version> command in its various incantations
works.

=end pod

my @tests = any(< -v --version >);
@tests = map -> Junction $_ { $_.eigenstates },
         map -> Junction $_ { $_, "-w $_", "$_ -w", "-w $_ -w" },
         @tests;

plan +@tests;
if $*OS eq "browser" {
  skip_rest "Programs running in browsers don't have access to regular IO.";
  exit;
}

diag "Running under $*OS";

my $redir = ">";

sub nonce () { return (".{$*PID}." ~ (1..1000).pick) }

for @tests -> $ex {
  my $out_fn = "temp-ex-output" ~ nonce;
  my $command = "$*EXECUTABLE_NAME $ex $redir $out_fn";
  diag $command;
  run $command;

  my $got = slurp $out_fn;
  unlink $out_fn;

  like($got, rx:Perl5/Version:.6\.\d+\.\d+/, "'$ex' displays version");
};
