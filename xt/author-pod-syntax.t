#!/usr/bin/perl
use strict; 
use warnings;

# Windows:  SET AUTHOR_TESTING=1
BEGIN {
  unless ($ENV{'AUTHOR_TESTING'}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

# This file was automatically generated by Dist::Zilla::Plugin::PodSyntaxTests.
use Test::More;
use Test::Pod 1.41;

all_pod_files_ok();

1;