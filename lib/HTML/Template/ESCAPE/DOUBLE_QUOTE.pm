package HTML::Template::ESCAPE::DOUBLE_QUOTE;
use strict;
use warnings FATAL => 'all';
use base qw(HTML::Template::ESCAPE);
our $VERSION = '2.9';

sub output {
  my $self = shift;
  $_ = shift if (@_ > 0);
  $_ = '"'.$_.'"';
}

1;
