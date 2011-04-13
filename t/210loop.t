use strict;
use warnings;
use Test::More tests => 1;
use HTML::Template;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  before
  <TMPL_LOOP loop1>
    <TMPL_VAR __value__>
  </TMPL_LOOP>
  after
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text,scalar_loops => 1);
$htb->param(loop1 => ['first','second']);
$output = $htb->output();
ok($output =~ /first/s);


