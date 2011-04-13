use strict;
use warnings;
use Test::More tests => 2;
use HTML::Template;
my ($htb,$tmpl_text,$output,@items);


$tmpl_text=<<EOT;
  <TMPL_IF var1>
    val1
  <TMPL_ELSIF var2>
    val2
  <TMPL_ELSE>
    val3
  </TMPL_IF>
EOT

$tmpl_text=<<EOT;
  <TMPL_INCLUDE t/templates/simple.tmpl>
  <TMPL_INCLUDE t/templates/simple.tmpl>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(ADJECTIVE => "single");
$output = $htb->output();
@items = split(/single/,$output);
ok(@items == 3);



$tmpl_text=<<EOT;
  <TMPL_REQUIRE t/templates/simple.tmpl>
  <TMPL_REQUIRE t/templates/simple.tmpl>
EOT
$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(ADJECTIVE => "single");
$output = $htb->output();
@items = split(/single/,$output);
ok(@items == 2);

