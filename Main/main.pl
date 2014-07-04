#!/usr/bin/perl 
use strict;
use warnings;
use POSIX qw(floor ceil);
use Device::SerialPort;
use Time::Local;
#use Geo::Calc;


use version; our $VERSION = qv('1.0.1');



require "/home/ubuntu/Subroutines/config.pm";
require "/home/ubuntu/Subroutines/debug.pm";
require "/home/ubuntu/Subroutines/geoCalc.pm";

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




debug("Main script starts");

#`sudo /home/ubuntu/start/startSetDate.pl`;
`/home/ubuntu/Config/config.pl`;		# check config file, if .last is different compare to .default, last is loaded to ramdisk

debug("Opening communication to Iridium modem");

my $ob = Device::SerialPort->new($PORT) || die "Can't Open $PORT: $!";

$ob->baudrate(19200) || die "failed setting baudrate";
$ob->parity("none") || die "failed setting parity";
$ob->databits(8) || die "failed setting databits";
$ob->handshake("none") || die "failed setting handshake";
$ob->write_settings || die "no settings";
$| = 1;

debug("Serial port ttyO4 to iridium is open");
sleep(1);
#checkModem();


		
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



		if ($telMode !~ m/[0-3]/)
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
		
				TIMENEW:
				$telSeconds = $telTime * 1;
				my $currentTime = time();
				my $execTime = $currentTime + $telSeconds - 1;
			
				TIMESTART:
					
				# check if this is a time to end telemetry
				if  ($currentTime > $execTime)
					{
						my $pid = fork();
						if( $pid == 0 )
							{
   								debug("Sending telemetry message");
   								print "Child process is existing\n";
   								sleep(1);
								exit 0;
								
							}
						goto TIMENEW;
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
                                                                debug("Sending telemetry message");
                                                                print "Child process is existing\n";
                                                                sleep(1);
                                                                exit 0;

                                                        }
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


###############################################  Subroutines ##################################################


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





sub checkModem
        {

                my $i =1;

                while ($i < 30)
                        {

                                $ob->write("AT\r");
                                debug("Checking if modem is accesable....trial $i");
                                $i++;
                                sleep(1);

                                $rx = $ob->read(255);
                                if ($rx =~ m/OK/)
                                        {
                                                goto READY;
                                        }
                        }
                        debug("Can\'t find Iridium 9602 !!");
                         exit();

                READY:{debug("Iridium 9602 identyfied and ready to work....");}
        }


