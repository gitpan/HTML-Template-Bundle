package HTML::Template::ESCAPE::JS;
use strict;
use warnings FATAL => 'all';
use base qw(HTML::Template::ESCAPE);
our $VERSION = '2.9';

sub output {
  my $self = shift;
  $_ = shift if (@_ > 0);
  s/\\/\\\\/g;
  s/'/\\'/g;
  s/"/\\"/g;
  s/\n/\\n/g;
  s/\r/\\r/g;
  $_;
}

1;
