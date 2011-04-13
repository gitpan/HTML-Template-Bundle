use strict;
use warnings;
use Test::More tests => 1;
use HTML::Template::Bundle;
my ($htb,$tmpl_text,$output);


$output = tmpl_render('t/templates/simple.tmpl',
  adjective => "it works"
);

ok($output =~ /it works/s);

