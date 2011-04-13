package HTML::Template::ESCAPE::URL;
use strict;
use warnings FATAL => 'all';
use base qw(HTML::Template::ESCAPE);
use vars qw(%MAP);
our $VERSION = '2.9';

sub output {
  my $self = shift;
  $_ = shift if (@_ > 0);

  # Build a char->hex map if one isn't already available
  unless (exists($MAP{chr(1)})) {
    for (0..255) { $MAP{chr($_)} = sprintf('%%%02X', $_); }
  }

  # do the translation (RFC 2396 ^uric)
  s!([^a-zA-Z0-9_.\-])!$MAP{$1}!g;

  $_;
}

1;
