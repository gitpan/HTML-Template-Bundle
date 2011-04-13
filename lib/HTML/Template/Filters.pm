package HTML::Template::Filters;
use strict;
use warnings FATAL => 'all';
use utf8;
use Exporter;
use Carp;
use vars qw(@ISA @EXPORT);
our $VERSION = '0.05';

@ISA = qw(Exporter);
@EXPORT = qw(
  HT_FILTER_STRIP_TMPL_NEWLINE_WHITESPACE
  HT_FILTER_VANGUARD_COMPATIBILITY
  HT_FILTER_ALLOW_TRAILING_SLASH
  HT_FILTER_SSI_INCLUDE_VIRTUAL
  HT_FILTER_STRIP_TMPL_NEWLINE
  HT_FILTER_GZIPPED_TEMPLATES
  HT_FILTER_PERCENT_VARIABLES
  HT_FILTER_STRIP_REDUNDANT
  HT_FILTER_STRIP_NEWLINE
  HT_FILTER_TMPL_CONSTANT
  HT_FILTER_TMPL_COMMENT
  HT_FILTER_TMPL_FIXME
  HT_FILTER_TMPL_JOIN
  HT_FILTER_MAC_OS
);

use constant HT_FILTER_STRIP_TMPL_NEWLINE_WHITESPACE => 'strip_tmpl_newline_whitespace';
use constant HT_FILTER_VANGUARD_COMPATIBILITY => 'percent_variables';
use constant HT_FILTER_ALLOW_TRAILING_SLASH => 'allow_trailing_slash';
use constant HT_FILTER_SSI_INCLUDE_VIRTUAL => 'ssi_include_virtual';
use constant HT_FILTER_STRIP_TMPL_NEWLINE => 'strip_tmpl_newline';
use constant HT_FILTER_GZIPPED_TEMPLATES => 'gzipped_templates';
use constant HT_FILTER_PERCENT_VARIABLES => 'percent_variables';
use constant HT_FILTER_STRIP_REDUNDANT => 'strip_redundant';
use constant HT_FILTER_STRIP_NEWLINE => 'strip_newline';
use constant HT_FILTER_TMPL_CONSTANT => 'tmpl_constant';
use constant HT_FILTER_TMPL_COMMENT => 'tmpl_comment';
use constant HT_FILTER_TMPL_FIXME => 'tmpl_fixme';
use constant HT_FILTER_TMPL_JOIN => 'tmpl_join';
use constant HT_FILTER_MAC_OS => 'mac_os';

#
# Example: get_filters(HT_FILTER_ALLOW_TRAILING_SLASH,HT_FILTER_TMPL_COMMENT);
#
sub get_filters {
  croak "Invalid arguments to HTML::Template::Filters->get_filters()" unless (@_ > 1);
  my $pkg = shift;
  my @wanted_filters = @_;

  # get the requested filters
  my @filter_subs;
  foreach my $wanted_filter (@wanted_filters) {
    next unless (defined $wanted_filter and length $wanted_filter);
    croak "Unknown filter: $wanted_filter" unless ($pkg->can($wanted_filter));
    my ($filter,$format) = $pkg->$wanted_filter();
    $format = 'scalar' if (not defined $format or $format ne 'array');
    push @filter_subs, {
      'sub' => $filter,
      'format' => $format,
    };
  }

  return \@filter_subs;
}

#
# allow trailing slash in <TMPL_xxx /> tags
#
sub allow_trailing_slash {
  my $filter = sub {
    my $text_ref = shift;
    my $match = qr/(<[Tt][Mm][Pp][Ll]_[^>]+)\/>/;
    $$text_ref =~ s/$match/$1>/g;
  };
  return $filter;
}

#
# Translate the SSI "include virtual" into a template include:
#
sub ssi_include_virtual {
  my $filter = sub {
    my $text_ref = shift;
    my $match = qr/<!--\s*#include virtual="[\/]?(.+?)"\s*-->/i;
    $$text_ref =~ s/$match/<TMPL_INCLUDE NAME="$1">/g;
  };
  return $filter;
}

#
# Decompress gzip-comressed templates
#
sub gzipped_templates {
  eval { require Compress::Zlib; };
  croak "To use gzip-compressed templates, you need into install Compress::Zlib" if ($@);
  my $filter = sub {
    my $text_ref = shift;
    require Compress::Zlib;
    $text_ref = Compress::Zlib::uncompress($text_ref);
  };
  return $filter;
}

#
# Allow template variables to use %var% syntax
#
sub percent_variables {
  my $filter = sub {
    my $text_ref = shift;
    my $match = qr/%([-\w\/\.+]+)%/;
    $$text_ref =~ s/$match/<TMPL_VAR NAME="$1">/g;
  };
  return $filter;
}

#
# Strip newline's following TMPL_XXX statements
#
sub strip_tmpl_newline {
  my $filter = sub {
    my $text_ref = shift;
    $$text_ref =~ s/(<TMPL_[^>]>)[\r\n]+/$1/g;
  };
  return $filter;
}


# remove any space at the start of a line if it is immediately before a tmpl tag
sub strip_tmpl_newline_whitespace {
  my $filter = sub {
    my $text_ref = shift;
    $$text_ref =~ s!^\s+(</?TMPL_[^>]+>)!$1!sg;
    $$text_ref =~ s!(</?TMPL_[^>]>)[\r\n]+!$1!sg;
  };
  return $filter;
}

##
## Concept taken from Compress::LeadingBlankSpaces to remove redundant data from the output stream
##
## -> Takes a string ref and returns string ref, so as to minimise data copying
## -> skip over headers...
## -> respects <pre>...</pre> tags
## -> strips leading spaces
## -> strips javascript comments
## -> strips style comments
## -> strips html comments
## -> strips empty lines
## -> Doesn't support multi-line stripping, as this complicates the issue somewhat
##
sub strip_redundant {
  my $filter = sub {
    my $text_ref = shift;
    my @buf = split('\n',$$text_ref);
    my $output = '';
    my $pre = 0;
    my $script = 0;
    my $style = 0;
    my $headers = 1;
  
    LOOP: foreach (@buf) {
  
      ## skip over headers
      if ($headers) {
        /<[Hh][Tt][Mm][Ll]/o and $headers=0;
        if ($headers) {
          $output .= $_ ."\n";
          next;
        };
      }
  
      ## find any </pre>
      if (/<\/[Pr][Rr][Ee]>/o) {
        $output .= $_ ."\n";
        $pre=0;
        next;
      }
      if ($pre) {
        $output .= $_ ."\n";
        next;
      }
  
      chomp;
      next unless length;
  
      ## javascript comments
      /<[Ss][Cc][Rr][Ii][Pp][Tt]/o and $script=1;
      /<\/[Ss][Cc][Rr][Ii][Pp][Tt]>/o and $script=0;
      if ($script) {
        /^\/\//o and not /-->/o and next;
        /(.*)\/\/(.*)$/o and not ($1 =~ /http/o or $2 =~ /-->/o) and s/\s*\/\/.*$//o and next unless length;
        s/\s*\/\*.*\*\/\s*//o and next unless length;
      }
  
      ## support in-document styles
      /<[Ss][Tt][Yy][Ll][Ee]/o and $style=1;
      /<\/[Ss][Tt][Yy][Ll][Ee]>/o and $style=0;
      if ($style) {
        s/\s*\/\*.*\*\/\s*//o and next unless length;
      }
  
      ## html comments
      s/<!--.*-->//o unless ($style or $script);
  
      ## trailing white space
      s/\s+$//o;
  
      ## leading white space
      s/^\s+//o;
  
      ## all white space
      s/^\s*$//o;
  
      ## if we got here and the line contains no content, dont do anything
      next unless length;
  
      ## find any <pre>
      /<[Pr][Rr][Ee]>/o and $pre++;
  
      $output .= $_ ."\n";
    }
  
    $text_ref = \$output;
  };
  return $filter;
}

#
# Simple newline strip
#
sub strip_newline {
  my $filter = sub {
    my $text_ref = shift;
    $$text_ref =~ s/\n\| *//g;
  };
  return $filter;
}

#
# strip out <TMPL_COMMENT>...</TMPL_COMMENT> entries
#
sub tmpl_comment {
  my $filter = sub {
    my $text_ref = shift;
    my $match  = qr/<(?:\!--\s*)?[Tt][Mm][Pp][Ll]_[Cc][Oo][Mm][Mm][Ee][Nn][Tt]\s*(?:--)?>.*?<(?:\!--\s*)?\/[Tt][Mm][Pp][Ll]_[Cc][Oo][Mm][Mm][Ee][Nn][Tt]\s*(?:--)?>/s;
    $$text_ref  =~ s/$match//g;
  };
  return $filter;
}

#
# strip out <TMPL_FIXME>...</TMPL_FIXME> entries
#
sub tmpl_fixme {
  my $filter = sub {
    my $text_ref = shift;
    my $match  = qr/<(?:\!--\s*)?[Tt][Mm][Pp][Ll]_[Ff][Ii][Xx][Mm][Ee]\s*(?:--)?>.*?<(?:\!--\s*)?\/[Tt][Mm][Pp][Ll]_[Ff][Ii][Xx][Mm][Ee]\s*(?:--)?>/s;
    $$text_ref  =~ s/$match//g;
  };
  return $filter;
}

#
# strip out <TMPL_JOIN ...> entries
#
sub tmpl_join {
  my $filter = sub {
    my $text_ref = shift;
    my $ht = shift;
    my $options = $ht->{options};
    die "TMPL_JOIN requires 'loop_context_vars' to be set" unless $options->{loop_context_vars};
    my @chunks = split(m!(?=<(?:\!--\s*)?[Tt][Mm][Pp][Ll]_[Jj][Oo][Ii][Nn]\s)!, $$text_ref);
    for (my $count = 0; $count < @chunks; $count++) {
      my $chunk = $chunks[$count];
      if ($chunk =~ /^<
                      (?:!--\s*)?
                      (?:
                        [Tt][Mm][Pp][Ll]_[Jj][Oo][Ii][Nn]
                      )

                      \s+

                      # ESCAPE attribute
                      (?:
                        [Ee][Ss][Cc][Aa][Pp][Ee]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $1 => ESCAPE
                      )?
   
                      \s*
   
                      # FIELD attribute
                      (?:
                        [Ff][Ii][Ee][Ll][Dd]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $2 => FIELD
                      )?
   
                      \s*
   
                      # SEP attribute
                      (?:
                        [Ss][Ee][Pp](?:[Aa][Rr][Aa][Tt][Oo][Rr])?
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $3 => SEP
                      )?
    
                      \s*
   
                      # ESCAPE attribute
                      (?:
                        [Ee][Ss][Cc][Aa][Pp][Ee]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $4 => ESCAPE
                      )?
   
                      \s*
   
                      # FIELD attribute
                      (?:
                        [Ff][Ii][Ee][Ll][Dd]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $5 => FIELD
                      )?
   
                      \s*
   
                      # SEP attribute
                      (?:
                        [Ss][Ee][Pp](?:[Aa][Rr][Aa][Tt][Oo][Rr])?
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $6 => SEP
                      )?
    
                      \s*
   
                      # ESCAPE attribute
                      (?:
                        [Ee][Ss][Cc][Aa][Pp][Ee]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $7 => ESCAPE
                      )?
   
                      \s*
   
                      # NAME attribute
                      (?:
                        (?:
                          [Nn][Aa][Mm][Ee]
                          \s*=\s*
                        )?
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $8 => NAME
                      )?
   
                      \s*
   
                      # ESCAPE attribute
                      (?:
                        [Ee][Ss][Cc][Aa][Pp][Ee]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $9 => ESCAPE
                      )?
   
                      \s*
   
                      # FIELD attribute
                      (?:
                        [Ff][Ii][Ee][Ll][Dd]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $10 => FIELD
                      )?
   
                      \s*
   
                      # SEP attribute
                      (?:
                        [Ss][Ee][Pp](?:[Aa][Rr][Aa][Tt][Oo][Rr])?
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $11 => SEP
                      )?
    
                      \s*
   
                      # ESCAPE attribute
                      (?:
                        [Ee][Ss][Cc][Aa][Pp][Ee]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $12 => ESCAPE
                      )?
   
                      \s*
   
                      # FIELD attribute
                      (?:
                        [Ff][Ii][Ee][Ll][Dd]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $13 => FIELD
                      )?
   
                      \s*
   
                      # SEP attribute
                      (?:
                        [Ss][Ee][Pp](?:[Aa][Rr][Aa][Tt][Oo][Rr])?
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $14 => SEP
                      )?
    
                      \s*
   
                      # ESCAPE attribute
                      (?:
                        [Ee][Ss][Cc][Aa][Pp][Ee]
                        \s*=\s*
                        (
                          (?:"[^"]*")
                          |
                          (?:'[^']*')
                          |
                          (?:[^\s]*)
                        )              # $15 => ESCAPE
                      )?
   
                      \s*

                      (?:
                        (?:--)
                        |
                        (?:\/)
                      )?>
                      (.*)             # $16 => $post - text that comes after the tag

                      $/sxo) {
        my $name = $8;
        if (defined $name and length $name) {
          my $escape = defined $1 ? $1 : defined $4 ? $4 : defined $7 ? $7 : defined $9 ? $9 : defined $12 ? $12 : defined $15 ? $15 : '';
          my $sep = defined $3 ? $3 : defined $6 ? $6 : defined $11 ? $11 : defined $14 ? $14 : '';
          my $field = defined $2 ? $2 : defined $5 ? $5 : defined $10 ? $10 : defined $13 ? $13 : '';
          my $post = defined $16 ? $16 : '';
          $field = '__value__' unless length($field);
          $sep = substr($sep,1,length($sep)-2) if ($sep =~ /^['"]/);
          $escape = "ESCAPE=$escape" if $escape;
          my $join = length $sep ? "<TMPL_UNLESS __last__>$sep</TMPL_UNLESS>" : "";
          $chunk = "<TMPL_LOOP $name><TMPL_VAR NAME=$field $escape>$join</TMPL_LOOP>";
          $chunks[$count] = $chunk.$post;
        }
      }
    }
    $$text_ref  = join('',@chunks);
  };
  return $filter;
}

#
# allow <TMPL_CONSTANT NAME="variable" VALUE="value">
# note this only works for TMPL_VAR's
#
sub tmpl_constant {
  my $filter = sub {
    my $text_ref = shift;
    my $match = qr/<(?:\!--\s*)?[Tt][Mm][Pp][Ll]_[Cc][Oo][Nn][Ss][Tt][Aa][Nn][Tt]\s*[Nn][Aa][Mm][Ee]\s*=(.*?)\s*[Vv][Aa][Ll][Uu][Ee]\s*=(.*?)\s*(?:--)?>/;
    my @taglist = $$text_ref =~ m/$match/g;
    return unless (@taglist > 0);
    my $strip = qr/^(?:'(.*)')|(?:"(.*)")$/;
    my %set_params;
    while (@taglist) {
      my ($t,$v) = (shift @taglist,shift @taglist);
      $t =~ m/$strip/;
      $t = defined $1 ? $1 : defined $2 ? $2 : $t;
      $v =~ m/$strip/;
      $v = defined $1 ? $1 : defined $2 ? $2 : $v;
      $set_params{$t} = $v;
    }
    $$text_ref =~ s/$match//g;
    my $split = qr/(?=<(?:\!--\s*)?[Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]\s+)/;
    my @chunks = split ($split, $$text_ref);
    return unless (@chunks > 0);
    my @output;
    my $chunker = qr/^(?=
                      <(?:!--\s*)?
                      [Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]\s+(?:[Nn][Aa][Mm][Ee]\s*=\s*)?
                      (?:
                        "([^">]*)"
                        |
                        '([^'>]*)'
                        |
                        ([^\s=>]*)
                      )
                      \s*(?:[^>])?(?:--)?>
                      (.*)
                   )/sx;
    foreach my $chunk (@chunks) {
      if ($chunk =~ $chunker) {
        my $name = defined $1 ? $1 : defined $2 ? $2 : defined $3 ? $3 : undef;
        if (defined $name and exists $set_params{$name}) {
          $chunk = $set_params{$name};
          $chunk .= $4 if $4;
        }
      }
      push @output, $chunk;
    }
    $$text_ref = join '',@output;
  };
  return $filter;
}

#
# turns the '\r' line feed to a '\n', for the Mac OS
#
sub mac_os {
  my $filter = sub {
    my $text_ref = shift;
    my $match  = qr/\r/s;
    $$text_ref  =~ s/$match/\n/g;
  };
  return $filter;
}

1;
__END__
=pod

=head1 NAME

HTML::Template::Filters - HTML::Template support module, which
contains some useful filters.

=head1 SYNOPSIS

  use HTML::Template::Filters qw(get_filters);

  my $filters = get_filters(
    HT_FILTER_ALLOW_TRAILING_SLASH,
    HT_FILTER_TMPL_COMMENT,
    HT_FILTER_TMPL_SET,
  );
  my $ht = new HTML::Template(
    filename => 'somefile.tmpl',
    filter => $filters,
  );

=head1 DESCRIPTION

This is a support module for HTML::Template, which contains a
collection of filters that can be applied to a HTML::Template
object.

Filters are applied in the order that they are specified.  As such,
you may need to take this into account in some situations.

=head1 FILTERS

Filters currently available (detailed below):
  HT_FILTER_STRIP_TMPL_NEWLINE_WHITESPACE
  HT_FILTER_VANGUARD_COMPATIBILITY
  HT_FILTER_ALLOW_TRAILING_SLASH
  HT_FILTER_SSI_INCLUDE_VIRTUAL
  HT_FILTER_STRIP_TMPL_NEWLINE
  HT_FILTER_GZIPPED_TEMPLATES
  HT_FILTER_PERCENT_VARIABLES
  HT_FILTER_STRIP_REDUNDANT
  HT_FILTER_STRIP_NEWLINE
  HT_FILTER_TMPL_CONSTANT
  HT_FILTER_TMPL_COMMENT
  HT_FILTER_TMPL_FIXME
  HT_FILTER_MAC_OS

=head2 STRIP_TMPL_NEWLINE_WHITESPACE

Strip any trailing newline and subsequence whitespace from the nextline,
when using closing TMPL_xxx tags.

=head2 VANGUARD_COMPATIBILITY

Implements the H::T option of 'vanguard compatibility'.
See 'PERCENT_VARIABLES'.

Note, doesn't set 'die_on_bad_params=0' (ie you may want/need
to do this yourself).

=head2 ALLOW_TRAILING_SLASH

Enable HTML::Template to support the parsing of a trailing
slash within template tags, as in the following:

  <TMPL_IF somevar />
    <TMPL_VAR anothervar />
  </TMPL_IF />

This may be useful for you if you use a HTML validating
editor, which likes to see empty tags written as <... />.

=head2 SSI_INCLUDE_VIRTUAL

 SSI (server side includes) virtual includes

Translate SSI (server side includes) virtual includes, into
H::T includes.

  <!-- #include virtual="some_include" -->

becomes

  <TMPL_INCLUDE NAME="some_include">

=head2 HT_FILTER_STRIP_TMPL_NEWLINE

Strip any trailing newlines from starting TMPL_xxx tags.

=head2 GZIPPED_TEMPLATES

This filter allows you GZip your templates, which it will
uncompress them, before parsing them, as in:

  -> file stored as:     index.tmpl.gz
  -> parsed by H::T as:  index.tmpl

Note that since the templates are small files already, this
capability, although quite cool, is rather stupid...!

=head2 PERCENT_VARIABLES

Allows you to use syntax like:

  ... %some_variable% ...

within your templates.  You may consider this to be nicer
looking than:

  ... <TMPL_VAR NAME="some_variable"> ...

=head2 STRIP_REDUNDANT

FIXME

=head2 STRIP_NEWLINE

FIXME

=head2 TMPL_CONSTANT

Allows the following syntax within templates:

  <TMPL_SET NAME="template_var" VALUE="some_value">

This will then translate all <TMPL_VAR NAME="template_var">'s
into "some_value".  Doesn't work for <TMPL_LOOP ..>'s as loops
require the template variable to be an array (rather than a
scalar).  Also, dont specify ESCAPE or DEFAULT arguments to the
TMPL_VAR as, they make no sense when used with TMPL_SET.

=head2 TMPL_COMMENT

Allows the TMPL_COMMENT tag so that any text between the
start/end tag is stripped, as in:

  <TMPL_COMMENT>Any text between comments
  is stripped</TMPL_COMMENT>

=head2 TMPL_FIXME

Same as TMPL_COMMENT (makes for searching of FIXME's)

=head2 TMPL_JOIN

Join a TMPL_LOOP param, using the required field and seperator.
Equivalent to Perl join().  The field and seperator are optional.

If using 'scalar_loops' you can easily push a simple Perl array
into the template, which can then be TMPL_JOIN'ed.

Note: this filter requires the use of 'loop_context_vars'.

=head2 MAC_OS

Converts the '\r' Mac OS linefeed character to '\n' so that H::T
can parse the template.

=head1 BUGS

You can send bug reports to the HTML::Template mailing-list. To join
the list, visit:

  http://lists.sourceforge.net/lists/listinfo/html-template-users

=head1 CREDITS

The users of the HTML::Template mailing list contributed the idea
and some patterns for the implementation of this module.

=head1 AUTHOR

Mathew Robertson <mathew@users.sf.net>

=head1 LICENSE

This module is released under the same license that HTML::Template
is released under.

