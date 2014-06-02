#!/usr/bin/perl -w

# Copyright (c) 2010 by Brian Manning <elspicyjack at gmail dot com>

=head1 NAME

B<dnsgentool.pl> - Generate a set of DNS zone files based on a configuration
file written in INI format.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# verify the modules needed for this script are available
BEGIN {
    # hash format; module_name => module_options, or undef for no options
    my %modules_to_check = (
        #q(Log::Log4perl)    => q(get_logger :levels),
        q(POSIX)            => qw(strftime),
        q(IO::File)         => undef,
        q(IO::Handle)       => undef,
        q(Config::IniFiles) => undef,
        q(Getopt::Long)     => undef,
        q(Pod::Usage)       => undef,
    ); # my %modules_to_check

    my @missing_modules;
    foreach ( keys(%modules_to_check) ) {
        if ( defined $modules_to_check{$_} ) {
            eval "use $_ qw(" . $modules_to_check{$_} . ");";
        } else {
            eval "use $_";
        } # if ( defined $modules_to_check{$_} )
        # push the missing module onto a stack so the missing modules can all
        # be printed out at once
        if ( $@ ) { push(@missing_modules, $_); }
    } # foreach ( keys(%modules_to_check) )
    if ( scalar(@missing_modules) > 0 ) {
        warn qq( ERR: The following modules are missing or failed to load:\n);
        foreach my $missing_mod ( @missing_modules ) {
            warn qq(\t$missing_mod\n);
        } # foreach my $missing_mod ( @missing_modules )
        die qq(Please install/build the above modules,)
            . qq(then rerun this script.\n);
    } # if ( scalar(@missing_modules) > 0 )
} # BEGIN

=head1 SYNOPSIS

 perl dnsgentool.pl [OPTIONS]

 Script options:
 -v|--verbose       Verbose script execution
 -h|--help          Shows this help text
 -c|--config        Configuration file to use for script options
 -g|--generate      Generate a sample .ini config file to modify
 --continue         Continue parsing files even if an error is encountered

 Example usage:

 # Generate a config file to modify that contains the script defaults
 dnsgentool.pl --generate

 # Use a configuration file for script options
 dnsgentool.pl --config /path/to/config/file.cfg

 # Verbose execution
 dnsgentool.pl --verbose --config /path/to/config/file.cfg

You can view the full C<POD> documentation of this file by calling C<perldoc
dnsgentool.pl>.

=head1 DESCRIPTION

B<dnsgentool.pl> is a tool that creates zone files compatable with BIND 9
servers, using a configuration file patterned after Windows-style C<.ini>
files.

=head1 OBJECTS

Note that the objects described below are documented for informational
purposes only, you don't need to instantiate them in order to use this script.

=head2 DNSZoneGen::Config

An object used for storing configuration data.

=head3 Object Methods

=cut 

######################
# DNSZoneGen::Config #
######################
package DNSZoneGen::Config;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use POSIX qw(strftime);

=over

=item new( )

Creates the L<DNSZoneGen::Config> object, and parses out options using
L<Getopt::Long>.

=cut

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
} # sub new


# set defaults here for any missing arugments
sub _apply_defaults {
    my $self = shift;
    # icecast defaults
    $self->set( user => q(source) ) unless ( defined $self->get(q(user)) );
    $self->set( password => q(default) ) unless ( 
        defined $self->get(q(password)) );
} # sub _apply_defaults

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
    #    print $arg . q( = ) . $self->get($arg) . qq(\n);
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
} # if ( exists $args{gen-config} )

=item get($key)

Returns the scalar value of the key passed in as C<key>, or C<undef> if the
key does not exist in the L<DNSZoneGen::Config> object.

=cut

sub get {
    my $self = shift;
    my $key = shift;
    # turn the args reference back into a hash with a copy
    my %args = %{$self->{_args}};

    if ( exists $args{$key} ) { return $args{$key}; }
    return undef;
} # sub get

=item set( key => $value )

Sets in the L<DNSZoneGen::Config> object the key/value pair passed in as
arguments.  Returns the old value if the key already existed in the
L<DNSZoneGen::Config> object, or C<undef> otherwise.

=cut

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
} # sub get

=item get_args( )

Returns a hash containing the parsed script arguments.

=cut

sub get_args {
    my $self = shift;
    # hash-ify the return arguments
    return %{$self->{_args}};
} # get_args

=back

=head2 DNSZoneGen::Parser

Parses the DNSZoneGen INI config file(s), creating objects for each zone read
in from file(s).

=head3 Object Methods

=cut

######################
# DNSZoneGen::Parser #
######################
package DNSZoneGen::Parser;
use strict;
use warnings;
use Config::IniFiles;

# [dnsgentool] block
my @_valid_dnszonegen_args = ( 
    qw(soa_serial_file soa_serial_file_autocreate)
); # my %_valid_global_cfg_args

# [zone_global] block
my @_valid_zone_global_args = qw(
    soa_serial 
    soa_refresh 
    soa_retry 
    soa_expire 
    soa_ttl 
    zone_ttl 
    nameservers 
    path
); # # [zone_global] block

# any block that describes a specific zone
my @_valid_zone_args = qw(
    include 
    alias 
    cname 
    a 
    aaaa
); # my @_valid_zone_args

=over

=item new( )

Creates the L<DNSZoneGen::Parser> object, which opens up the INI file and
parses it into DNS zone objects.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    die qq( ERR: DNSZoneGen::Logger object required as 'logger =>')
        unless ( exists $args{logger} );
    my $_logger = $args{logger};
        
    die qq( ERR: DNSZoneGen::Logger object required as 'config =>')
        unless ( exists $args{config} );
    my $_config = $args{config};

    my $self = bless ({
        _logger => $_logger,
        _config => $_config,
    }, $class);

    return $self;
} # sub new

=item parse($_inifile)

Parses the INI file specified with C<$_inifile>.

=cut

sub parse {
    my $self = shift;
    my $_inifile = shift;
    my $_config = $self->{_config};

    my $_ini = Config::IniFiles->new( -file => $_config->get(q(config)) );
    $self->{_ini} = $_ini;

    # parse out all of the sections in the zone file
    foreach my $section_name ( $_ini->Sections() ) {
        if ( $section_name eq q(dnszonegen) ) {
            $self->_check_dnszonegen();
        } elsif ( $section_name eq q(zone_global) ) {
            $self->_check_zone_global();
        } else { 
            $self->_check_zone($section_name);
        } # if ( $section_name eq q(dnszonegen) )
    } # foreach my $section_name ( $_ini->Sections() )
} # sub parse
# check the [dnszonegen] section
sub _check_dnszonegen {
    my $self = shift;
    my $_ini = $self->{_ini};
    my $_config = $self->{_config};

    foreach my $param ($_ini->Parameters(q(dnszonegen))) {
        if ( grep(/$param/, @_valid_dnszonegen_args) > 0 ) {
            # add this parameter to the main config object
            $_config->set( $param => $_ini->val(q(dnszonegen), $param) );
        } else { 
            if ( defined $self->get(q(continue)) ) {
                warn qq(WARN: unknown parameter '$param' in section )
                    . qq([dnszonegen]\n);
            } else {
                die qq( ERR: unknown parameter '$param' in section )
                    . qq([dnszonegen]\n);
            } # if ( defined $self->get(q(continue)) )
        } # if ( grep(/$param/, @_valid_dnszonegen_args) > 0 )
    } # foreach my $param ($_ini->Parameters(q(dnszonegen)))
} # sub _check_dnszonegen

# check the [zone_global] section
sub _check_zone_global {
    my $self = shift;
    my $_ini = $self->{_ini};

    my %global_args;
    foreach my $param ($_ini->Parameters(q(zone_global))) {
        if ( grep(/$param/, @_valid_zone_global_args) > 0 ) {
            # add this parameter to the main config object
            $global_args{$param} = $_ini->val(q(dnszonegen), $param);
        } else { 
            if ( defined $self->get(q(continue)) ) {
                warn qq(WARN: unknown parameter '$param' in section )
                    . qq([zone_global]\n);
            } else {
                die qq( ERR: unknown parameter '$param' in section )
                    . qq([zone_global]\n);
            } # if ( defined $self->get(q(continue)) )
        } # if ( grep(/$param/, @_valid_zone_global_args) > 0 )
    } # foreach my $param ($_ini->Parameters(q(zone_global)))
} # sub _check_dnszonegen

# check the [zone_global] section
sub _check_zone {
    my $self = shift;
    my $section = shift;
    my $_ini = $self->{_ini};

    if ( ! defined $section ) { 
        die q( ERR: _check_zone called without $section object!);
    } # if ( ! defined $section )

    my %zone_args;

    # scrape all of the key/value pairs out of this section
    foreach my $param ($_ini->Parameters($section)) {
        $zone_args{$param} = $_ini->val($section, $param);
    } # foreach my $param ($_ini->Parameters($section))

    # don't print anything if this section is empty
    if ( scalar(keys(%zone_args)) > 0 ) {
        print qq(Zone parameters for zone ) . $section . qq(:\n);
        foreach my $key ( sort(keys(%zone_args)) ) {
            print qq(\t$key -> ) . $zone_args{$key} . qq(\n);
        } # foreach my $key ( sort(keys(%zone_args)) )
    } # if ( scalar(keys(%zone_args)) > 0 )

    # FIXME create the zone object here, then return it
} # sub _check_zone

=back

=head2 DNSZoneGen::Logger

A simple logger module, for logging script output and errors.

=head3 Object Methods

=cut

######################
# DNSZoneGen::Logger #
######################
package DNSZoneGen::Logger;
use strict;
use warnings;
use POSIX qw(strftime);
use IO::File;
use IO::Handle;

=over 

=item new($_config)

Creates the L<DNSZoneGen::Logger> object, and sets up various filehandles
needed to log to files or C<STDOUT>.  Requires a L<DNSZoneGen::Config> object
as the argument, so that options having to deal with logging can be
parsed/acted upon.  Returns the logger object to the caller.

=cut

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
    } # if ( exists $args{logfile} )
    $logfd->autoflush(1);

    my $self = bless ({
        _OUTFH => $logfd,
    }, $class);

    # return this object to the caller
    return $self;
} # sub new

=item log($message)

Log C<$message> to the logfile, or I<STDOUT> if the B<--logfile> option was
not used.

=cut

sub log {
    my $self = shift;
    my $msg = shift;

    my $FH = $self->{_OUTFH};
    print $FH $msg . qq(\n);
} # sub log

=item timelog($message)

Log C<$message> with a timestamp to the logfile, or I<STDOUT> if the
B<--logfile> option was not used.

=cut

sub timelog {
    my $self = shift;
    my $msg = shift;
    my $timestamp = POSIX::strftime( q(%c), localtime() );

    my $FH = $self->{_OUTFH};
    print $FH $timestamp . q(: ) . $msg . qq(\n);
} # sub timelog

=back

=head2 DNSZoneGen::File

An object that represents the file that is to be streamed to the
Icecast/Shoutcast server.  This is a helper object for the file that helps out
different functions related to file metadata and logging output.  Returns
C<undef> if the file doesn't exist on the filesystem or can't be read.

=head3 Object Methods

=cut

####################
# DNSZoneGen::Zone #
####################
package DNSZoneGen::Zone;
use strict;
use warnings;

=over 

=item new(logger => $_logger, C<key/value pairs)

Creates an object that represents a DNS zone. 

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $_logger;

    die qq( ERR: DNSZoneGen::Logger object required as 'logger =>')
        unless ( exists $args{logger} );
    $_logger = $args{logger};
        
    my $self = bless ({
        # save the config and logger objects so that this object's methods can
        # use them
        _logger => $_logger,
    }, $class);

    # FIXME populate the zone object here so it can be returned
    return $self
} # sub new

=back

=cut

################
# package main #
################
package main;
use strict;
use warnings;


    # create a config object
    my $_config = DNSZoneGen::Config->new();

    # create a logger object, and prime the logfile for this session
    my $_logger = DNSZoneGen::Logger->new($_config);
    $_logger->timelog(qq(INFO: Starting dnsgentool.pl, version $VERSION));
    $_logger->timelog(qq(INFO: my PID is $$));
    my $parser = DNSZoneGen::Parser->new(
        config => $_config, 
        logger => $_logger
    ); # my $parser = DNSZoneGen::Parser->new
    $parser->parse($_config->get(q(config)));
=head1 AUTHOR

Brian Manning, C<< <elspicyjack at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<< <elspicyjack at gmail dot com> >>.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc dnsgentool.pl

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set sw=4 ts=4
