#!/usr/bin/perl -w 
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Lingua::Stem::Snowball::No - Norwegian stemmer
# :: based upon the norwegian stemmer algorithm at snowball.sourceforge.net
#	 by Martin Porter.
# (c) 2001 Ask Solem Hoel <ask@unixmonks.net>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2,
#   *NOT* "earlier versions", as published by the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

package Lingua::Stem::Snowball::No;

use strict;
use vars qw(%cache $VERSION);

$VERSION = 0.5;

# special characters
my $ae = chr(0x91);
my $ao = chr(0x86);
my $oe = chr(0x9b);

# delete the s if a "s ending" is preceeded by one
# of these characters.
my $s_ending = "bcdfghjklmnoprtvyz";

# norwegian vowels.
my $vowels = "aeiouy+$ae$ao$oe";

# ####
# the endings in step 1
# XXX: these must be sorted by length
# to save time we've done it already, you can do it like this:
#	my $bylength = sub {
#		length $a <=> length $b;
#	}
#	@endings = reverse sort $bylength @endings;
my @endings = qw/
	hetenes hetene hetens heten heter endes edes ende
	ande enes erte ast het ets ene ert ane ens ers ede es as
	er ar et en e a s
/;

# the endings in step 2
# XXX: these must be sorted by length, like @endings in step 1.
my @endings2 = qw/
	hetslov slov elov elig eleg els lig eig lov leg ig
/;

%Lingua::Stem::Snowball::No::cache = ();

sub new {
	my $pkg = shift;
	my %arg = @_;
	my $self = {};
	bless $self, $pkg;
	if($arg{use_cache}) {
		$self->use_cache(1);
	}
	return $self;
}

sub use_cache {
	my($self, $use_cache) = @_;
	if($use_cache) {
		$self->{USE_CACHE} = 1;
	}
	return $self->{USE_CACHE};
}

sub stem {
	my ($self, $word) = @_;
	my $orig_word;

	if($self->use_cache()) {
		$orig_word = $word;
		my $cached_word = $cache{$word};
		return $cached_word if $cached_word;
	}

	my ($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
	return $word unless $lslen >= 3;

	# ### STEP 1
	# only need to refresh wlen each time we change the word.
	foreach my $ending (@endings)  {
		my $endinglen = length $ending; # do this once.

		# only continue if the word has this ending at all.
		if(substr($rs, $rslen - $endinglen, $rslen) eq $ending) {
			# replace erte and ert with er
			if($ending eq 'erte' || $ending eq 'ert') { # c)
					$word = substr($word, 0, $wlen - $endinglen);
					$word .= "er";
					($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
					last;
			}
			elsif($ending eq 's') { # b)
				# check if it has a valid "s ending"...
				my $valid_s_ending = 0;
				if($rslen == 1) {
					my $wmr1 = substr($word, 0, $wlen - $rslen);
					if($wmr1 =~ /[$s_ending]$/o) {
						$valid_s_ending = 1;
					}
				}
				else {
					if(substr($rs, $rslen - 2, $rslen - 1) =~ /[$s_ending]/o) {
						$valid_s_ending = 1;
					}
				}
				if($valid_s_ending) {
					# ...delete the last character (which is a s)
					$word = substr($word, 0, $wlen - 1);
					($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
					last;
				}
			}
			else { # a)
				# delete the ending.
				$word = substr($word, 0, $wlen - $endinglen);
				($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
				last;
			}
		}
	}
	return $word unless $lslen >= 3;

	# ### STEP 2
	my $ending = substr($rs, $rslen - 2, $rslen);
	if($ending eq 'dt' || $ending eq 'vt') {
		$word = substr($word, 0, $wlen - 1);
		($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
	}
	return $word unless $lslen >= 3;

	# ### STEP 3
	foreach my $ending (@endings2) {
		my $endinglen = length $ending;
		if(substr($rs, $rslen - $endinglen, $rslen) eq $ending) {
			$word = substr($word, 0, $wlen - $endinglen);
			last;
		}
	}

	if($self->use_cache()) {
		$cache{$orig_word} = $word;
	}
	
	return $word;
}

sub getsides {
    my $word = shift;
    my $wlen = length $word;

    my($ls, $rs) = (undef, undef); # left side and right side.
	
    # ###
    # find the first vowel with a non-vowel after it.
    my($found_vowel, $nonv_position, $curpos) = (-1, -1, 0);
    foreach(split//, $word) {
        if($found_vowel> 0) {
			if(/[^$vowels]/o) {
				if($curpos > 0) {
				$nonv_position = $curpos + 1;
				last;
				}
			}
        }
        if(/[$vowels]/o) {
            $found_vowel = 1;
        }
        $curpos++;
    }

	# got nothing: return false
	return undef if $nonv_position < 0;

    # ###
    # length of the left side must be atleast 3 chars.
    my $leftlen = $wlen - ($wlen - $nonv_position);
    if($leftlen < 3) {
        $ls = substr($word, 0, 3);
        $rs = substr($word, 3, $wlen);
    }
    else {
        $ls = substr($word, 0, $leftlen);
        $rs = substr($word, $nonv_position, $wlen);
    }
    return($ls, $rs, $wlen, length $ls, length $rs);
}

1;

__END__
=head1 NAME

Lingua::Stem::Snowball::No - Porters stemming algorithm for Norwegian

=head1 SYNOPSIS

  use Lingua::Stem::Snowball::No
  my $stemmer = new Lingua::Stem::Snowball::No (use_cache => 1);

  foreach my $word (@words) {
	my $stemmed = $stemmer->stem($word);
	print $stemmed, "\n";
  }

=head1 DESCRIPTION

The stem function takes a scalar as a parameter and stems the word
according to Martin Porters Norwegian stemming algorithm,
which can be found at the Snowball website: L<http://snowball.sourceforge.net/>.

It also supports caching if you pass the use_cache option when constructing
a new L:S:S:N object.

=head2 EXPORT

Lingua::Stem::Snowball::No has nothing to export.

=head1 AUTHOR

Ask Solem Hoel, E<lt>ask@unixmonks.netE<gt>

=head1 SEE ALSO

L<perl>. L<Lingua::Stem::Snowball>. L<Lingua::Stem>. L<http://snowball.sourceforge.net>.

=cut
~

