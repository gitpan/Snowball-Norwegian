#!/usr/bin/perl

use strict;
use Lingua::Stem::Snowball::No;

my $stemmer = new Lingua::Stem::Snowball::No(use_cache => 1);
while(my $line = <>) {
	chomp $line;
	foreach my $word (split /\s+/, $line) {
		my $stemmed = $stemmer->stem($word);
		print $stemmed, "\n";
	}
}
undef $stemmer;
