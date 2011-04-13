use strict;
use warnings;
use Test::More tests => 3;
use HTML::Template;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  before
  <TMPL_VAR __type__>
  after
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text,intrinsic_vars => 1);
$output = $htb->output();
ok($output =~ /scalarref/s);


$htb = HTML::Template->new(filename => 't/templates/intrinsic.tmpl',intrinsic_vars => 1);
$output = $htb->output();
ok($output =~ /intrinsic.tmpl/s);


$htb = HTML::Template->new(filename => 't/templates/inc_intrinsic.tmpl',intrinsic_vars => 1);
$output = $htb->output();
ok($output =~ /inc_intrinsic.tmpl/s);


