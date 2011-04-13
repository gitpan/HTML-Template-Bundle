use strict;
use warnings;
use Test::More tests => 4;
use HTML::Template;
my ($htb,$tmpl_text,$output);


$htb = HTML::Template->new(
  path => 't/templates',
  filename => 'simple.tmpl',
  debug => 0,
);
$htb->param('ADJECTIVE' => 'very');
$output =  $htb->output;
ok($output !~ /ADJECTIVE/ and $htb->param('ADJECTIVE') eq 'very');


$tmpl_text=<<EOT;
  <TMPL_VAR var1>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => 'val1');
$output = $htb->output();
ok($output =~ /val1/);


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


$tmpl_text=<<EOT;
  <TMPL_UNLESS var1>
    val1
  <TMPL_ELSE>
    val2
  </TMPL_UNLESS>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => 1);
$output = $htb->output();
ok($output =~ /val2/s);

