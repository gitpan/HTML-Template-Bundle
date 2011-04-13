use Test::More qw(no_plan);
use Parse::RecDescent;

use constant DEBUG => 0;
$::RD_HINT = DEBUG;
# $::RD_TRACE = 1;

use HTML::Template::Expr;
use Data::Dumper;



# test grammar directly

my @tests = (
             "(foo)",
             "foo",
             "(! bif)",
             "!(baz)",
             "(foo || bar || baz || bif)",
             "!(foo || bar || baz || bif)",
             "((foo + 10.1) > 100)",
             "!((foo + 10.1) > 100)",
             "not((foo + 10.1) > 100)",
);

foreach my $test (@tests) {
    print STDERR "TRYING TO PARSE $test\n" if DEBUG;
    my $tree = $HTML::Template::Expr::PARSER->expression($test);
    ok($tree, "parsing \"$test\"");
    if (DEBUG && $tree) {
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Purity = 0;
        local $Data::Dumper::Deepcopy = 1;
        print STDERR Data::Dumper->Dump([\$tree],['$tree']);
        print STDERR "vars: ", join(',', HTML::Template::Expr::_expr_vars($tree)), "\n\n";
    }
}
