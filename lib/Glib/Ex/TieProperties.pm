# Copyright 2009 Kevin Ryde

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


package Glib::Ex::TieProperties;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;

our $VERSION = 4;

use constant DEBUG => 0;

sub new {
  tie my(%hash), shift, @_;
  return \%hash;
}
sub in_object {
  my ($class, $obj, %option) = @_;
  $option{'weak'} = 1;
  my $field = delete $option{'field'};
  if (! defined $field) { $field = 'property'; }
  tie my(%hash), $class, $obj, %option;
  return ($obj->{$field} = \%hash);
}
sub object {
  return $_[0]->[0];
}

# $self is an arrayref, created as one element just for _OBJ, with a second
# for _KEYS on-demand..
#
# $self->[_OBJ] is the target Glib::Object
#
# $self->[_KEYS] is an arrayref of keys (string property names) to return
# from FIRSTKEY/NEXTKEY, with NEXTKEY shifting off one per call.
#
use constant { _OBJ => 0,
               _KEYS => 1 };

# Think about:
#   error_on_fetch
#   error_on_store
#
sub TIEHASH {
  my ($class, $obj, %option) = @_;
  (ref $obj) || croak "$class needs an object to tie";
  my $self = bless [ $obj ], $class;
  if ($option{'weak'}) {
    require Scalar::Util;
    Scalar::Util::weaken ($self->[_OBJ]);
  }
  return $self;
}
sub FETCH  {
  my ($self, $key) = @_;
  my $obj = $self->[_OBJ] || return undef; # if weakened away
  my $pspec = $obj->find_property ($key) || return undef;
  return ($pspec->{'flags'} >= 'readable'
          ? $obj->get_property($key)
          : undef); # not readable
}
sub STORE  {
  my ($self, $key, $value) = @_;
  my $obj = $self->[_OBJ] || return;  # do nothing if weakened away
  $obj->set_property ($key, $value);
}
sub EXISTS {
  my ($self, $key) = @_;
  my $obj = $self->[_OBJ] || return 0;  # if weakened away
  return defined ($obj->find_property($key));
}
sub DELETE { croak 'Cannot delete object properties' }
{ no warnings;
  *CLEAR = \&DELETE; }

sub FIRSTKEY {
  my ($self) = @_;
  my $obj = $self->[_OBJ] || return undef;  # if weakened away
  @{$self->[_KEYS]} = map {$_->{'name'}} $obj->list_properties;
  goto &NEXTKEY;
}
sub NEXTKEY {
  return shift @{$_[0]->[_KEYS]};
}

# true if at least one property
sub SCALAR {
  my ($self) = @_;
  # it's pretty wasteful getting a full list of pspecs then throwing them
  # away, but g_object_class_list_properties() is about the only way to
  # check if there's any, and $obj->list_properties() is the only interface
  # to that function.
  my $obj;
  return (($obj = $self->[_OBJ])  # false if weakened away
          && defined (($obj->list_properties)[0]));
}

1;
__END__

=head1 NAME

Glib::Ex::TieProperties -- tied hash for object property access

=head1 SYNOPSIS

 use Glib::Ex::TieProperties;
 my %hash;
 tie %hash, 'Glib::Ex::TieProperties', $object;

 # or an anonymous hashref
 my $href = Glib::Ex::TieProperties->new ($object);

=head1 DESCRIPTION

C<Glib::Ex::TieProperties> accesses properties of a given C<Glib::Object>
through a tied hash.  The keys are the property names and fetching and
storing values operates on the property values.

If you're just getting and setting properties then you're best off simply
calling the C<get> and C<set> methods, but one good use for a tie is to
apply C<local> settings within a block, to be undone by a C<set> back to
their previous values no matter how the block is left (C<goto>, C<return>,
C<die>, etc).

    {
      tie my(%aprops), 'Glib::Ex::TieProperties', $adjustment;
      local $aprops{'page-increment'} = 100;
      do_page_up();
    }

With C<new> to create a tied anonymous hashref a single long C<local>
expression is possible

    # usually allow-shrink is not a good idea, have it temporarily
    local Glib::Ex::TieProperties->new($toplevel)->{'allow-shrink'} = 1;
    some_resize();

You can even be creative with hash slices for multiple settings in one
statement.

    # how big is $toplevel if $widget width is forced
    {
      tie my(%wprops), 'Glib::Ex::TieProperties', $widget;
      local @wprops{'width-request','height-request'} = (100, 200);
      my $req = $toplevel->size_request;
    }

Like most C<tie> things, TieProperties tends to be better in concept than
actuality.  There's relatively few object properties that you want to make
block-scoped changes to, and things like getting all property names or
values must generally pay attention to whether they're read-only,
write-only, etc, so a naive iteration is rarely much good.

=head2 Details

The property names for the keys are anything accepted by C<get_property>,
C<find_property>, etc.  This means underscores "_" can be used in place of
dashes "-", for example C<border_width> is an alias for C<border-width>.

The C<keys> and C<each> operations return just the dashed names.  Currently
they return properties in the same order as C<< $obj->list_properties >>
gives, but don't depend on that.

Getting a non-existent property name returns C<undef>, the same as a
non-existent entry in an ordinary Perl hash.  C<exists> tests for a key with
C<find_property>.

If a property exists but is not readable then fetching returns C<undef>.  An
error in that case would also be possible, but that would make it impossible
to use C<each> to iterate through an object with any write-only properties.
Storing to a non-existent property throws an error, a bit like a restricted
hash (see L<Hash::Util>).  Storing to a read-only property likewise throws
an error.

=head1 FUNCTIONS

=over 4

=item C<< tie %h, 'Glib::Ex::TieProperties', $object >>

=item C<< tie %h, 'Glib::Ex::TieProperties', $object, key=>value,... >>

Tie a hash C<%h> to C<$object> so that C<%h> accesses the properties of
C<$object>.  The keys of C<%h> are property names, the values the settings
in C<$object>.

Optional key/value pairs in the C<tie> set the following options

=over 4

=item weak (boolean, default false)

Hold only a weak reference to C<$object>.

    tie %h, 'Glib::Ex::TieProperties', $object, weak=>1;

If C<$object> is garbage collected while the tied C<%h> still exists then
C<%h> gives C<undef> for all fetches, does nothing for all stores, C<exists>
is always false, and C<keys> and C<each> are empty.

Doing nothing for stores is designed to ignore C<local> or similar cleanups
which might still be pending.  If no-one else cared whether the object lived
or died then restoring settings can't be too important.

=back

=item C<< $hashref = Glib::Ex::TieProperties->new ($object) >>

=item C<< $hashref = Glib::Ex::TieProperties->new ($object, key=>value, ...) >>

Create and return a new anonymous hashref tied to the properties of
C<$object>.  This is the same as

    tie my(%hash), 'Glib::Ex::TieProperties', $object;
    $hashref = \%hash;

The difference between using a hash or hashref is normally just a matter of
which style you prefer.  With the C<my> worked into the C<tie> call it can
be a one line setup either way.

=item C<< Glib::Ex::TieProperties->in_object ($object) >>

=item C<< Glib::Ex::TieProperties->in_object ($object, key=>value, ...) >>

Establish a tied hash within C<$object> accessing its properties.  The
default is a field called C<property>, so for instance

    Glib::Ex::TieProperties->in_object ($object)
    $object->{'property'}->{'tooltip-text'} = 'Hello.';

The optional key/value pairs are passed to the tie constructor as above, and
in addition

=over 4

=item field

Set the field name within C<$object> which becomes the tied hash.  The
default "property" is designed to be readable and not too likely to clash
with other things, but you can control it with the C<field> parameter,

    Glib::Ex::TieProperties->in_object ($object, field => 'xyzzy')
    print $object->{'xyzzy'}->{'border-width'};

=back

The C<weak> parameter described above is always set on a tied hash
established by C<in_object> so it doesn't create a circular reference which
would keep C<$object> alive forever.

=back

=head1 TIED OBJECT FUNCTIONS

The tie object associated with the hash, which is returned by the C<tie> or
obtained later with C<tied>, has the following methods.

=over 4

=item C<< $tobj->object >>

Return the underlying object (C<Glib::Object> object) being accessed by
C<$tobj>.

    my %hash
    my $tobj = tie %hash, 'Gtk2::Ex::TiedListColumn', $object;
    ...
    print $tobj->object;  # the original $object

Or getting the C<$tobj> later with C<tied>,

    my %hash
    tie %hash, 'Gtk2::Ex::TiedListColumn', $object;
    ...
    my $tobj = tied(%hash);
    my $object = $tobj->object;
    $object->show;

=back

=head1 OTHER NOTES

The C<Glib> builtin C<< $object->tie_properties >> feature does a very
similar thing.  But it works instead by populating C<$object> with
individual tied field objects for the properties.
C<Glib::Ex::TieProperties> is separate from the object and may use a bit
less memory since it's one object instead of many.  Being separate however
means an extra variable, or an extra indirection for the C<in_object> style
above.

=head1 SEE ALSO

L<Glib>, L<Glib::Object>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2009 Kevin Ryde

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
