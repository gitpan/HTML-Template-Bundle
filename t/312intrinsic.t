use strict;
use warnings;
use Test::More tests => 1;
use HTML::Template::Expr;
my ($htb,$tmpl_text,$output);


$htb = HTML::Template::Expr->new(filename => 't/templates/expr_intrinsic.tmpl',intrinsic_vars => 1);
$output = $htb->output();
ok($output =~ /full/s);



