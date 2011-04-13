use strict;
use warnings;
use Test::More tests => 3;
use HTML::Template;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  <TMPL_IF var1>
    val1
  <TMPL_ELSE>
    val2
  </TMPL_IF>
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => 1);
$output = $htb->output();
ok($output =~ /val1/s);

$htb = HTML::Template->new(scalarref => \$tmpl_text, die_on_bad_params => 0); #, die_on_unset_params => 0);
$htb->param(var2 => 1);
$output = $htb->output();
ok($output =~ /val2/s);

$htb = HTML::Template->new(scalarref => \$tmpl_text, die_on_unset_params => 1);
$htb->param(var1 => 1);
$output = $htb->output();
ok($output =~ /val1/s);

