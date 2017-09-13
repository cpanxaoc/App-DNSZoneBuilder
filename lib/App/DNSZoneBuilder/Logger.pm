package App::DNSZoneBuilder::Logger;
use strict;
use warnings;
use POSIX qw(strftime);
use IO::File;
use IO::Handle;


sub new {
   my $class = shift;
   my $_config = shift;

   my $logfd;
   if ( defined $_config->get(q(logfile)) ) {
      # append to the existing logfile, if any
      $logfd = IO::File->new(q( >> ) . $_config->get(q(logfile)));
      die q( ERR: Can't open logfile ) . $_config->get(q(logfile)) . qq(: $!)
         unless ( defined $logfd );
      # apply UTF-8-ness to the filehandle
      $logfd->binmode(qq|:encoding(utf8)|);
   } else {
      # set :utf8 on STDOUT before wrapping it in IO::Handle
      binmode(STDOUT, qq|:encoding(utf8)|);
      $logfd = IO::Handle->new_from_fd(fileno(STDOUT), q(w));
      die qq( ERR: could not wrap STDOUT in IO::Handle object: $!)
         unless ( defined $logfd );
   }

   $logfd->autoflush(1);

   my $self = bless ({
      _OUTFH => $logfd,
   }, $class);

   # return this object to the caller
   return $self;
}


sub log {
   my $self = shift;
   my $msg = shift;

   my $FH = $self->{_OUTFH};
   print $FH $msg . qq(\n);
}


sub timelog {
   my $self = shift;
   my $msg = shift;
   my $timestamp = POSIX::strftime( q(%c), localtime() );

   my $FH = $self->{_OUTFH};
   print $FH $timestamp . q(: ) . $msg . qq(\n);
}


=head1 NAME

L<App::DNSZoneBuilder::Logger> - A simple logger object.

=head1 METHODS

=head2 new($_config)

Creates the L<App::DNSZoneBuilder::Logger> object, and sets up various
filehandles needed to log to files or C<STDOUT>.  Requires a
L<App::DNSZoneBuilder::Config> object as the argument, so that options having
to deal with logging can be parsed/acted upon.  Returns the logger object to
the caller.

=head2 log($message)

Log C<$message> to the logfile, or I<STDOUT> if the B<--logfile> option was
not used.

=head2 timelog($message)

Log C<$message> with a timestamp to the logfile, or I<STDOUT> if the
B<--logfile> option was not used.

=head1 AUTHOR

Brian Manning, C<< <cpan at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to...

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

   perldoc App::DNSZoneBuilder::Logger

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set sw=3 ts=3
