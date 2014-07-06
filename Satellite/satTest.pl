#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(floor ceil);
use Device::SerialPort;
use Time::Local;
use List::Util qw( min max );

use version; our $VERSION = qv('1.0.1');
require "/home/ubuntu/Subroutines/debug.pm";

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
my $inMessage;
my $outMessage = "%% Command test first";
our $debug = 1; 


debug("Satellite system is starting");


# Activate serial connection:
my $PORT = "/dev/ttyO4";
our $ob = Device::SerialPort->new($PORT) || die "Can't Open $PORT: $!";

$ob->baudrate(19200) || die "failed setting baudrate";
$ob->parity("none") || die "failed setting parity";
$ob->databits(8) || die "failed setting databits";
$ob->handshake("none") || die "failed setting handshake";
$ob->write_settings || die "no settings";
$| = 1;

debug("Serial port ttyO4 to iridium is open");


sleep(1);

#print"Checkng modem\n";
checkModem();

#print"Checking buffer\n";
#checkBuffer();
#checkRI();
#satCom();
#signalNetwork();
#sendMessage($outMessage);
#readMessage();
#test();
#print" Check ring:\n";
#checkRI(); 
message2MO();
checkBuffer();
MOMT();
#test();
#checkBuffer();
readMessage();


sub monitor 
	{
		while(1)
			{
				$rx = $ob->read(255);
				sleep(1);
				print $rx;
			}
	}
############################################ subroutines ##################################



sub test
        {

			$ob->write("AT&Y0\r");                       # reading buffer                  
                        sleep(1);
                        $rx = $ob->read(255);
				if ($rx)
					{
						print "$rx\n";
					}

        }


sub message2MO
        {

		$ob->write("AT+SBDWT=$outMessage\r");
                sleep(1);
                $rx = $ob->read(255);
                if ($rx =~ m/OK/)
                        {
				print "Message should be in buffer\n";
			}
	}




sub MOMT  
        {



                                $ob->write("AT+SBDTC\r");

                                sleep(1);
				debug("transfering message from MO to MT");
                                $rx = $ob->read(255);
                                if ($rx)
                                        {
                                                print "$rx";
                                        }
        }





sub checkModem
	{

		my $i =1;

		while ($i < 6)
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


sub checkBuffer
        {
                $ob->write("AT+SBDS\r");
                sleep(1);
		print"Checking BUFFER:\n";
                $rx = $ob->read(255);
                if ($rx =~ m/SBDS:/)
                        {

                                my @array = split(':',$rx);
                                my $array;
                                my $Part2 = $array[1];
                                my @array2 = split(',',$Part2);
                                my $array2;
                                $MO = $array2[0]; # Mobile originated message 0 - no, 1 - yes
                                $MOMSN = $array2[1]; # Mobile originated message sequence number
                                $MT = $array2[2]; # Terminal originated message
                                $MTMSN = $array2[3]; # Terminal originated message sequence number

                        }
		print "MO: $MO\nMOMSN: $MOMSN\nMT: $MT\nMTMSN: $MTMSN\n";
        }


sub checkRI
	{
                 $ob->write("AT+SBDSX\r");
                 sleep(1);
                 $rx = $ob->read(255);
                 if ($rx =~ m/SBDSX:/)
                        {

				my @arrayRI = split(/\n/,$rx);
				foreach (@arrayRI)
					{
						if($_ =~ m/SBDSX:/)	

							{

                                 				my @array = split(':',$_);
                                 				my $Part2 = $array[1];
                                 				my @array2 = split(',',$Part2);
                                 				my $array2;
                                 				$MO = $array2[0]; # Mobile originated message 0 - no, 1 - yes
                                 				$MOMSN = $array2[1]; # Mobile originated message sequence number
                                 				$MT = $array2[2]; # Terminal originated message
                                 				$MTMSN = $array2[3]; # Terminal originated message sequence number
                                 				$RI = $array2[4]; # Ring indicator
                                 				$numOfMessages = $array2[5]; # Number of messages witing
                                 				$numOfMessages =~ s/\r|\n|OK//g;
                                 				debug("MO: $MO\nMOMSN: $MOMSN\nMT: $MT\nMTMSN: $MTMSN\nRI: $RI\nNum of messages waiting: $numOfMessages");
							}	
					}	
				return $RI;
			}
	}


sub signalNetwork{


                $ob->write("AT+CIER=1,1,1,0\r");
                debug("Checking network and signal strenght\n");
                do
                        {
                                sleep(1);
                                $rx = $ob->read(255);
                                if ($rx)
                                        {
                                                if ($rx =~ m/CIEV:1/)
                                                        {
                                                              
                                                                my @array = split(':',$rx);
                                                                my $array;
                                                                @array = split(',',$array[1]);
                                                                $network = substr($array[1], 0, 1);
                                                                if ($network == 1)
                                                                        {
                                                                                debug("\nNetwork available");
                                                                        }
                                                        }



                                                if ($rx =~ m/CIEV:0/)
                                                       {

                                                                my @array2 = split(':',$rx);
                                                         my $array2;
                                                                    #print $array[1];
                                                                @array2 = split(',',$array2[1]);
                                                                $sigStrenght = substr( $array2[1],0,1);
                                                                debug("Sig streght = $sigStrenght");

                                                        }
                                        }

                        }
                                until ($sigStrenght >1);
                                debug("Ready to communicate");

}



sub sendMessage 
        {

                my $outMessage = shift;

                ## Check the buffer if there is any MO messages to be send

                $ob->write("AT+SBDS\r");
                sleep(1);
                $rx = $ob->read(255);
                if ($rx =~ m/SBDS:/)
                        {


                                my @arrayBUF  = split(/\n/,$rx);
                                foreach (@arrayBUF)
                                        {
                                                if ($_ =~ m/SBDS:/)
                                                        {
                                                                my @array = split(':',$_);
                                                                my $array;
                                                                my $Part2 = $array[1];
                                                                my @array2 = split(',',$Part2);
                                                                my $array2;
                                                                $MO = $array2[0];               # Mobile originated message 0 - no, 1 - yes
                                                                $MOMSN = $array2[1];            # Mobile originated message sequence number
                                                                $MT = $array2[2];               # Terminal originated message 
                                                                $MTMSN = $array2[3];            # Terminal originated message sequence number

                                                        }

                                        }
                        }

                if ($MO != 0)
                        {
                                #send a message
                                debug("One message to be send from MO\n");
                                satCom();
                        }


                ## Put message into buffer

                $ob->write("AT+SBDWT=$outMessage\r");
                sleep(1);
                $rx = $ob->read(255);
                if ($rx =~ m/OK/)
                        {

                        # communicate with sattelite - cost money
                                satCom();

                        }
        }



sub satCom 
        {
                BEGININGSAT:
                signalNetwork();        # check the network and wait for good signal
                debug("Executing SBDIXA command\n");

                $ob->write("AT+SBDIXA\r");
#		
		 $rx = $ob->read(255);
#		
                do
                        {
                                sleep(1);
                                $rx = $ob->read(255);
                        }
                until ($rx =~ m/SBDIX:/);
   
                my @arrayIX  = split(/\n/,$rx);

                foreach (@arrayIX)
                        {
                                if ($_ =~ m/SBDIX:/)
                                        {
                                                my @array6 = split(':',$_);
                                                my $array6;
                                                my $Part26 = $array6[1];
                                                my @array26 = split(',',$Part26);
                                                my $array26;
                                                $MO = $array26[0];               # 0 - message transfered, 
                                                $MOMSN = $array26[1];            # Mobile originated message sequence number
                                                $MT = $array26[2];               # 0-no messages to be received, 1-Succesfully recvd, 2-error  
                                                $MTMSN = $array26[3];           # Mobile terminated message sequence number             
                                                $numOfMessages = $array26[5];   # number of messages to be transfered from GSS
                                                $numOfMessages = substr($numOfMessages, 0, 3);
                                                $numOfMessages =~ s/\r|\n//g;
                                        }
                        }

                debug("MO: $MO, MOMSN: $MOMSN, MT: $MT, MTMSN: $MTMSN, numOfMessages: $numOfMessages\n");

                if ($MO == 0)   # MO=0 - transfered ok, MO=1 

                        {
                                $ob->write("AT+SBDD0\r");
                                sleep(1);
                                $rx = $ob->read(255);
                                if ($rx =~ m /0/)
                                        {
 
                                                debug("Message sent and MO buffer cleaned\n");
                                        }
                        }
                elsif($MO == 17 or $MO == 18 or $MO == 13 or $MO == 10 or $MO == 35)                    # gataway not respondng
                        {
                                goto BEGININGSAT;
                        }
                elsif($MO == 18)        # connection lost
                        {
                                goto BEGININGSAT;
                        }

                if ($MT > 0)
                        {
                                debug("There is a MT in the buffer\n");
                                $inMessage = readMessage();
                               # processMessage();
                        }
                if ($numOfMessages > 1)
                        {
                                debug("More mesages waiting at GSS, will get them.\n");
                                satCom();
                        }
        }

sub readMessage {

                        $ob->write("AT+SBDRT\r");                       # reading buffer                  
                        sleep(1);
                        $rx = $ob->read(255);
                        my @array = split(':',$rx);
                        my $array;
                        $rx = $array[1];
                        $rx =~ s/^\s+//; #remove leading spaces
                        $rx =~ s/\s+$//; #remove trailing spaces
                        my $okRead = substr($rx, -2);
                        $inMessage = substr($rx, 0, -2);


                        $ob->write("AT+SBDD1\r");                       # cleaning buffer
                        sleep(1);
                        $rx = $ob->read(255);

                        my @cleanBuff = split(/\n/,$rx);
                        my $cleanBuff;
                        if ($cleanBuff[1] == 0)
                                {
                                        debug("Buffer cleaned succesfully\n");
                                }
                        debug("Received message is: $inMessage");


				if ($inMessage =~ m/%%/)	# check if this is regular mail or command
					{
						commandProcess();
						debug("Command was received: $inMessage");

					}
				else 
					{
						my $mailNumber = mailNumber();
						open my $MAIL, ">/home/ubuntu/Mail/Current/$mailNumber" or die "Could not create file $!";
						print $MAIL $inMessage;
						close ($MAIL);
                
                        			debug("Mail was filed as $mailNumber into Current directory");
					}
        }


sub mailNumber 
        {

                my $mailListCurr = ` ls /home/ubuntu/Mail/Current/`;
                my @listArrayCurr = split (/\n/,$mailListCurr);
                my $listArrayCurr;
                my @finalArray;

                foreach(@listArrayCurr)
                        {
                                my @elementArrayCurr = split (/\./,$_);
                                my $elemantArrayCurr;
                                push (@finalArray,$elementArrayCurr[0]);
                        }

                my $mailListRead = ` ls /home/ubuntu/Mail/Read/`;
                my @listArrayRead = split (/\n/,$mailListRead);
                my $listArrayRead;

                foreach(@listArrayRead)
                        {
                                my @elementArrayRead = split (/\./,$_);
                                my $elemantArrayRead;
                                push (@finalArray,$elementArrayRead[0]);
                        }


                my $max = max(@finalArray);
                $max = $max+1;
                $max  = "$max"."."."txt";
                return $max;
        }

sub commandNum
        {
                my $max;
                my $comNum = ` ls /home/ubuntu/Mail/Commands/`;
                my @listArrayCom = split (/\n/,$comNum);
                my $listArrayCom;
                my @finalArray;

                if (@listArrayCom)
                        {
                                foreach(@listArrayCom)
                                        {
                                                my @elementArrayCom = split (/\./,$_);
                                                my $elemantArrayCom;
                                                push (@finalArray,$elementArrayCom[0]);
                                        }

                                $max = max(@finalArray);
                                $max = $max+1;
                                $max  = "$max"."."."txt";
                                return $max;
                        }
                else
                        {
                                $max = "1"."."."txt";
                                return $max;
                        }
        }


sub commandProcess
	{
		debug("Command is being processed");
		
		 my $commandNum = commandNum();				# putting command into archives
                 open my $COMMAND, ">/home/ubuntu/Mail/Commands/$commandNum" or die "Could not create file $!";
                                                print $COMMAND $inMessage;
                                                close ($COMMAND);
		
	}
