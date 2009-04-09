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
resources:
    homepage: http://www.geocities.com/user42_kevin/glib-ex-objectbits/index.html
    license: http://www.gnu.org/licenses/#GPL
HERE
  );

sub MY::postamble {
  return <<'MAKE_FRAG';

LINT_FILES = $(TO_INST_PM) t/*.t
# examples/*.pl devel/*.pl
lint:
	perl -MO=Lint $(LINT_FILES)
pc:
	-podchecker $(LINT_FILES)
	perlcritic $(LINT_FILES)
unused:
	for i in $(LINT_FILES); do perl -Mwarnings::unused -I lib $$i; done

myman:
	mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

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

# find files in the dist with mod times this year, but without this year in
# the copyright line
copyright-years-check:
	year=`date +%Y`; \
	tar tvfz Glib-Ex-ObjectBits-$(VERSION).tar.gz \
	| egrep '$$year-|debian/copyright' \
	| sed 's:^.*Glib-Ex-ObjectBits-$(VERSION)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat \
	      | t/pod.t \
	      | COPYING | MANIFEST* | SIGNATURE | META.yml) \
	      continue ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! grep -q "Copyright.*$$year" $$f; then \
	      echo "$$i:1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

debug-constants-check:
	if egrep -n 'DEBUG => [^0]' $(TO_INST_PM); then exit 1; else exit 0; fi


diff-prev:
	rm -rf diff.tmp
	mkdir diff.tmp
	cd diff.tmp \
	&& tar xfz ../$(NAME)-`expr $(VERSION) - 1`.tar.gz \
	&& tar xfz ../$(NAME)-$(VERSION).tar.gz
	-cd diff.tmp; diff -ur $(NAME)-`expr $(VERSION) - 1` \
	                       $(NAME)-$(VERSION) >tree.diff
	-less diff.tmp/tree.diff
	rm -rf diff.tmp

MAKE_FRAG
}
