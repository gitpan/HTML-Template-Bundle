use strict;
use warnings;
use Test::More tests => 1;
use HTML::Template::Bundle;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  Hi
  <TMPL_VAR DEBUG>
  there
EOT

eval {
  $htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text);
  $output = $htb->output();
};
ok(!$@);
