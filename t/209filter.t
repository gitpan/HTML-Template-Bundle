use strict;
use warnings;
use Test::More tests => 2;
use HTML::Template;
my ($ht,$output);


$ht = HTML::Template->new(
  filename => './t/templates/include_path/a.tmpl',
  filter => sub {
    my $textref = shift;
    $$textref =~ s/Bar/Zanzabar/g;
  },
);
$output =  $ht->output;
ok($output =~ /Zanzabar/);


$ht = HTML::Template->new(
  filename => './t/templates/include_path/a.tmpl',
  filter => sub {
    my $textref = shift;
    my $ht = shift;
    if ($ht->{options}->{case_sensitive}) {
      $$textref =~ s/Bar/Zanzabar/g;
    }
  },
);
$output =  $ht->output;
ok($output =~ /Bar/);


