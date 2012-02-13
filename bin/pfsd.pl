#!/usr/bin/perl

use strict;
use warnings;

use WebService::Strava;
use DateTime;
use DateTime::Duration;

use Getopt::Long;
use Pod::Usage;

# Config options
my $ride;
my ( $help, $man );

pod2usage(1) unless @ARGV;
GetOptions(
    'ride=i' => \$ride,
    'help'   => \$help,
    'man'    => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

my $s = WebService::Strava->new;
$s->ride($ride);

# look through the efforts for Polo Fields segments to find 15 consecutive
# polo field laps, and get the fastest 15 laps
my $polo_segment_id = 432873;

my @pfsd_laps;
my $pfsd_lap = 1;
foreach my $effort ( @{ $s->efforts } ) {

    # fixme - non-contiguous polo field laps
    unless ( $effort->segment->id == $polo_segment_id ) {
        next;
    }

    warn("processed pfsd lap $pfsd_lap");
    $pfsd_lap++;
    push @pfsd_laps, $effort;
}

unless ( scalar(@pfsd_laps) > 14 ) {
    die "not enough laps to calculate pfsd time";
}

# 15 laps means only one TT
my $potential_pfsd_num = scalar(@pfsd_laps) - 14;

my @pfsd_lap_times;

# 2012-01-21T13:42:52Z
foreach my $lap ( 1 .. $potential_pfsd_num ) {

    my $last_lap = $pfsd_laps[ $lap + 13 ];
    my $first    = parse_date( $pfsd_laps[ $lap - 1 ]->start_date_local );
    my $last     = parse_date( $last_lap->start_date_local );

    my $duration = $last->subtract_datetime($first);

    # now add the last lap duration
    $duration->add( seconds => $last_lap->elapsed_time );

    my $total_seconds = $duration->minutes * 60 + $duration->seconds;
    push @pfsd_lap_times, $total_seconds;
}

my @sorted_laps = sort { $a <=> $b } @pfsd_lap_times;

my $fastest_lap = DateTime::Duration->new( seconds => $sorted_laps[0] );
$DB::single = 1;

my $minutes = int( $fastest_lap->seconds / 60 );
my $seconds = $fastest_lap->seconds % 60;

my $miles = 10.2;    # from gps, grab from effort data
my $mph = sprintf( "%3.1f", $miles / ( $fastest_lap->seconds ) * 3600 );

print
"Fastest PFSD TT took $minutes minutes, $seconds seconds, avg speed $mph miles per hour.\n";

sub parse_date {
    my $data = shift;
    my ( $date, $time ) = split( 'T', $data );
    my ( $year, $mon, $day ) = split( '-', $date );
    my ( $hour, $min, $sec ) = split( ':', substr( $time, 0, 8 ) );
    my $dt = DateTime->new(
        year   => $year,
        month  => $mon,
        day    => $day,
        hour   => $hour,
        minute => $min,
        second => $sec
    );
    return $dt;
}

1;

