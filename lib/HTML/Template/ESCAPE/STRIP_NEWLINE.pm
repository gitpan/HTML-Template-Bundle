package HTML::Template::ESCAPE::STRIP_NEWLINE;
use strict;
use warnings FATAL => 'all';
use base qw(HTML::Template::ESCAPE);
our $VERSION = '2.9_01';

sub output {
  my $self = shift;
  $_ = shift if (@_ > 0);
  s/\n/ /g;
  $_;
}

1;
