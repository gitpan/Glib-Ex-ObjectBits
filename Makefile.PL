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

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Glib-Ex-ObjectBits',
   ABSTRACT     => 'Helpers for Glib objects.',
   VERSION_FROM => 'lib/Glib/Ex/SignalIds.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',

   PREREQ_PM    => {
                    # any version should be ok
                    'Glib' => 0,
                   },

   META_MERGE
   => { resources
        => { homepage => 'http://user42.tuxfamily.org/glib-ex-objectbits/index.html' },
        optional_features
        => { maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'Test::NoWarnings' => 0,
                              },
                },
           },
      },

   MyMakeMakerExtras_Pod_Coverage
   => [ 'Glib::Ex::FreezeNotify',
	'Glib::Ex::SignalIds',
	'Glib::Ex::SourceIds',
	'Glib::Ex::TieProperties,also_private=>[qr/^SCALAR$$/]',
      ],
  );
