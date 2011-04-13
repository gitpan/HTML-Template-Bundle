#!/bin/sh
`perl -e 1 > /dev/null 2>&1` && eval 'exec perl -x $0 $*' || echo "Perl cannot be found";
cat<<__END__>/dev/null
#!perl

=head1 NAME

tmpl_test.pl - test parse the templates used in a HTML::Template
invocation.

=head1 SYNOPSIS

This script will test the validity of a template that is going to
be used by an invocation of HTML::Template.  Example:

  tmpl_test.pl somefile.tmpl

or:

  tmpl_test.pl -r

Recursively finds templates, searching from the current directory,
then test-parsing each template file validating the syntax.

=head1 DESCRIPTION

While developing templates for use in your application, you may find
that you end up using a development model where you spend a lot of
time making changes to templates, then trying to generate output with
them, just to find out that you made an error in one (or more) of the
templates that you were just working on.  This often results in lots
of small time wastages since your development environment may be setup
to test your end-to-end framework, rather than individual changes.

Also, if your are modifying a number of templates in one sitting, often
you will make a mistake, which is hard to detect and analyse, using a
normal HTML::Template invocation.

The aim of this script is simply to test-parse template files, so as
to catch common TMPL-type syntax errors.  This test-parse will find
most errors in each template file, thus it allows you to test-parse
included files, individually, rather than simply invoking HTML::Template
on the top-level template.

=head1 USAGE

tmpl_test.pl takes the following arguments (using defaults if not specified):

 -r   Recursively search for templates from current directory.

 -t   Specify a file specification for recursive searches,
      defaults to: *.tmpl

 -s   Specify a directory to be added to H::T's search path,
      defaults to including the current directory.

 -f   Specify the name of a template file to test.  You can
      specify multiple '-f's on the command line; each
      template will be tested in order of specification.

 -o   Show outout of template parse (this is probably only
      useful when testing a single template.

 -p   Sets params so that they can be used within template
      tests.  Use multiple -p's to add more params.
      Syntax: -p "key" "value"

Any argument that doesn't begin with a '-', is assumed to be a filename,
so that you can do something like:

  tmpl_test.pl include/template1.tmpl template2.tmpl

Note that '-r' overrides any files specified on the command line.

=head1 CAVEATS

This module uses HTML::Template::Expr to do the actual test.
If H::T or H::T::E themselves cannot detect an error within
a template, then neither can this script.

=head1 AUTHORS

Mathew Robertson <mathew@users.sf.net>

=head1 LICENCE

Copyright (C) 2004 Mathew Robertson

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 (or any
later version) as published by the Free Software Foundation.

=cut

use strict;
use warnings;
use Cwd;
$| = 1;

my $usage = <<EOF;
usage: tmpl_test.pl [-h] [-r] [-s directory] [-f ][template_file]
       -h   Show this help screen
       -r   Recursively search from current directory, for any templates.
            Note that '-r' overrides any files specified on the command line.
       -t   Specify a file specification for recursive searches, defaults to: *.tmpl
       -s   Specify a directory to be added to H::T's search path
       -f   Specify the name of a template file to test; you can specify multiple '-f's
            Any argument that doesn't begin with a '-' is assumed to be a filename.
       -o   Show output of template parse.
       -p   Set params for use within template tesing. Syntax: -p "key" "value"
EOF

sub usage {
  print $usage;
  exit(1);
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
  foreach (@entries) {
    my $files = find($path .'/'. $_,$regex_pattern);
    next unless $files;
    push @files, @$files;
  }
  return \@files;
}

sub strip_path {
  my ($path,$files) = @_;
  my @files;
  foreach (@$files) {
    s/^$path\///;
    push @files, $_;
  }
  return \@files;
}

sub exit_unless {
  my ($file) = @_;
  unless (-f $file) {
    print STDERR "Not found: $file\n";
    exit(1);
  }
}


## get arguments from command line ###############################
usage() if (@ARGV < 1 or $ARGV[0] eq '-h');
my $files;
my $recursive = 0;
my $file_spec = '\.tmpl$';
my @search_path;
push @search_path, cwd();
my $show_output = 0;
my %params;

for (my $i = 0; $i < @ARGV; $i++) {
  next unless (defined $ARGV[$i]);
  my $arg = $ARGV[$i];
  if ($arg eq '-f') {
    $i++;
    usage() unless (defined $ARGV[$i]);
    exit_unless ($ARGV[$i]);
    push @$files, $ARGV[$i];
  } elsif ($arg eq '-r') {
    $recursive = 1;
  } elsif ($arg eq '-t') {
    $i++;
    usage() unless (defined $ARGV[$i]);
    $file_spec = $ARGV[$i];
  } elsif ($arg eq '-s') {
    $i++;
    usage() unless (defined $ARGV[$i]);
    push @search_path, $ARGV[$i];
  } elsif ($arg eq '-o') {
    $show_output = 1;
  } elsif ($arg eq '-p') {
    $i++;
    usage() unless (defined $ARGV[$i] && defined $ARGV[$i+1]);
    $params{$ARGV[$i]} = $ARGV[$i+1];
    $i++;
  } elsif ($arg !~ /^-/) {
    exit_unless ($arg);
    push @$files, $arg;
  } else {
    usage();
  }
}

## find templates ##############################################
if ($recursive) {
  $file_spec = undef unless length $file_spec;
  $files = find (cwd(),$file_spec);
  unless (@$files > 0) {
    print STDERR "No files found, for recursive lookup\n.";
    exit(1);
  }
  $files = strip_path(cwd(),$files);
} else {
  usage() unless (@$files > 0);
}

## test parse each template ####################################
require HTML::Template::Expr;
my $err;
my $ht;
my $output;
my ($param,$value);

foreach my $file (@$files) {
  print "Testing: $file ...";

  eval {
    $ht = new HTML::Template::Expr(
      path => \@search_path,
      filename => $file,
      die_on_bad_param => 0,
      strict => 0,
      global_vars => 1,
    );
    while (($param,$value) = each %params) {
      $ht->param($param,$value);
    }
  };
  if ($@) {
    $err = $@;
    $err =~ s/^.*HTML::Template->new\(\)\s+:\s+//;
    $err =~ s/\s+at\s+\/.*$//s;
  }
  if ($err) {
    print STDERR "$err\n";
    exit(1);
  } elsif (! $ht) {
    print STDERR "Failed making HTML::Template object\n";
    exit(1);
  }

  eval {
    $output = $ht->output();
  };
  if ($@) {
    print STDERR "Failed generating output.\n";
    exit(1);
  }

  print "ok\n";
  undef $ht;

  $show_output && print "\n$output\n";
}

exit(0);
__END__
