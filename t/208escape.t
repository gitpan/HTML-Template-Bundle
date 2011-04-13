use strict;
use warnings;
use Test::More tests => 4;
use HTML::Template;
my ($htb,$tmpl_text,$output);

# 1
# HTML
# DOUBLE_QUOTE
# JS
# STRIP_NEWLINE
# TEXT
# URL


$tmpl_text=<<EOT;
  <TMPL_VAR name=var1 escape=1>
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => 'val1');
$output = $htb->output();
ok($output =~ /val1/s);

$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => '&');
$output = $htb->output();
ok($output =~ /&amp;/s);




$tmpl_text=<<EOT;
  <TMPL_VAR name=var1 escape=HTML>
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => 'val1');
$output = $htb->output();
ok($output =~ /val1/s);

$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(var1 => '&');
$output = $htb->output();
ok($output =~ /&amp;/s);

