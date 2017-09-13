###############################
# App::DNSZoneBuilder::Config #
###############################
package App::DNSZoneBuilder::Config;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use POSIX qw(strftime);

my @_valid_script_args = ( qw(verbose config) );

sub new {
   my $class = shift;
   my $self = bless ({}, $class);

   # script arguments
   my %args;

   # parse the command line arguments (if any)
   my $parser = Getopt::Long::Parser->new();

   # pass in a reference to the args hash as the first argument
   $parser->getoptions(
      \%args,
      # script options
      q(verbose|v+),
      q(help|h),
      q(config|c=s),
      q(continue),
      q(generate|g),
      # FIXME make this work
      # run the testing harness scripts by do'ing or require'ing them
      # q(test|t),
   ); # $parser->getoptions

   # assign the args hash to this object so it can be reused later on
   $self->{_args} = \%args;

   # a check to verify the shout module is available
   # it's put here so some warning is given if --help was called

   # dump and bail if we get called with --help
   if ( $self->get(q(help)) ) { pod2usage(-exitstatus => 1); }

   # generate a config file and exit?
   if ( defined $self->get(q(generate)) ) {
      # this method exits the script after outputting the config
      $self->_print_default_config();
   } # if ( defined $self->get(q(generate)) )

   # read a config file if that's specified
   if ( ! defined $self->get(q(config)) ) {
      die qq| ERR: missing config file argument (--config)|;
   } # if ( ! defined $self->get(q(config)) )
   if ( ! -r $self->get(q(config)) ) {
      die q( ERR: config file ') . $self->get(q(config)) . q( not readable);
   } # if ( ! -r $self->get(q(config)) )

   # return this object to the caller
   return $self;
}


# set defaults here for any missing arugments
sub _apply_defaults {
   my $self = shift;
   # icecast defaults
   $self->set( user => q(source) )
     unless ( defined $self->get(q(user)) );
   $self->set( password => q(default) )
     unless ( defined $self->get(q(password)) );
}


sub _print_default_config {
   my $self = shift;

   # apply the default configuration options to the Config object
   $self->_apply_defaults();
   # now print out the sample config file
   print qq(# sample template config file\n);
   print qq(# any line that starts with '#' is a comment\n);
   print qq(# sample config generated on )
      . POSIX::strftime( q(%c), localtime() ) . qq(\n);
   #foreach my $arg ( @_valid_script_args ) {
   #   print $arg . q( = ) . $self->get($arg) . qq(\n);
   #} # foreach my $arg ( @_valid_shout_args )
   # cheat a bit and add these last config settings
   # here document syntax
   print <<EOC;
# more config file parameters here
key1 = value1
# commenting the logfile will log to STDOUT instead
logfile = /path/to/output.log
EOC
   exit 0;
}


sub get {
   my $self = shift;
   my $key = shift;
   # turn the args reference back into a hash with a copy
   my %args = %{$self->{_args}};

   if ( exists $args{$key} ) { return $args{$key}; }
   return undef;
}


sub set {
   my $self = shift;
   my $key = shift;
   my $value = shift;
   # turn the args reference back into a hash with a copy
   my %args = %{$self->{_args}};

   if ( exists $args{$key} ) {
      my $oldvalue = $args{$key};
      $args{$key} = $value;
      $self->{_args} = \%args;
      return $oldvalue;
   } else {
      $args{$key} = $value;
      $self->{_args} = \%args;
   } # if ( exists $args{$key} )
   return undef;
}


sub get_args {
   my $self = shift;
   # hash-ify the return arguments
   return %{$self->{_args}};
} # get_args


=head1 App::DNSZoneBuilder::Config

An object used for storing configuration data.

=head2 METHODS

=head3 new( )

Creates the L<App::DNSZoneBuilder::Config> object, and parses out options using
L<Getopt::Long>.

=head3 get($key)

Returns the scalar value of the key passed in as C<key>, or C<undef> if the
key does not exist in the L<App::DNSZoneBuilder::Config> object.

=head3 set( key => $value )

Sets in the L<App::DNSZoneBuilder::Config> object the key/value pair passed in
as arguments.  Returns the old value if the key already existed in the
L<App::DNSZoneBuilder::Config> object, or C<undef> otherwise.

=head3 get_args( )

Returns a hash containing the parsed script arguments.

=head1 AUTHOR

Brian Manning <cpan at xaoc dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2017 by Brian Manning

=cut

# fin!
# vim: set sw=3 ts=3
