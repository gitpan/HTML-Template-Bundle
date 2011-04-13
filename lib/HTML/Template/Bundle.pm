package HTML::Template::Bundle;
use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use HTML::Template::Expr '0.07_01';
use base 'HTML::Template::Expr';
use Exporter qw(import);
use HTML::Template::Filters;
our $VERSION = '0.01';
our @EXPORT = qw(tmpl_render);
our $DEBUG = int(defined $ENV{DEBUG} ? $ENV{DEBUG} : 0) unless $DEBUG;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $options = {};
  $options = HTML::Template::_load_supplied_options([@_], $options);
  $options->{extended_syntax} = 1;

  # Should we associate the environmental variables? If the value is set
  # to a string, that is the prefix otherwise use the syntax ENV.xxx (we
  # have already enabled structure_vars).
  my $env = delete $options->{env_variables};

  # create the instance
  my $self = $class->SUPER::new(%$options);
  die "Failed to create ".__PACKAGE__ unless $self;

  # Pump in the environmental variables
  if ($env) {
    my %pmap = map { $_ => 1 } $self->param();
    $env = "ENV" if ($env =~ /^\d+$/);
    my $sep = $options->{structure_vars} ? "." : "_";
    foreach my $k (keys %ENV) {
      my $key = $env.$sep.$k;
      $key = lc($key) unless $options->{case_sensitive};
      exists $pmap{$key} && $self->param($key => $ENV{$k});
    }
  }

  return bless $self, $class;
}

sub new_bundle {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $options = {
    die_on_bad_params => 0,
    die_on_unset_params => 1,
    structure_vars => 1,
    loop_context_vars => 1,
    intrinsic_vars => 1,
    recursive_templates => -1,
    strict => 0,
    filter => HTML::Template::Filters->get_filters(
      HT_FILTER_ALLOW_TRAILING_SLASH,
      HT_FILTER_SSI_INCLUDE_VIRTUAL,
      HT_FILTER_PERCENT_VARIABLES,
      HT_FILTER_TMPL_CONSTANT,
      HT_FILTER_TMPL_COMMENT,
      HT_FILTER_TMPL_FIXME,
      HT_FILTER_TMPL_JOIN,
      $DEBUG ? HT_FILTER_STRIP_TMPL_NEWLINE_WHITESPACE : HT_FILTER_STRIP_REDUNDANT,
    ),
  };
  $options = HTML::Template::_load_supplied_options([@_], $options);

  my $self = $class->new(%$options);
  $self->param(DEBUG => $DEBUG);

  return $self;
}

#--------------------------------------------------------------------------
# Override the default handling of parsing of unknown
# TMPL_xxx tags. Tags we know about:
#
# TMPL_SET
#
sub handle_tmpl_construct {
  my ($self,$slash,$which,$part,$post,$pmap,$top_pmap) = @_;
  my $options = $self->{options};
  print STDERR "Handling custom TMPL_xxx construct:$/- TMPL_xxx: $slash$which$/- TMPL part: $part$/- post: $post$/ $/" if $options->{debug};

  if ($which eq 'SET') {

    # Translation of string and any template variables
    if ($part =~ /^\s*

                   # name = value
                   ([^=]+)         # $1 => name
                   \s*=\s*
                   (
                     (?:"[^"]*")
                     |
                     (?:'[^']*')
                     |
                     (?:[^\s]*)
                   )               # $2 => value

                   $/sxo) {
      my $name = $1;
      my $value = defined $2 ? $2 : '';
      if (defined $name and length $name) {
        $self->{set_stack} = [] unless $self->{set_stack};
        push @{$self->{set_stack}}, [$name,$value];
        return undef,$post;
      }
      print STDERR "Failed handling <TMPL_$which ...> - unknown key $/";
      return undef,$post;
    }

    print STDERR "Failed handling <".$slash."TMPL_$which \"$part\"> - incorrect syntax $/";
    return undef,$post;
  }

  return $self->SUPER::handle_tmpl_construct($slash,$which,$part,$post,$pmap,$top_pmap);
}

## overload default handling of ouput generation for custom TMPL_xxx tags
sub handle_parse_stack_construct {
  my ($self,$index,$type,$tmpl_obj,$force_untaint) = @_;
  my $options = $self->{options};
  return $self->SUPER::handle_parse_stack_construct($index,$type,$tmpl_obj,$force_untaint);
}

## Overload _init() so that we pump out the TMPL_SET param()'s
sub _init {
  my $self = shift;
  $self->SUPER::_init(@_);
  if ($self->{set_stack}) {
    foreach my $set (@{$self->{set_stack}}) {
      $self->param($set->[0] => $set->[1]);
    }
  }
}

## Simple support for batch/CGI processing
sub tmpl_render {
  my $tmplfile = shift;
  my $htmlfile = defined wantarray ? undef : shift;
  croak("Incorrect num of params to tmpl_render") unless (@_ % 2 == 0);
  my $path = [];
  if ($tmplfile =~ /(.*)\/(.*)$/) {
    push @$path, $1;
  }
  my $ht = __PACKAGE__->new_bundle(
    filename => $tmplfile,
    path => $path,
    search_path_on_include => 1,
  );
  for($. = 0; $. < scalar(@_); $. += 2) {
    my $key = $_[$.];
    my $val = $_[$.+1];
    $ht->param($key => $val);
    my $r = HTML::Template::reftype($val);
    if ($r eq 'ARRAY') {
      $val = scalar(@$val);
    } elsif ($r =~ 'HASH') {
      $val = scalar(keys %$val);
    } elsif (defined $val) {
      $val = length $val;
    } else {
      $val = 0;
    }
    $ht->param($key.".length" => $val);
  }
  my $content = $ht->output();
  if ($htmlfile) {
    open(FH,">","$htmlfile.tmp") or die $!;
    print FH $content;
    close(FH);
    rename("$htmlfile.tmp","$htmlfile") or die $!;
  }
  return $content;
}

1;
__END__
=pod

=head1 NAME

HTML::Template::Bundle - Use everything available from HTML::Template

=head1 SYNOPSIS

  use HTML::Template::Bundle;

  my $template = HTML::Template::Bundle->new(filename => 'foo.tmpl');
  $template->param(...);
  print $template->output();

or

  my $template = HTML::Template::Bundle->new_bundle(filename => 'foo.tmpl');

If you prefer a shrink-wrapped version.

  use HTML::Template::Bundle;
  my $content = tmpl_render('foo.tmpl',
    ....
  ));
  print $content;


=head1 DESCRIPTION

This module provides an extension to HTML::Template (and HTML::Template::Expr)
which enables all of the useful feature requests made over the years.

Basically all of the documentation for the original HTML::Template, applies
here too.  That said, there are a lot of enhancements, so you will want to
familiarise yourself with the new features, thus C<perldoc HTML::Template>
and C<perldoc HTML::Template::Expr> contain the updated docs.  You will
also want to read up on C<HTML::Template::Bundle> (aka this document),
C<HTML::Template::Filters>, C<HTML::Template::ESCAPE> and C<HTML::Template::Preload>.

=head1 NEW TAGS

=head2 TMPL_SET

  <TMPL_SET some_VARIABLE_nAme="some value">

Does the equivalent of $ht->param(some_VARIABLE_nAme => "some value"), but from
within the template.

=head1 METHODS

=head2 new()

Call new() to create a new Bundle instance; this instance doesn't have any
HTML::Template options altered, so it its pimarily used as a drop-in
replacement for existing code.

=head2 new_bundle()

Call new_bundle() enable most the new features provided by the HTML::Template
enhancements and by the H::T::Bundle package.

These options are enabled as defaults:

  die_on_bad_params => 0
  die_on_unset_params => 1
  structure_vars => 1
  loop_context_vars => 1
  intrinsic_vars => 1
  recursive_templates => -1
  strict => 0
  filters =>
    HT_FILTER_ALLOW_TRAILING_SLASH
    HT_FILTER_SSI_INCLUDE_VIRTUAL
    HT_FILTER_PERCENT_VARIABLES
    HT_FILTER_TMPL_CONSTANT
    HT_FILTER_TMPL_COMMENT
    HT_FILTER_TMPL_FIXME
    HT_FILTER_TMPL_JOIN

The DEBUG environmental variable is used to determine the current build
environment, resulting in these defaults:

  filters =>
    $DEBUG ? HT_FILTER_STRIP_TMPL_NEWLINE_WHITESPACE : HT_FILTER_STRIP_REDUNDANT

Note that since H::T filters are stacked, the filters listed above are
executed in that order.

=head2 tmpl_render

To simplify use of H::T::B features, we default-export a function which you
can use for simple CGI or batch processing.  Use it like:

  tmpl_render('blah.tmpl','blah.html',
    var => 'val',
    ...
  );

or

  my $content = tmpl_render('blah.html,
    var => 'val',
    ...
  );

Note that internally it new_bundle(); if you require a differing set of
options, you will need to call new() as appropriate.

=head1 OPTIONS

=head2 Defaults

All existing options are passed directly to H::T, except that we enable the
extended_syntax option so that we can make use of TMPL_SET, etc.  Also note
that H::T::B is a sub-class of H::T::E so global_vars is enabled by default.

=head2 New Options

=over 4

=item env_variables

Automatically define environmental variables as params. Note that case is
preserved, as most environments will support mixed-case variables.

If this value is a string, it will be used for the prefix - otherwise 'ENV'
is used.  If 'structure_vars' is enabled, dotted-notation is used as the
seperator - otherwise an underscore is used.

=back

=head1 MOTIVATION

I wanted to use all of the HTML::Template features, without having to
always write lots of code to make H::T sane.  And I didn't particularly
like using Template::Toolkit due to its quirks... and it is too much like
PHP...

So as written in the HTML::Template::Expr perldoc:

=over 4

  If you don't like it, don't use this module.  Keep using plain ol' HTML::Template - I know I will!

=back

=head1 MOD_PERL TIP

Both HTML::Template and HTML::Template::Expr recommend some various
tips when running under mod_perl.  H::T::Preload simplifies this.

=head1 CAVEATS

The HTML::Template defaults for this module, differ than those for
HTML::Template.... be aware...

=head1 BUGS

I am aware of no bugs - but I do know that some test cases arn't
covered.

You can still email me directly if you find any.

=head1 CREDITS

Sam Tregar for the HTML::Template and H::T::Expr modules.

Ideas from the H::T mailing list.

Me.

Thanks!

=head1 AUTHOR

Mathew Robertson <mathew@users.sf.net>

=head1 LICENSE

Liscense is the same as that used by HTML::Template.

