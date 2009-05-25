#!/usr/bin/pugs
=begin pod

=head1 NAME

Sys::Statistics::Linux::FileStats - Collect linux file statistics.

=head1 SYNOPSIS

   use Sys::Statistics::Linux::FileStats;

   my $lxs   = Sys::Statistics::Linux::FileStats.new;
   my %stats = $lxs.get;

=head1 DESCRIPTION

Sys::Statistics::Linux::FileStats gathers file statistics from the virtual F</proc> filesystem (procfs).

For more informations read the documentation of the front-end module L<Sys::Statistics::Linux>.

=head1 FILE STATISTICS

Generated by F</proc/sys/fs/file-nr>, F</proc/sys/fs/inode-nr> and F</proc/sys/fs/dentry-state>.

   fhalloc    -  Number of allocated file handles.
   fhfree     -  Number of free file handles.
   fhmax      -  Number of maximum file handles.
   inalloc    -  Number of allocated inodes.
   infree     -  Number of free inodes.
   inmax      -  Number of maximum inodes.
   dentries   -  Dirty directory cache entries.
   unused     -  Free diretory cache size.
   agelimit   -  Time in seconds the dirty cache entries can be reclaimed.
   wantpages  -  Pages that are requested by the system when memory is short.

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

   my $lxs = Sys::Statistics::Linux::FileStats.new;

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash.

   my %stats = $lxs.get;

=head1 EXAMPLES

    my $lxs = Sys::Statistics::Linux::FileStats.new;
    my $header = 0;

    loop {
        sleep(1);
        my %stats = $lxs.get;
        my $time  = localtime();

        if $header == 0 {
            $header = 20;
            print  ' ' x 20;
            printf "%12s%12s%12s%12s%12s%12s%12s%12s%12s%12s\n", <fhalloc fhfree fhmax inalloc infree inmax dentries unused agelimit wantpages>;
        }

        printf "%04d-%02d-%02d %02d:%02d:%02d %12s%12s%12s%12s%12s%12s%12s%12s%12s%12s\n",
               $time.<year month day hour min sec>,
               %stats<fhalloc fhfree fhmax inalloc infree inmax dentries unused agelimit wantpages>;

        $header--;
    }

=head1 EXPORTS

No exports.

=head1 SEE ALSO

B<proc(5)>

=head1 REPORTING BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (c) 2006, 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=end pod

#package Sys::Statistics::Linux::FileStats;
#our $VERSION = '0.04';

class Sys::Statistics::Linux::FileStats-0.001;

use v6;

#use strict;
#use warnings;
#use Carp qw(croak);

sub croak (*@m) { die @m } # waiting for Carp::croak

#sub new {
#   my $class = shift;
#   my %self = (
#      files => {
#         file_nr    => '/proc/sys/fs/file-nr',
#         inode_nr   => '/proc/sys/fs/inode-nr',
#         dentries   => '/proc/sys/fs/dentry-state',
#      }
#   );
#   return bless \%self, $class;
#}

has %.files;

submethod BUILD () {
    $.files<file_nr>  = '/proc/sys/fs/file-nr';
    $.files<inode_nr> = '/proc/sys/fs/inode-nr';
    $.files<dentries> = '/proc/sys/fs/dentry-state';
}

#sub get {
#   my $self  = shift;
#   my $class = ref $self;
#   my $file  = $self->{files};
#   my %stats = ();
#
#   {
#      open my $fh, '<', $file->{file_nr} or croak "$class: unable to open $file->{file_nr} ($!)";
#      @stats{qw(fhalloc fhfree fhmax)} = (split /\s+/, <$fh>)[0..2];
#      close($fh);
#   }
#
#   {
#      open my $fh, '<', $file->{inode_nr} or croak "$class: unable to open $file->{inode_nr} ($!)";
#      @stats{qw(inalloc infree)} = (split /\s+/, <$fh>)[0..1];
#      $stats{inmax} = $stats{inalloc} + $stats{infree};
#      close($fh);
#   }
#
#   {
#      open my $fh, '<', $file->{dentries} or croak "$class: unable to open $file->{dentries} ($!)";
#      @stats{qw(dentries unused agelimit wantpages)} = (split /\s+/, <$fh>)[0..3];
#      close($fh);
#   }
#
#   return \%stats;
#}

method get () {
    my $file_nr  = self.files<file_nr>;
    my $inode_nr = self.files<inode_nr>;
    my $dentries = self.files<dentries>;
    my (%stats, $line);

#    my $filfh = open($file_nr, :r) or croak("unable to open $file_nr: $!");
#    %stats<fhalloc fhfree fhmax> = ($filfh.readline.comb)[0..2];
#    $filfh.close;

    for =$file_nr -> $line {
        %stats<fhalloc fhfree fhmax> = ($line.comb)[0..2];
    }

#    my $inofh = open($inode_nr, :r) or croak("unable to open $inode_nr: $!");
#    %stats<inalloc infree> = ($inofh.readline.comb)[0..1];
#    $inofh.close;

    for =$inode_nr -> $line {
        %stats<inalloc infree> = ($line.comb)[0..1];
    }
    %stats<inmax> = %stats<inalloc> + %stats<infree>;

#    my $denfh = open($dentries, :r) or croak("unable to open $dentries: $!");
#    %stats<dentries unused agelimit wantpages> = ($denfh.readline.comb)[0..3];
#    $denfh.close;

    for =$dentries -> $line {
        %stats<dentries unused agelimit wantpages> = ($line.comb)[0..3];
    }

    return %stats;
}
