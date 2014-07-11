#!/usr/bin/perl 
use strict;
use warnings;
use POSIX qw(floor ceil);
use Device::SerialPort;
use Time::Local;
#use Geo::Calc;
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
		
				$telSeconds = $telTime * 30;
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

				TIMENEW:
		
				my $execTime = $currentTime + $telSeconds - 1;
			
				TIMESTART:
					
				# check if this is a time to end telemetry
				if  ($currentTime > $execTime)
					{
   						debug("Time is up, sending telemetry");
							#	sendMessage($telMessage);
   						sleep(1);
						recordRapTime();								
						goto TIMENEW;
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
						goto TIMENEW;
					}
				
				goto TIMESTART;
				

			}
		elsif ($telMode == 2)
			{
				debug("TelMode is 2, so telemetry will be sent every $telTime miles");
				
				DISTANCENEW:
                                
				
				my $distance2Be = getTelTime();
                        	$distance2Be = $distance2Be *10;        
                            

                                DISTANCESTART:


                                # check if distance is long enough to send telemetry message
				my $distance = distanceCalc();		
                                if  ($distance  > $distance2Be)
                                        {
					        my $pid = fork();
                                                if( $pid == 0 )
                                                        {
                                                       		
							        debug("Sending telemetry message after Distance was exeded");
                                                                print "Child process is existing after distance was exeded\n";
												
                                                                sleep(1);
								exit(0);
								
                                                        }
						updateLastGPS();
						goto DISTANCENEW;
                                        }
                                sleep(1);

                                # Check if telMode was changed 
                                my  $newTelMode = getTelMode();
                                if ($newTelMode != $telMode)
                                        {
                                                print "New tel mode detected\n";
                                                $telMode = $newTelMode;
                                                goto BEGINING;
                                        }

                                my $newDistance2Be = getTelTime();
				$newDistance2Be = $newDistance2Be *10;

                                # check if distance  was changed
                                if ($newDistance2Be != $distance2Be)
                                        {
                                                print "New distance is  introduced\n";
                                                $distance2Be = $newDistance2Be;
                                                goto DISTANCENEW;
                                        }

                                goto DISTANCESTART;

			}

		sleep(5);
	}







