#!/usr/bin/perl
use warnings;
use strict;


sub distanceCalc
        {

                my $startLat;
                my $startLon;
                my $finishLat;
                my $finishLon;

                STARTDISTANCECALC:
                open my $STARTPOS, "/home/ubuntu/GPS/lastGPS.dat" or die "Could not open STARTLAT $!";
                my $startPos = (<$STARTPOS>);

                my @startPosArray = split(/,/,$startPos);
                my $startPosArray;
                $startLat =  $startPosArray[1];
                $startLon = $startPosArray[2];
                close $STARTPOS;

                #print "\nStart Lat PRE: $startLat\n";
                #print "Start Lon PRE: $startLon\n";

                $startLat = geoLat($startLat);
                $startLon = geoLon($startLon);

                #print "Start Lat: $startLat\n";
                #print "Start Lon: $startLon\n";

                open my $FINISHPOS, "/mnt/ramdisk/gps.dat" or die "$!";
                my $finishPos = "";
                $finishPos  = (<$FINISHPOS>);

                #check if data from GPS are available
                if (-s '/mnt/ramdisk/gps.dat')
                        {

                                my @finishPosArray = split(/,/,$finishPos);
                                my $finishPosArray;
                                $finishLat = $finishPosArray[1];
                                $finishLon = $finishPosArray[2];
                                close $FINISHPOS;


                                #print "\nFinish Lat PRE: $finishLat\n";
                                #print "Finish Lon PRE: $finishLon\n";

                                $finishLat = geoLat($finishLat);
                                $finishLon = geoLon($finishLon);

                                #print "Finish Lat: $finishLat\n";
                                #print "Finish Lon: $finishLon\n";
                        }
                else
                        {
                                debug("No GPS data yet, will wait for it");
		           }


                my $distance = distance($startLat, $startLon, $finishLat, $finishLon);
                return $distance;

        }




sub geoLat
	{
		my $nmeaLat = shift;
		my $geoLat;
		

		if ($nmeaLat =~ m/N/)
			{
				$nmeaLat =~ s/N//;
			}
		elsif($nmeaLat =~ m/S/)
			{
				$nmeaLat =~ s/S/-/;
			} 
		



		my @nmeaLatArray = split(/\./,$nmeaLat);
		my $nmeaLatArray;

		my @preDecimalLat = split(//,$nmeaLatArray[0]);
		my $preDecimalLat;
		my $preDecLat = "$preDecimalLat[0]"."$preDecimalLat[1]";
		
		
		my @postDecimal = split (//,$nmeaLatArray[1]);
		my $postDecimal;


		my $postLat = "$preDecimalLat[2]"."$preDecimalLat[3]"."$postDecimal[0]"."$postDecimal[1]"."$postDecimal[3]";
		$postLat = "."."$postLat";
		

		$postLat = 1.667 * $postLat;
		$postLat = sprintf("%.5f",$postLat);


		my @postProcessLat = split(/\./,$postLat);
	
		my $postProcessLat;
		

		$geoLat = "$preDecLat"."."."$postProcessLat[1]";
		

		$geoLat =     sprintf("%.6f",$geoLat);

		return $geoLat;

	}







sub geoLon
	{
		my $nmeaLon = shift;
		my $geoLon;
	
		if ($nmeaLon =~ m/E/)
                        {
                                $nmeaLon =~ s/E//;
                        }
                elsif($nmeaLon =~ m/W/)
                        {
                                $nmeaLon =~ s/W/-/;
                        }


		my @nmeaLonArray = split(/\./,$nmeaLon);
		my $nmeaLonArray;
		my @nmeaElementsLon = split(//,$nmeaLonArray[0]);

		my @preDecimalLon = split(//,$nmeaLonArray[0]);
		my $preDecimalLon;
		my $preDecLon = "$preDecimalLon[0]"."$preDecimalLon[1]"."$preDecimalLon[2] ";

		my $postLon = "$preDecimalLon[3]"."$preDecimalLon[4]"."$nmeaLonArray[1]";

		$postLon ="."."$postLon";

		$postLon = 1.667 * $postLon;

		my @postProcessLon = split(/\./,$postLon);
		my $postProcessLon;

		$geoLon = "$preDecimalLon[0]"."$preDecimalLon[1]"."$preDecimalLon[2]"."."."$postProcessLon[1]";

		$geoLon =     sprintf("%.6f",$geoLon);

		return $geoLon;

	}


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


1;
