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


our $debug = 1;          	# 0 - no debug, 1-is terminal STOUT, 2-STOUT to Log/main.log
my $PORT = "/dev/ttyO4";	# Iridium port
my $routineTime = 5;		# Lenght of time when routine pouse before repeating itself
my $timeMultiplication = 5; 	# For 1h = 3600 - number of seconds in hour

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
		$telDistance = getTelDistance();
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
				
				NOTELE:

				# Check if any message is waiting to be retrieve
                                my $RI = checkRI();
                                if ($RI != 0)
                                        {
                                                debug("Mode0: Ring was received, will retrieve message");
                                        }
				
				# Check if telMode was changed 
                                my  $newTelMode = getTelMode();
                                if ($newTelMode != $telMode)
                                        {
                                                debug("Mode0: New telemetry  mode detected -> $newTelMode");
                                                $telMode = $newTelMode;
                                                goto BEGINING;
                                        }

				sleep($routineTime);
				goto NOTELE;

			}
		elsif ($telMode == 1)
			{
			
				debug("TelMode is 1, so will send data every $telTime h");
		
				$telSeconds = $telTime * $timeMultiplication;
				# Check from record how much time passed from last report
				my $lastRepTime = lastRapTime();
				my $lastExpectedTime = $lastRepTime + $telSeconds; 
				my $currentTime = time();
				
				if  ($currentTime > $lastExpectedTime)
                                        {
                                         	debug("Mode1: Just starting, Sending telemetry since time passed is more than set");
                                               # sendMessage($telMessage);
                                                sleep(1);
                                                recordRapTime();
                                        }

				TIMENEW1:
		
				my $execTime = $currentTime + $telSeconds - 1;
				$telTime = getTelTime();				
		
				TIMESTART1:
					
				# check if this is a time to end telemetry
				if  ($currentTime > $execTime)
					{
   						debug("Mode1: Time is up, sending telemetry");
							#	sendMessage($telMessage);
   						sleep(1);
						recordRapTime();								
						goto TIMENEW1;
					}

				# Check if any message is waiting to be retrieve
				#print ".";
				my $RI = checkRI();
               			if ($RI != 0)
                        		{
                                		print "Mode1: Ring was received, will retrieve message\n";
                                		#satCom();
                        		}
				sleep($routineTime);
				
				# Check if telMode was changed 
				my  $newTelMode = getTelMode();
				if ($newTelMode != $telMode)
					{
						debug("Mode1: New telemetry  mode detected -> $newTelMode");
						$telMode = $newTelMode;
						goto BEGINING;
					}

				$currentTime = time();
				my $newTelTime = getTelTime();
				
				# check if telTime was changed
				if ($newTelTime != $telTime)
					{
						debug("Mode1: New telTime detected -> $newTelTime");
						$telTime = $newTelTime;
						goto BEGINING;
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
                                if ($distance > $distance2Be)
                                        {
						debug("Mode2: Sending telemetry message after Distance was exeded");
                                                sleep(1);
						updateLastGPS();
						goto DISTANCENEW2;
                                        }

				# Check if any message is waiting to be retrieve
                                #print ".";
                                my $RI = checkRI();
                                if ($RI != 0)
                                        {
                                                print "Ring was received, will retrieve message\n";
                                                #satCom();
                                        }


                                sleep($routineTime);
			
                                # Check if telMode was changed
                                my $newTelMode = getTelMode();
                                if ($newTelMode != $telMode)
                                        {
                                                debug("New tel mode detected -> $newTelMode");
                                                $telMode = $newTelMode;
                                                goto BEGINING;
                                        }

                                my $newDistance2Be = getTelDistance();
				$newDistance2Be = $newDistance2Be *10;
				
                                # check if distance was changed
                                if ($newDistance2Be != $distance2Be)
                                        {
                                                debug("Mode2: New distance detected -> $newDistance2Be");
                                                $distance2Be = $newDistance2Be;
                                                goto DISTANCENEW2;
                                        }
	

                                goto DISTANCESTART2;


			}

		 elsif ($telMode == 3)
                        {

                                debug("TelMode is 3, so will send data every $telTime h or every $telDistance miles, whatever comes first");
				
				$telTime = getTelTime();
                                $telSeconds = $telTime * $timeMultiplication;
                                # Check from record how much time passed from last report
                                my $lastRepTime = lastRapTime();
                                my $lastExpectedTime = $lastRepTime + $telSeconds;
                                my $currentTime = time();

                                if  ($currentTime > $lastExpectedTime)
                                        {
                                                debug("Mode 3: Sending telemetry message it is time - just turned ON");
                                               # sendMessage($telMessage);
                                                sleep(1);
                                                recordRapTime();
						updateLastGPS();
                                        }

                                TIMENEW3:
				$telTime = getTelTime();
                                $telSeconds = $telTime * $timeMultiplication;
                                my $execTime = $currentTime + $telSeconds - 1;

                                TIMESTART3:

                                # check if this is a time to end telemetry
				$currentTime = time();
                                if  ($currentTime > $execTime)
                                        {
                                                debug("Mode 3: Time is up, sending telemetry");
                                                # sendMessage($telMessage);
                                                sleep(1);
                                                recordRapTime();
						updateLastGPS();
                                                goto TIMENEW3;
                                        }
				


                                my $distance2Be = getTelDistance();
                                $distance2Be = $distance2Be *10;


                                # check if distance is long enough to send telemetry message
                                my $distance = distanceCalc();

                                if ($distance > $distance2Be)
                                        {
                                                debug("Mode 3: Sending telemetry message after Distance was exeded");
                                                sleep(1);
                                                updateLastGPS();
						recordRapTime();
                                                goto TIMENEW3;
                                        }
                              

                                # Check if any message is waiting to be retrieve
                                #print ".";
                                my $RI = checkRI();
                                if ($RI != 0)
                                        {
                                                print "Ring was received, will retrieve message\n";
                                                #satCom();
                                        }

				  sleep($routineTime);

                                # Check if telMode was changed 
                                my  $newTelMode = getTelMode();
                                if ($newTelMode != $telMode)
                                        {
                                                debug("Mode 3: New tel mode detected -> $newTelMode");
                                                $telMode = $newTelMode;
                                                goto BEGINING;
                                        }

				 # check if telTime was changed

                                my $newTelTime = getTelTime();
		
                                if ($newTelTime != $telTime)
                                        {
                                                debug("Mode 3: New telTime was detected -> $newTelTime");
                                                goto BEGINING;
                                        }

				# check in distance was changed
				my $newDistance2Be = getTelDistance();
                                $newDistance2Be = $newDistance2Be *10;

				 if ($newDistance2Be != $distance2Be)
                                        {
                                                debug("Mode 3: New distance detected -> $newDistance2Be");
                                                $distance2Be = $newDistance2Be;
                                                goto BEGINING;
                                        }

                                goto TIMESTART3;


                        }


	}







