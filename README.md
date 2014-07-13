# DNS Zone Builder #

Generate DNS zone files to be used with ISC's `BIND` and `DHCPD` software
applications using "INI-style" configuration files.

Homepage: https://github.com/cpanxaoc/App-DNSZoneBuilder

License: Perl 5 (Perl Artistic or GNU GPL v1)

## Todo ##
- Use templates to capture similar behaivor and hostnames between different
  domains/zone files
- Use actual zone files as test files, in order to compare generated zone
  files against something
- IPv6 support
- Round trip
  - Encode a DNS update to an internal/binary format, then decode the message,
    and make sure it matches the original message
  - Changes to DNS should be encodable to a _Net::DNS::Update_ object, so that
    the update can be sent to a server if desired

## Implementation Notes ##
- Create a general/generic SOA template file
  - Set the `$ORIGIN`
- Include A/AAAA/NS/MX/TXT records from other files, as desired
  - Keep track of what records are sourced from what files, so
    duplicates/errors can be reported back to the user
- Generate `dhcpd.conf` files with the correct information
- Generate reverse DNS zone files with the correct information
- Add the ability to add "host comments", or comments about a given host, to
  the `dhcpd.conf` files and DNS zone files

vim: filetype=markdown shiftwidth=2 tabstop=2
