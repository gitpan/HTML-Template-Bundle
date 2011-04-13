use strict;
use warnings;
use Test::More tests => 2;
use HTML::Template;
my ($htb,$tmpl_text,$output);

my $hash = {
  BUNDLE_TEST => 'BUNDLE_VALUE',
};

$tmpl_text=<<EOT;
  Hi
  <TMPL_VAR env>
  <TMPL_VAR env_BUNDLE_TEST>
  there
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text);
$htb->param(env => $hash);
$output = $htb->output();
ok($output =~ /BUNDLE_VALUE/s);



$tmpl_text=<<EOT;
  Hi
  <TMPL_VAR env>
  <TMPL_VAR env.BUNDLE_TEST>
  there
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text,structure_vars => 1);
$htb->param(env => $hash);
$output = $htb->output();
ok($output =~ /BUNDLE_VALUE/s);

