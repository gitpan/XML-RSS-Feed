#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

eval { use Test::Pod::Coverage };
plan skip_all => "Test::Pod::Coverage required" unless $INC{'Test/Pod/Coverage.pm'};
eval { all_pod_coverage_ok() };
