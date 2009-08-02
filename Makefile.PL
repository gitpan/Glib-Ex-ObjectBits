#!/usr/bin/perl

# Copyright 2007, 2008, 2009 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

WriteMakefile
  (NAME         => 'Glib-Ex-ObjectBits',
   ABSTRACT     => 'Helpers for Glib objects.',
   VERSION_FROM => 'lib/Glib/Ex/SignalIds.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   PREREQ_PM    => {
                    # any version should be ok
                    'Glib' => 0,
                   },

   clean        => { FILES => 'FreezeNotify.html SignalIds.html SourceIds.html TieProperties' },

   EXTRA_META => <<'HERE',
recommends:
    Test::Pod: 1.00
no_index:
    directory:
        - devel
        - inc
        - t
resources:
    homepage: http://user42.tuxfamily.org/glib-ex-objectbits/index.html
    license: http://www.gnu.org/licenses/gpl.html
HERE
  );

#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;
  $makemaker->{'MyMakeMakerExtras_Pod_Coverage'}
    = [ 'Glib::Ex::FreezeNotify',
	'Glib::Ex::SignalIds',
	'Glib::Ex::SourceIds',
	'Glib::Ex::TieProperties,also_private=>[qr/^SCALAR$$/]',
      ];
  return MyMakeMakerExtras::postamble($makemaker) . <<'HERE';

html: FreezeNotify.html SignalIds.html SourceIds.html TieProperties.html

FreezeNotify.html: lib/Glib/Ex/FreezeNotify.pm Makefile
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go \
	  lib/Glib/Ex/FreezeNotify.pm \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3AEx%3A%3A\([^"]*\)!\1.html!' \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3A\([^"]*\)!http://gtk2-perl.sourceforge.net/doc/pod/Glib/\1.html!' \
	  >FreezeNotify.html

SignalIds.html: lib/Glib/Ex/SignalIds.pm Makefile
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go \
	  lib/Glib/Ex/SignalIds.pm \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3AEx%3A%3A\([^"]*\)!\1.html!' \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3A\([^"]*\)!http://gtk2-perl.sourceforge.net/doc/pod/Glib/\1.html!' \
	  >SignalIds.html

SourceIds.html: lib/Glib/Ex/SourceIds.pm Makefile
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go \
	  lib/Glib/Ex/SourceIds.pm \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3AEx%3A%3A\([^"]*\)!\1.html!' \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3A\([^"]*\)!http://gtk2-perl.sourceforge.net/doc/pod/Glib/\1.html!' \
	  >SourceIds.html

TieProperties.html: lib/Glib/Ex/TieProperties.pm Makefile
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go \
	  lib/Glib/Ex/TieProperties.pm \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3AEx%3A%3A\([^"]*\)!\1.html!' \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3A\([^"]*\)!http://gtk2-perl.sourceforge.net/doc/pod/Glib/\1.html!' \
	  >TieProperties.html
HERE
}

exit 0;
