package WebService::Strava;

use strict;
use warnings;

=head1 NAME

WebService::Strava - Interface to the Strava API version 2

=cut

use Any::Moose;
use Any::URI::Escape;
use JSON;
use LWP::UserAgent;
use Data::Dumper;

has 'ride' => ( is => 'rw', isa => 'Int', required => 0 );

use constant DEBUG => $ENV{STRAVA_DEBUG} || 0;

our $Endpoint = "http://www.strava.com/api/v2";

our $VERSION = 0.01;

our $Ua = LWP::UserAgent->new( agent => join( '_', __PACKAGE__, $VERSION ) );
our $Json = JSON->new->allow_nonref;

=head1 METHODS

=over 4

=item efforts

  $s = WebService::Strava->new;
  $s->ride(3508715);
  $efforts = $s->efforts;

=back

=cut

sub efforts {
    my ( $self, $args ) = @_;

    my $ride = $self->ride || die;
    my $url = "$Endpoint/rides/$ride/efforts";
    warn("query $url") if DEBUG;

    $Ua->timeout(10);
    my $res = $Ua->get($url);

    die "query for $url failed!" unless $res->is_success;

    $res = $Json->decode( $res->content );

    my @efforts;
#    $DB::single = 1;
    foreach my $effort ( @{ $res->{efforts} } ) {

        my $effort_obj = WebService::Strava::Effort->new(
            {
                %{ $effort->{effort} },
                segment =>
                  WebService::Strava::Segment->new( $effort->{segment} )
            }
        );
        push @efforts, $effort_obj;
    }
    return \@efforts;
}

__PACKAGE__->meta->make_immutable;

package WebService::Strava::Effort;

use Any::Moose;

has 'id'               => ( is => 'ro', isa => 'Int', required => 1 );
has 'start_date_local' => ( is => 'ro', isa => 'Str', required => 1 );
has 'elapsed_time'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'moving_time'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'distance'         => ( is => 'ro', isa => 'Str', required => 1 );
has 'segment' =>
  ( is => 'ro', isa => 'WebService::Strava::Segment', required => 1 );

package WebService::Strava::Segment;

use Any::Moose;

has 'id'              => ( is => 'ro', isa => 'Int',      required => 1 );
has 'elev_difference' => ( is => 'ro', isa => 'Num',      required => 1 );
has 'name'            => ( is => 'ro', isa => 'Str',      required => 1 );
has 'climb_category'  => ( is => 'ro', isa => 'Str',      required => 1 );
has 'avg_grade'       => ( is => 'ro', isa => 'Str',      required => 1 );
has 'start_latlng'    => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'end_latlng'      => ( is => 'ro', isa => 'ArrayRef', required => 1 );

1;

=head1 SYNOPSIS

  use WebService::Strava;
  $S = WebService::Strava->new;

  # specify a ride to examine
  $S->ride(331215);

  # get the efforts from the ride
  $efforts = $S->efforts;


=head1 DESCRIPTION

Alpha level API client to the webservice at http://www.strava.com

This module is currently my way of scratching an itch for the
Polo Field Smack Down competition.

=head1 SEE ALSO

L<https://strava.pbworks.com/w/browse>

L<http://polofieldsmackdown.com>

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
