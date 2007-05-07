#!/usr/local/bin/perl
# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );
use vars qw($VERSION);
$VERSION = 1.1;
eval "use Test::Pod 1.00"; ## no critic
if ($EVAL_ERROR) {
    plan skip_all => 'Test::Pod 1.00 required for testing POD';
}
all_pod_files_ok( );
