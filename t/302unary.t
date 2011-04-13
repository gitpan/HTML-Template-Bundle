use strict;
use warnings;
use Test::More tests => 2;
use HTML::Template::Expr;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  Hi
  <TMPL_VAR EXPR="!(foo)">
  there
EOT
$htb = HTML::Template::Expr->new(scalarref => \$tmpl_text,die_on_bad_params => 0);
$htb->param(foo => 0);
$output = $htb->output();
print $output;
ok($output =~ /1/s);


$tmpl_text=<<EOT;
  <TMPL_IF EXPR="!(foo eq 'hi')">
    match
  <TMPL_ELSE>
    no match
  </TMPL_IF>
EOT
$htb = HTML::Template::Expr->new(scalarref => \$tmpl_text,die_on_bad_params => 0);
$htb->param(foo => 'hi');
$output = $htb->output();
print $output;
ok($output =~ /no match/s);


