#!/usr/bin/perl 
use strict;
use warnings;
use POSIX qw(floor ceil);
use Device::SerialPort;
use Time::Local;
use Geo::Calc;
use List::Util qw( min max );


use version; our $VERSION = qv('1.0.1');



require "/home/ubuntu/Subroutines/config.pm";
require "/home/ubuntu/Subroutines/debug.pm";
require "/home/ubuntu/Subroutines/geoCalc.pm";
require "/home/ubuntu/Subroutines/modem.pm";
require "/home/ubuntu/Subroutines/mail.pm";
require "/home/ubuntu/Subroutines/time.pm";



our $debug = 1;          # 0 - no debug, 1-is terminal STOUT, 2-STOUT to Log/main.log
my $PORT = "/dev/ttyO4";	# Iridium port


my $telMode;
my $telTime;
my $telDistance;
my $telSeconds;
my $BTON;
my $BTOFF;
my $ledMode;
my $confirmMode;
my $gpsMode;
my $sigStrenght;
my $network;
my $MO;
my $MOMSN;
my $MT;
my $MTMSN;
my $tx;
my $rx;
my $RI;
my $numOfMessages;
my $startLat;
my $startLon;
my $finishLat;
my $finishLon;
my $telMessage = `date`;


debug("Main script starts");

#`sudo /home/ubuntu/start/startSetDate.pl`;
`/home/ubuntu/Config/config.pl`;		# check config file, if .last is different compare to .default, last is loaded to ramdisk

debug("Opening communication to Iridium modem");

our $ob = Device::SerialPort->new($PORT) || die "Can't Open $PORT: $!";

$ob->baudrate(19200) || die "failed setting baudrate";
$ob->parity("none") || die "failed setting parity";
$ob->databits(8) || die "failed setting databits";
$ob->handshake("none") || die "failed setting handshake";
$ob->write_settings || die "no settings";
$| = 1;

debug("Serial port ttyO4 to iridium is open");
sleep(1);
checkModem();


		
debug("Reading config data");

$telMode = getTelMode();
debug("Tel mode is $telMode");
$telTime = getTelTime();
debug("TelTime is $telTime h");
$telDistance = getTelDistance();
debug("TelDistance is $telDistance miles");
$BTON = getBTON();
debug("BTOn is for $BTON sec");
$BTOFF = getBTOFF();
debug("BTOFF before: $BTOFF");
$ledMode = getLEDMode();
debug("LEDMode before: $ledMode");
$confirmMode = getConfirmMode();
debug("ConfirmMode before: $confirmMode");
$gpsMode = getGPSMode();
debug("GPSMode before: $gpsMode");
                
while (1)
	{
	
		BEGINING:

		$telMode = getTelMode();
		$telTime = getTelTime();
		$BTON = getBTON();
		$BTOFF = getBTOFF();
		$ledMode = getLEDMode();
		$confirmMode = getConfirmMode();
		$gpsMode = getGPSMode();



		if ($telMode !~ m/[0-4]/)
			{
				$telMode = 1;
				debug("telemetry mode is wrong, will use 1 as default");
			}

		if ($telMode == 0)
			{
				debug("TelMode is 0, no telemetry will be sent");
			}
		elsif ($telMode == 1)
			{
			
				debug("TelMode is 1, so will send data every $telTime h");
		
				$telSeconds = $telTime * 300;
				# Check from record how much time passed from last report
				my $lastRepTime = lastRapTime();
				my $lastExpectedTime = $lastRepTime + $telSeconds; 
				my $currentTime = time();
				
				if  ($currentTime > $lastExpectedTime)
                                        {
                                         	debug("Sending telemetry message when lastExpected time is ready");
                                               # sendMessage($telMessage);
                                                sleep(1);
                                                recordRapTime();
                                        }

				TIMENEW1:
		
				my $execTime = $currentTime + $telSeconds - 1;
			
				TIMESTART1:
					
				# check if this is a time to end telemetry
				if  ($currentTime > $execTime)
					{
   						debug("Time is up, sending telemetry");
							#	sendMessage($telMessage);
   						sleep(1);
						recordRapTime();								
						goto TIMENEW1;
					}

				# Check if any message is waiting to be retrieve
			
				print "Checking for RI\n";
				my $RI = checkRI();
               			if ($RI != 0)
                        		{
                                		print "Ring was received, will retrieve message\n";
                                		#satCom();
                        		}


				
				sleep(5);
				
				# Check if telMode was changed 
				my  $newTelMode = getTelMode();
				if ($newTelMode != $telMode)
					{
						print "New tel mode detected\n";
						$telMode = $newTelMode;
						goto BEGINING;
					}

				$currentTime = time();
				my $newTelTime = getTelTime();
				
				# check if telTime was changed
				if ($newTelTime != $telTime)
					{
						print "New telTime introduced\n";
						$telTime = $newTelTime;
						goto TIMENEW1;
					}
				
				goto TIMESTART1;
				

			}
		elsif ($telMode == 2)
			{	
				debug("TelMode is 2, so telemetry will be sent every $telTime miles");

				DISTANCENEW2:
                                

				my $distance2Be = getTelDistance();
                         	$distance2Be = $distance2Be *10;
                            

                                DISTANCESTART2:


                                # check if distance is long enough to send telemetry message
				my $distance = distanceCalc();
				$distance = $distance * 10;
				print "distance is: $distance\n";	
                                if ($distance > $distance2Be)
                                        {
						debug("Sending telemetry message after Distance was exeded");
                                                sleep(1);
						updateLastGPS();
						goto DISTANCENEW2;
                                        }
                                sleep(5);
			
                                # Check if telMode was changed
                                my $newTelMode = getTelMode();
                                if ($newTelMode != $telMode)
                                        {
                                                print "New tel mode detected\n";
                                                $telMode = $newTelMode;
                                                goto BEGINING;
                                        }

                                my $newDistance2Be = getTelDistance();
				$newDistance2Be = $newDistance2Be *10;
				
                                # check if distance was changed
                                if ($newDistance2Be != $distance2Be)
                                        {
                                                print "New distance is introduced\n";
                                                $distance2Be = $newDistance2Be;
                                                goto DISTANCENEW2;
                                        }
	

                                goto DISTANCESTART2;


			}

		 elsif ($telMode == 3)
                        {

                                debug("TelMode is 3, so will send data every $telTime h or every $telDistance miles, whatever comes first");

                                $telSeconds = $telTime * 10;
                                # Check from record how much time passed from last report
                                my $lastRepTime = lastRapTime();
                                my $lastExpectedTime = $lastRepTime + $telSeconds;
                                my $currentTime = time();

                                if  ($currentTime > $lastExpectedTime)
                                        {
                                                debug("Mode 3: Sending telemetry message when lastExpected time is ready");
                                               # sendMessage($telMessage);
                                                sleep(1);
                                                recordRapTime();
						updateLastGPS();
                                        }

                                TIMENEW3:

                                my $execTime = $currentTime + $telSeconds - 1;

                                TIMESTART3:

                                # check if this is a time to end telemetry
				$currentTime = time();
                                if  ($currentTime > $execTime)
                                        {
                                                debug("Mode 3: Time is up, sending telemetry");
                                                        #       sendMessage($telMessage);
                                                sleep(1);
                                                recordRapTime();
						updateLastGPS();
                                                goto TIMENEW3;
                                        }
				


                                my $distance2Be = getTelDistance();
                                $distance2Be = $distance2Be *10;


                                # check if distance is long enough to send telemetry message
                                my $distance = distanceCalc();
				print "Distance 2be $distance2Be\n";
				print "Distance now $distance\n";


                                if ($distance > $distance2Be)
                                        {
                                                debug("Mode 3: Sending telemetry message after Distance was exeded");
                                                sleep(1);
                                                updateLastGPS();
						recordRapTime();
                                                goto TIMENEW3;
                                        }
                              

                                # Check if any message is waiting to be retrieve

                                print "Checking for RI\n";
                                my $RI = checkRI();
                                if ($RI != 0)
                                        {
                                                print "Ring was received, will retrieve message\n";
                                                #satCom();
                                        }

				  sleep(5);

                                # Check if telMode was changed 
                                my  $newTelMode = getTelMode();
				print"New TelMode is: $newTelMode\n\n";
                                if ($newTelMode != $telMode)
                                        {
                                                print "Mode 3: New tel mode detected\n";
                                                $telMode = $newTelMode;
                                                goto BEGINING;
                                        }

				 # check if telTime was changed

                                my $newTelTime = getTelTime();
                                if ($newTelTime != $telTime)
                                        {
                                                print "Mode 3: New telTime introduced\n";
                                                $telTime = $newTelTime;
                                                goto TIMENEW3;
                                        }

				# check in distance was changed
				my $newDistance2Be = getTelDistance();
                                $newDistance2Be = $newDistance2Be *10;

				 if ($newDistance2Be != $distance2Be)
                                        {
                                                print "Mode 3: New distance is introduced\n";
                                                $distance2Be = $newDistance2Be;
                                                goto TIMENEW3;
                                        }

                                goto TIMESTART3;


                        }


	}







