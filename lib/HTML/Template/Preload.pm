package HTML::Template::Preload;
our $VERSION = '0.01';

=head1 NAME

HTML::Template::Preload - Preload HTML::Template templates into cache.

=head1 SYNOPSIS

Preload HTML::Template templates into cache:

  use HTML::Template::Preload qw(-path => '/some/path', cache => 1);

=head1 DESCRIPTION

HTML::Template supports the concept of a 'cache' which is use to hold
pre-parsed templates.  At the same time, HTML::Template supports a
number of different types of caching mechanisms.

In a Apache/ModPerl environment, there may be a small but significant
performance benefit having Apache pre-load the templates, so as to
avoid needing the Apache-child-instances parse the templates, as they
will have inherited the parent instance cache.  To make this work, you
would call this module from your startup.pl in Apache/mod_perl.

Thus this module pre-parses all the templates, then places them into
the selected cache.

=head1 USAGE

You can use this module in one of two ways, either:
 a) In your 'use' statement, provide it with your
    HTML::Template cache info, as in:

   use HTML::Template::Preload qw(
     -path => '/some/path',
     -path => 'some/other/path',
     cache => 1,
   );

 b) Or inside your program code:

   use HTML::Template::Preload;
   ...
   my %ht_options;
   $ht_options{path} = \@search_paths;
   $ht_options{global_vars} = 1;
   $ht_options{strict} = 0;
   $ht_options{cache} = 1;
   ...
   HTML::Template::Preload->preload(%ht_options);

HTML::Template::Preload takes a hash of named arguments:

  -extension
          The filename extension you use for all of your
          templates.  Defaults to: .tmpl

  -file   Name a specific file or files to cache.  Takes
          a scalar or an array of filenames.  This uses
          the search path to find the template files; as
          implemented by HTML::Template.

  -path   Name a specific search path or paths.  Takes a
          scalar or an array of paths.  This will usually
          be the same list as would be passed to the 'path'
          argument to HTML::Template.

  -function
          sub's to functions that need to be registered
          for HTML::Template::Expr.

All other arguments (that dont begin with a '-') are passed
to the HTML::Template caching-instance.

Note that you dont need to specify the "-xxx" variation of
these arguments -> you can simply use the same hash-options
as given to HTML::Template.  The point of these extra options
is to allow for explicitly caching a specific template.

=cut

use strict;
use warnings FATAL => 'all';
use utf8;
use Exporter;
use Carp;
use HTML::Template::ESCAPE;
use HTML::Template::ESCAPE::URL;
use HTML::Template::ESCAPE::JS;
use HTML::Template::ESCAPE::TEXT;
use HTML::Template::ESCAPE::STRIP_NEWLINE;
use HTML::Template::ESCAPE::DOUBLE_QUOTE;
use HTML::Template;
use HTML::Template::Expr;
use HTML::Template::Filters;
use HTML::Template::Bundle;
use vars qw($DEBUG);
$DEBUG = 0;

# Helper functions
{
  sub left {
    my ($string, $num) = @_;
    $num = 1 unless defined $num;
    return substr($string,0,$num);
  }

  sub find {
    my ($path, $regex_pattern) = @_;
    unless (-d $path) {
      if ($regex_pattern) {
        return [ $path ] if ($path =~ /$regex_pattern/);
        return undef;
      } else {
        return [ $path ];
      }
    }
    return undef if ($path =~ /.*\.$/ or $path =~ /.*\.\.$/ );

    return undef unless (opendir(DIR, $path));
    my @entries;
    while ($_ = readdir(DIR)) {
      push @entries, $_;
    }
    closedir(DIR);

    my @files;
    foreach my $entry (@entries) {
      my $files = find($path .'/'. $entry,$regex_pattern);
      next unless $files;
      push @files, @$files;
    }
    return \@files if (@files > 0);
    return undef;
  }

  sub strip_path {
    my ($path,$files) = @_;
    my @files;
    foreach my $file (@$files) {
      s/^$path\///;
      push @files, $file;
    }
    return \@files if (@files > 0);
    return undef;
  }

  sub get_value {
    my $val = shift;
    $val =~ s/,$//;
    if ($val =~ /^(?:
                    "([^"]*)"   # double-quoted value
                    |
                    '([^']*)'   # single-quoted value
                  )$/sx) {
      $val = $1 ? $1 : $2 ? $2 : "";
    }
    return $val;
  }

  our $DIE_FROM_CALLER = 0;

  sub die_from_caller {
    if ($DEBUG) {
      require Carp;
      Carp::confess "Locale::MakePhrase detected an error:";
    }
    my $caller_count = 0;
    while (1) {
      $caller_count++;
      my $caller = caller($caller_count);
      last if (!defined $caller || $caller !~ /^HTML::Template/);
    }
    my ($caller,$file,$line) = caller($caller_count);
    if (defined $caller) {
      for (1..$DIE_FROM_CALLER) {
        $caller_count++;
        ($caller,$file,$line) = caller($caller_count);
        last unless defined $caller;
      }
    }
    $caller = "main" unless defined $caller;
    $file = "(unknown)" unless defined $file;
    $line = "(unknown)" unless defined $line;
    my $msg = "Fatal: ". caller() ." detected an error in: $caller$/";
    $msg .= "File: $file$/";
    $msg .= "Line: $line$/";
    @_ and $msg .= join (" ", @_) . $/;
    die $msg;
  }

  sub resolve_function {
    my $val = shift;
    return $val if (HTML::Template::reftype($val) eq 'CODE');
    my $caller_count = 0;
    while (1) {
      $caller_count++;
      my $caller = caller($caller_count);
      last if (!defined $caller || $caller !~ /^HTML::Template/);
    }
    my $caller = caller($caller_count) || "main";
    return "$caller->$val" if ($caller->can($val));
    die_from_caller("Cannot find a reference to function: $val");
  }
}

# provide facility to allow use of module within 'use' statemtent
sub import {
  return unless (@_ > 1);
  my $pkg = shift;
  my $extension = '.tmpl';
  my @paths;
  my @files;
  my @expr_functions;
  my %ht_options;

  # get arguments
  foreach my $arg (@_) {
    next unless $arg;
    $arg =~ s/,$//;
    next unless $arg;
    croak "Incorrect syntax for '$arg'" unless (@_ > 1);
    shift;
    my $val = shift;
    if (left($arg) eq '-') {
      my $type = substr($arg,1);
      my $ref = HTML::Template::reftype($val);

      if (left($type,9) eq 'extension') {
        $extension = get_value($val);

      } elsif (left($type,4) eq 'path') {
        if ($ref eq 'ARRAY') {
          push @paths, @$val,
        } else {
          push @paths, get_value($val);
        }

      } elsif (left($type,4) eq 'file') {
        if ($ref eq 'ARRAY') {
          push @files, @$val;
        } else {
          push @files, get_value($val);
        }

      } elsif (left($type,) eq 'function') {
        if ($ref eq 'ARRAY') {
          foreach (@$val) {
            push @expr_functions, resolve_function($_);
          }
        } else {
          push @expr_functions, resolve_function($val);
        }
      } else {
        croak "Unknown argument: $arg";
      }
    } else {
      $ht_options{$arg} = $val;
    }
  }

  # register any Expr functions
  foreach my $expr_func (@expr_functions) {
    HTML::Template::Expr->register_function($expr_func);
  }

  # Since we are trying to preload stuff, we need to make sure
  # a cache option is actually enabled...
  if (exists $ht_options{cache} or
          exists $ht_options{share_cache} or
          exists $ht_options{double_cache} or
          exists $ht_options{blind_cache} or
          exists $ht_options{file_cache} or
          exists $ht_options{double_file_cache} ){
    # If no files or paths specified, grab the paths from the H::T
    # options, if we can...
    if (@paths == 0 and @files == 0) {
      exists $ht_options{path} and @paths = @{$ht_options{path}};
    }
  
    # Lookup the files in the specified paths
    if (@paths > 0) {
      print STDERR "Preloading files from ". scalar(@paths) ." paths.\n" if $DEBUG > 1;
      my $file_spec = undef;
      if (defined $extension and length $extension) {
        $file_spec = $extension .'$';
        $file_spec =~ s/\./\\./g;
      };
      my $files;
      foreach my $path (@paths) {
        print STDERR "Preloading templates from: $path" if $DEBUG > 3;
        $files = find ($path, $file_spec);
        next unless $files;
        $files = strip_path ($path, $files);
        next unless $files;
        push @files, @$files;
      }
    }
  
    # Try loading the templates into the cache
    (@files == 0) and croak "Failed to load any templates.";
    foreach my $file (@files) {
      print STDERR "Preloading template: $file\n" if $DEBUG > 2;
      eval {
        my $ht = HTML::Template->new(
          filename => $file,
          %ht_options,
        );
      };
      $@ and croak "Error caching file: $file.";
    }
    print STDERR "Preloaded ". scalar(@files) ." templates\n" if $DEBUG;

  } elsif (@expr_functions == 0) {
    croak "Using $pkg, while not enabling any cache, is pointless.\nEither enable a cache, or disable HTML::Tempate::Preload.";
  }

}

# Allow static function call
#sub preload { shift->import(@_) }
no warnings 'once';
*preload = *import;
use warnings 'once';

1;
__END__

=head1 AUTHOR

Mathew Robertson (mathew@users.sf.net)

=head1 LICENSE

This module is released under the same license as the license the
HTML::Template is released under.

=cut
