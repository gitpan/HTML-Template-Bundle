package HTML::Template::ESCAPE;
use strict;
use warnings FATAL => 'all';
use base qw();
our $VERSION = '2.9';

sub new {
  my $unused;
  my $self = \$unused;
  bless($self, $_[0]);
  return $self;
}

# straight from the CGI.pm bible.
sub output {
  my $self = shift;
  $_ = shift if (@_ > 0);
  s/&/&amp;/g;
  s/\"/&quot;/g; #"
  s/>/&gt;/g;
  s/</&lt;/g;
  s/'/&#39;/g; #'
  $_;
}

1;
__END__

=head1 NAME

HTML::Template::ESCAPE

=head1 SYNOPSIS

This module implements 'HTML escaping' of TMPL_VAR output, as in:

  ...<TMPL_VAR NAME=some_var ESCAPE=HTML>...

=head1 DESCRIPTION

You can use the "ESCAPE=xxx" option in a TMPL_VAR tag to indicate that you
want the value to be escaped before being returned from output.
Example:

   <input name=param type=text value="<TMPL_VAR NAME="PARAM">">

If the value within PARAM contained sam"my, you will get into trouble
with HTML's idea of double-quoting.  To overcome this you can use the
form:

   <input name=param type=text value="<TMPL_VAR ESCAPE=HTML NAME="PARAM">">

which tells HTML::Template that you would like it to transform any
characters that HTML renderers would consider bad-form, into their
corresponding HTML equivalent-character entities.  This means that the
", <, >, and & characters get translated into &quot;, &lt;, &gt; and &amp;
respectively.  This is useful when you want to use a TMPL_VAR in a context
where those characters would cause trouble.  Thus you will get what you
wanted no matter what value happens to be passed in for param.

You can also write ESCAPE="HTML", ESCAPE='HTML' and ESCAPE='1'.  Substitute
a 0 for the HTML and you turn off escaping, which is the default anyway.

=head1 ESCAPE modes

=head2 ESCAPE=HTML

Using ESCAPE=HTML implements the example describe above; ", <, > and &
characters get translated into &quot;, &lt;, &gt; and &amp; respectively.

=head2 ESCAPE=URL

There is the "ESCAPE=URL" option which may be used for VARs that
populate a URL.  It will do URL escaping, like replacing ' ' with '%20', '+'
with '%2B' and '/' with '%2F'.

=head2 ESCAPE=JS

There is also the "ESCAPE=JS" option which may be used for VARs that
need to be placed within a Javascript string. All \n, \r, ' and " characters
are escaped.

=head2 ESCAPE=TEXT

There is the "ESCAPE=TEXT" option which allows you to use semi-
preformatted text (for example, text containing newlines), to be
translated to html tags.  This allows you to use TMPL_VAR's within the
context of paragraph formatting, so that you will get a reasonable
looking layout of the content of the template variable, rather than requiring
to revert to using <pre>...</pre> tags. '\n', '\r\n', '\r' all get translated
into '<br>\n'.

Since any text which contains ", <, > and & will also affect a html parsers'
interpretation of subsequent text, those characters are also translated into
their character entity references (as is done by ESCAPE=HTML).

=head1 CUSTOM ESCAPE HANDLING

HTML::Template allows you to use your own ESCAPE definitions, such as
ESCAPE=MY_ESCAPE.  To implement your own definition, you will need to
sub-class HTML::Template, then overload L<parse_escape_construct()>,
implementing something for the new escape handler.

You will need to define a escape handler package, which implements the
L<output()> method.
Example:

  package MyHtmlTemplateEscape;
  use base qw(HTML::Template::Escape);
  sub output {
    my $self = shift;
    $_ = shift if (@_ > 0);
    # ... do something to $_ ...
    $_;
  }

  package MyHtmlTemplate;
  use base qw(HTML::Template);
  sub parse_escape_construct {
    my $self = shift;
    my $escape = shift;
    if ($escape eq 'MY_ESCAPE') {
      require MyHtmlTemplateEscape;
      return MyHtmlTemplateEscape->new();
    }
    return $self->parse_escape_construct($escape);
  }

=head1 NOTES

The old ESCAPE=1 syntax is still supported.

The current implementation of detecting custom ESCAPE constructs
could be made more user friendly, so as to save the user needing
to overload HTML::Template.

=cut
