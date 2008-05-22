# Glib::Ex::SignalIds tests.

# Copyright 2008 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More tests => 11;
use Glib::Ex::SignalIds;

package MyClass;
use strict;
use warnings;
use Glib;
use Glib::Object::Subclass
  Glib::Object::,
  properties => [ Glib::ParamSpec->int
                  ('myprop',
                   'myprop',
                   'Blurb',
                   0, 100, 50,
                   Glib::G_PARAM_READWRITE) ];

package main;

# the SignalIds object gets garbage collected when weakened
{
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj, $obj->signal_connect (notify => sub {}));
  require Scalar::Util;
  Scalar::Util::weaken ($sigs);
  is (defined $sigs ? 'defined' : 'not defined',
      'not defined');
}

# the target object gets garbage collected when weakened
{
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj, $obj->signal_connect (notify => sub {}));
  require Scalar::Util;
  Scalar::Util::weaken ($obj);
  is (defined $obj ? 'defined' : 'not defined',
      'not defined',
      'target object garbage collected when weakened');
}

# the held signal is disconnected when the SignalIds destroyed
{
  my $signalled;
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj, $obj->signal_connect (notify => sub { $signalled = 1 }));

  $signalled = 0;
  $obj->set(myprop => 1);
  ok ($signalled);

  $sigs = undef;

  $signalled = 0;
  $obj->set(myprop => 1);
  ok (! $signalled);
}

# two held signals disconnected
{
  my $signalled1;
  my $signalled2;
  my $obj = MyClass->new;
  my $sigs = Glib::Ex::SignalIds->new
    ($obj,
     $obj->signal_connect (notify => sub { $signalled1 = 1 }),
     $obj->signal_connect (notify => sub { $signalled2 = 1 }));

  $signalled1 = 0;
  $signalled2 = 0;
  $obj->set(myprop => 1);
  ok ($signalled1);
  ok ($signalled2);

  $sigs = undef;

  $signalled1 = 0;
  $signalled2 = 0;
  $obj->set(myprop => 1);
  ok (! $signalled1);
  ok (! $signalled2);
}

# SignalIds can cope if held signal is disconnected elsewhere
{
  my $obj = MyClass->new;
  my $id = $obj->signal_connect (notify => sub { });
  my $sigs = Glib::Ex::SignalIds->new ($obj, $id);

  $obj->signal_handler_disconnect ($id);
  $sigs = undef;
}

eval { Glib::Ex::SignalIds->new (123); };
ok ($@, 'notice number as first arg');

eval { Glib::Ex::SignalIds->new ([]); };
ok ($@, 'notice ref as first arg');

eval { Glib::Ex::SignalIds->new (bless [], 'bogosity'); };
ok ($@, 'notice wrong blessed as first arg');


exit 0;

