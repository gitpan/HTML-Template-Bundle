package HTML::Template::ESCAPE::TEXT;
use strict;
use warnings FATAL => 'all';
use base qw(HTML::Template::ESCAPE);
our $VERSION = '2.9_01';

sub output {
  my $self = shift;
  $_ = shift if (@_ > 0);
  s/&/&amp;/g;
  s/\"/&quot;/g; #"
  s/>/&gt;/g;
  s/</&lt;/g;
  s/'/&#39;/g; #'
  s/\r\n/<br>/g;
  s/\n/<br>/g;
  s/\r/<br>/g;
  s/<br>/<br>\n/g;
  $_;
}

1;
