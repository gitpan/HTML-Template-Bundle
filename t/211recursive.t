use strict;
use warnings;
use Test::More tests => 1;
use HTML::Template;
my ($htb,$tmpl_text,$output);


$tmpl_text=<<EOT;
  before
  <TMPL_INCLUDE <TMPL_VAR file_to_include>>
  after
EOT

$htb = HTML::Template->new(scalarref => \$tmpl_text,recursive_templates => 1);
$htb->param(file_to_include => 't/templates/simple.tmpl');
$htb->param(adjective => 'first');
$output = $htb->output();
ok($output =~ /first/s);


