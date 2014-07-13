#!/usr/bin/perl
use strict;
use warnings;
#use Geo::Calc;



require "/home/ubuntu/Subroutines/debug.pm";
require "/home/ubuntu/Subroutines/geoCalc.pm";


our $debug = 1;          # 0 - no debug, 1-is terminal STOUT, 2-STOUT to Log/main.log
#debug("testing debug");



my $startLat;
my $startLon;
my $finishLat;
my $finishLon;




		open my $STARTPOS, "/home/ubuntu/GPS/lastGPS.dat" or die "Could not open STARTLAT $!";
                my $startPos = (<$STARTPOS>);
		my @startPosArray = split(/,/,$startPos);
		my $startPosArray;
		$startLat =  $startPosArray[1];
		$startLon = $startPosArray[2];
		close $STARTPOS;	



		open my $FINISHPOS, "/mnt/ramdisk/gps.dat" or die "$!";
                my $finishPos  = (<$FINISHPOS>);
		my @finishPosArray = split(/,/,$finishPos);
                my $finishPosArray;
                $finishLat = $finishPosArray[1];
		$finishLon = $finishPosArray[2];
                close $FINISHPOS;       







#my $distance = distance($startLat, $startLon, $finishLat, $finishLon);
print "Distance is $distance\n";




sub distance 
        {
                my $startLat = shift;
                my $startLon = shift;
                my $finishLat = shift;
                my $finishLon = shift;


                my $gc = Geo::Calc->new( lat => $startLat, lon => $startLon, units => 'mi' ); # Somewhere in Madrid
                my $distance =  $gc->distance_to( { lat => $finishLat, lon => $finishLon},-1 );
                return  $distance;
        }



