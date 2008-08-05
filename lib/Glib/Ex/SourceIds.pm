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

package Glib::Ex::SourceIds;
use strict;
use warnings;
use Glib;
use Scalar::Util;

our $VERSION = 2;

sub new {
  my ($class, @ids) = @_;
  return bless \@ids, $class;
}

sub DESTROY {
  my ($self) = @_;
  $self->remove;
}

# g_source_remove() returns false if it didn't find the ID, so no need for
# any check here whether it's already removed (for instance by a false
# return from the handler function).
#
sub remove {
  my ($self) = @_;
  while (my $id = pop @$self) {
    Glib::Source->remove ($id);
  }
}

1;
__END__

=head1 NAME

Glib::Ex::SourceIds -- hold Glib main loop source IDs

=head1 SYNOPSIS

 use Glib::Ex::SourceIds;
 my $ids = Glib::Ex::SourceIds->new
             (Glib::Timeout->add (1000, \&do_timer),
              Glib::Idle->add (\&do_idle));

 # removed when ids object destroyed
 $ids = undef;
        
=head1 DESCRIPTION

C<Glib::Ex::SourceIds> holds a set of Glib main loop source IDs.  When the
SourceIds is destroyed it removes those IDs.

This is designed to make life easier when keeping sources installed for a
limited period, such as an IO watch while communicating on a socket, or a
timeout on an action.  Often such things will be associated with a
C<Glib::Object> (or just a Perl object), though they don't have to be.

=head1 FUNCTIONS

=over 4

=item C<< $sobj = Glib::Ex::SourceIds->new ($id,$id,...) >>

Create and return a SourceIds object holding the given C<$id> main loop
source IDs (integers).

SourceIds doesn't install sources.  You do that with
C<< Glib::Timeout->add >>, C<< Glib::IO->add_watch >> and
C<< Glib::Idle->add >> in the usual ways and all the various options, then
pass the resulting ID to SourceIds to look after.  Eg.

    my $ids = Glib::Ex::SourceIds->new
                (Glib::Timeout->add (1000, \&do_timer));

You can hold any number of IDs in a SourceIds object.  Generally if you want
things installed and removed at different points in the program then you'll
use separate SourceIds objects for each (or each group).

=item C<< $ids->remove() >>

Remove the source IDs held in C<$ids> from the main loop, using
C<< Glib::Source->remove >>, if not already removed (for instance by a
"false" return from the handler code).  This remove is done when C<$ids> is
garbage collected, but you can do it explicitly sooner if desired.

=back

=head1 SEE ALSO

L<Glib::MainLoop>, L<Glib::Ex::SignalIds>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2008 Kevin Ryde

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
