use strict;
use warnings;
use Test::More tests => 6;
use HTML::Template::Bundle;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  Hi
  <TMPL_SET var1=val1>
  <TMPL_VAR var1>
  there
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text);
$output = $htb->output();
ok($output =~ /val1/s);



$tmpl_text=<<EOT;
  Hi
  <TMPL_VAR var1>
  <TMPL_SET var1=val1>
  there
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text);
$output = $htb->output();
ok($output =~ /val1/s);



$tmpl_text=<<EOT;
  <TMPL_SET var1=val1>
  Hi
    <TMPL_LOOP loop1>
      <TMPL_VAR var1>
    </TMPL_LOOP>
  there
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text);
$htb->param(loop1 => [ {} ]);
$output = $htb->output();
ok($output =~ /val1/s);


$tmpl_text=<<EOT;
  Hi
    <TMPL_LOOP loop1>
      <TMPL_SET var1=val1>
      <TMPL_VAR var1>
    </TMPL_LOOP>
  there
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text);
$htb->param(loop1 => [ {} ]);
$output = $htb->output();
ok($output =~ /val1/s);



$tmpl_text=<<EOT;
  Hi
    <TMPL_LOOP loop1>
      <TMPL_VAR var1>
    </TMPL_LOOP>
  there
  <TMPL_SET var1=val1>
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text);
$htb->param(loop1 => [ {} ]);
$output = $htb->output();
ok($output =~ /val1/s);


$tmpl_text=<<EOT;
  Hi
    <TMPL_LOOP loop1>
      <TMPL_SET var1=val1>
    </TMPL_LOOP>
  there
  <TMPL_VAR var1>
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text);
$htb->param(loop1 => [ {} ]);
$output = $htb->output();
ok($output =~ /val1/s);


