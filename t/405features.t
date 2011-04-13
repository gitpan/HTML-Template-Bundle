use strict;
use warnings;
use Test::More tests => 1;
use HTML::Template::Bundle;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  before
  <TMPL_JOIN loop1 SEP=",">
  after
EOT
$htb = HTML::Template::Bundle->new_bundle(scalarref => \$tmpl_text,scalar_loops => 1);
$htb->param(loop1 => [ 'a','b','c','d','e' ]);
$output = $htb->output();
ok($output =~ /d/s);

