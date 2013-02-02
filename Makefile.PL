#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService-Strava',
    VERSION_FROM  => 'lib/WebService/Strava.pm',
    PREREQ_PM     => { 'JSON' => 0, 'Any::Moose' => 0, DateTime => 0, 'Any::URI::Escape' => 0 },
    ABSTRACT_FROM => 'lib/WebService/Strava.pm',
    AUTHOR        => 'Fred Moyer <fred@redhotpenguin.com>',
);
