use strict;
use warnings;
use Test::More qw(no_plan);
use HTML::Template;
my ($htb,$tmpl_text,$output);


SKIP: {
  skip("Not yet implemented...");

$tmpl_text=<<EOT;
  <TMPL_VAR var1>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => 'val1');
$output = $htb->output();
ok($output =~ /val1/);


$tmpl_text=<<EOT;
  <TMPL_VAR var1_length>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text,die_on_bad_params => 0);
$htb->param(var1 => 'val1');
$output = $htb->output();
ok($output =~ /\s+/);


$tmpl_text=<<EOT;
  <TMPL_VAR var1>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text,automatic_length_param => 1);
$htb->param(var1 => 'val1');
$output = $htb->output();
ok($output =~ /val1/);


$tmpl_text=<<EOT;
  <TMPL_VAR var1_length>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text,automatic_length_param => 1,die_on_bad_params => 0);
$htb->param(var1 => 'somevalue_with_length');
$output = $htb->output();
ok($output =~ /21/);

}
