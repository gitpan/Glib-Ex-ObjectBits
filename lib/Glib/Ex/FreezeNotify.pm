# Copyright 2008 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::FreezeNotify;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;

our $VERSION = 1;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = bless [], $class;
  $self->add (@_);
  return $self;
}

sub add {
  my ($self, @objects) = @_;
  if (DEBUG) { print "FreezeNotify on ",join(' ',@objects),"\n"; }
  foreach my $object (@objects) {
    $object->freeze_notify;
    push @$self, $object;
    Scalar::Util::weaken ($self->[-1]);
  }
}

sub DESTROY {
  my ($self) = @_;
  while (@$self) {
    my $object = pop @$self or next; # possible undef by weakening
    if (DEBUG) { print "FreezeNotify thaw $object\n"; }
    $object->thaw_notify;
  }
}

1;
__END__

=head1 NAME

Glib::Ex::FreezeNotify -- freeze notifies in scope guard style

=head1 SYNOPSIS

 use Glib::Ex::FreezeNotify;

 { my $freezer = Glib::Ex::FreezeNotify->new ($obj);
   $obj->set (foo => 123);
   $obj->set (bar => 456);
   # notify_thaw happens when $freezer goes out of scope
 }

 # or multiple objects in one FreezeNotify
 {
   my $freezer = Glib::Ex::FreezeNotify->new ($obj1, $obj2, ...);
   $obj1->set (foo => 999);
   ...
 }

=head1 DESCRIPTION

C<Glib::Ex::FreezeNotify> helps you C<freeze_notify> on given
C<Glib::Object>s, with an automatic corresponding C<thaw_notify> at the end
of the block, no matter how it's exited, whether a C<goto>, early C<return>,
C<die>, etc.

Protection against an error throw leaving the object permanently frozen is
the biggest advantage.  Errors are thrown for a bad property name in a
C<set>, or in all the usual ways if calculating a value (but as of Glib-Perl
1.181 bad value types generally only provoke warnings).

FreezeNotify works by having C<thaw_notify> in the destroy code of a
FreezeNotify object.  General purpose cleanups in this destructor style can
be done with C<Scope::Guard> or C<Sub::ScopeFinalizer>.  FreezeNotify is
specific to C<Glib::Object> freeze/thaw.

FreezeNotify holds only weak references to its objects, so the mere fact
they're due for later thawing doesn't keep them alive if nothing else cares
whether they live or die.  The only real effect of this is that frozen
objects can be garbage collected within the freeze block, instead of having
their life extended to the end of it.

It works to nest freeze/thaws, done either with FreezeNotify or with
explicit C<freeze_notify> calls.  Because GObject simply counts outstanding
freezes there's no need for true nesting; multiple freezes can overlap in
any fashion.  If you're freezing for an extended span then a FreezeNotify
object is a good way not to lose track of your thaws, but anything except a
short freeze for a handful of C<set()> calls is probably unusual.

=head1 FUNCTIONS

=over 4

=item C<< Glib::Ex::FreezeNotify->new ($object,...) >>

Do a C<< $object->freeze_notify >> on each given object and return a
FreezeNotify object which, when it's destroyed, will
C<< $object->thaw_notify >> each.  So if you were thinking of

    $obj->freeze_notify;
    $obj->set (foo => 1);
    $obj->set (bar => 1);
    $obj->thaw_notify;

you instead use

    { my $freezer = Glib::Ex::FreezeNotify->new ($obj);
      $obj->set (foo => 1);
      $obj->set (bar => 1);
    } # automatic thaw when $freezer goes out of scope

=back

=head1 SEE ALSO

L<Glib::Object>, L<Scope::Guard>, L<Sub::ScopeFinalizer>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2007, 2008 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
