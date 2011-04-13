use strict;
use warnings;
use Test::More tests => 2;
use HTML::Template::Bundle;
my ($htb,$tmpl_text,$output);


$ENV{BUNDLE_TEST} = "BUNDLE_VALUE";
$tmpl_text=<<EOT;
  Hi
  <TMPL_VAR ENV_BUNDLE_TEST>
  there
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text,env_variables => 1); #,die_on_unset_params => 0);
$output = $htb->output();
ok($output =~ /BUNDLE_VALUE/s);


$ENV{BUNDLE_TEST} = "BUNDLE_VALUE";
$tmpl_text=<<EOT;
  Hi
  <TMPL_VAR ENV.BUNDLE_TEST>
  there
EOT
$htb = HTML::Template::Bundle->new(scalarref => \$tmpl_text,structure_vars => 1,env_variables => 1); #,die_on_unset_params => 0);
$output = $htb->output();
ok($output =~ /BUNDLE_VALUE/s);


