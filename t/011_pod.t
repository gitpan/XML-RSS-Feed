#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

eval { use Test::Pod };
plan skip_all => "Test::Pod required" unless $INC{'Test/Pod.pm'};
eval { all_pod_files_ok() };
