#!/usr/bin/perl
use warnings;
use strict;

# pos 0 - telemetry mode
# pos 1,2 - telemetry time or distance
# pos 3,4 - BTON for number of minutes
# pos 5,6 - BTOFF for number of hours
# pos 7 - LED mode
# pos 8 - Confirmatory mode
# pos 9 - GPS mode 	- 0 - nothing
#					- 1 - transmiting NMEA0183 via serial port


my $reading = 1;	# 0 - no debug  1 = debug

#my $all = getAll();
#print "All before $all\n";



if ($reading == 1)
	{


		my $telMode = getTelMode();
		print "Tel mode is $telMode\n";
		changeTelMode(0);
		$telMode = getTelMode();
		print "Tel mode after is $telMode\n";

		my $telTime = getTelTime();
		print "TelTime before: $telTime\n";
		changeTelTime(01);
		$telTime = getTelTime();
		print "TelTime after: $telTime\n";

		my $BTON = getBTON();
		print "BTON before: $BTON\n";
		changeBTON(05);
		$BTON = getBTON();
		print "BTON after: $BTON\n";

		my $BTOFF = getBTOFF();
		print "BTOFF before: $BTOFF\n";
		changeBTOFF(01);
		$BTOFF = getBTOFF();
		print "BTOFF after: $BTOFF\n";

		my $ledMode = getLEDMode();
		print "LEDMode before: $ledMode\n";
		changeLEDMode(9);
		$ledMode = getLEDMode();
		print "LEDMode after: $ledMode\n";

		my $confirmMode = getConfirmMode();
		print "confirmMode before: $confirmMode\n";
		changeConfirmMode(8);
		$confirmMode = getConfirmMode();
		print "ConfirmMode after: $confirmMode\n";

		my $gpsMode = getGPSMode();
		print "GPSMode before: $gpsMode\n";
		changeGPSMode(1);
		$gpsMode = getGPSMode();
		print "gpsMode after: $gpsMode\n";


		#$all = getAll();
		#print "All after $all\n";


	}


################################### Subroutines ###########################
sub getAll
	{
		open (my $CONFIG, '/home/ubuntu/Config/config.last');
		my $data =  (<$CONFIG>);
		chomp $data;
		my @dataArray = split(//,$data);
		foreach(@dataArray)
			{
				print"Data: $_\n";
			}
		close $CONFIG;
		
	}


sub getTelMode
	{
		open (my $CONFIG, '/home/ubuntu/Config/config.last');
		my $data =  (<$CONFIG>);
		my @dataArray = split(//,$data);
		my $dataArray;
		close $CONFIG;
		return $dataArray[0];
	}



sub changeTelMode
	{
		my $newMode = shift;
		if ($newMode !~ m/[0-5]/)
			{
				print "telMode had a WRONG value!! Was not changed\n";
				return;
			}
		else 
			{
				open my $READ, "/home/ubuntu/Config/config.last" or die "Could not open READ $!";
				my $data = (<$READ>);
				chomp $data;
				my @dataArray = split(//,$data);
				my $dataArray;	
				$dataArray[0] = $newMode;
				$data = join('',@dataArray);
				open my $WRITE, "+> /home/ubuntu/Config/config.last" or die "Could not open it  $!";	
				print $WRITE "$data";
				close $READ;
				close $WRITE;
			}
	}


sub getTelTime
	{
		open (my $CONFIG, '/home/ubuntu/Config/config.last');
		my $data =  (<$CONFIG>);
		my @dataArray = split(//,$data);
		my $dataArray;
		close $CONFIG;
		return "$dataArray[1]"."$dataArray[2]";
	}


sub changeTelTime
	{
		my $newTelTime = shift;
		$newTelTime = sprintf("%02d",$newTelTime);
		open my $READ, "/home/ubuntu/Config/config.last" or die "Could not open READ $!";
		my $data = (<$READ>);
		chomp $data;
		my @dataArray = split(//,$data);
		my $dataArray;
		my @telTime = split(//,$newTelTime);
		my $telTime;
			
		$dataArray[1] = $telTime[0];
		$dataArray[2] = $telTime[1];
		$data = join('',@dataArray);
		open my $WRITE, "+> /home/ubuntu/Config/config.last" or die "Could not open it  $!";	
		print $WRITE "$data";
		close $READ;
		close $WRITE;
	}




sub getBTON
	{
		open (my $CONFIG, '/home/ubuntu/Config/config.last');
		my $data =  (<$CONFIG>);
		my @dataArray = split(//,$data);
		my $dataArray;
		close $CONFIG;
		return "$dataArray[3]"."$dataArray[4]";
	}

sub changeBTON
	{
		my $newBTON = shift;
		$newBTON = sprintf("%02d",$newBTON);
		open my $READ, "/home/ubuntu/Config/config.last" or die "Could not open READ $!";
		my $data = (<$READ>);
		chomp $data;
		my @dataArray = split(//,$data);
		my $dataArray;
		my @BTTimeON = split(//,$newBTON);
                my $BTTimeON;

		$dataArray[3] = $BTTimeON[0];
		$dataArray[4] = $BTTimeON[1];

		my $dataBTON = join('',@dataArray);
	
		open my $WRITE, "+> /home/ubuntu/Config/config.last" or die "Could not open it  $!";	
		print $WRITE "$dataBTON";
		close $READ;
		close $WRITE;
	}		
		

sub getBTOFF
        {
                open (my $CONFIG, '/home/ubuntu/Config/config.last');
                my $data =  (<$CONFIG>);
                my @dataArray = split(//,$data);
                my $dataArray;
                close $CONFIG;
                return "$dataArray[5]"."$dataArray[6]";
        }

sub changeBTOFF
        {
                my $newBTOFF = shift;
		$newBTOFF = sprintf("%02d",$newBTOFF);
                open my $READ, "/home/ubuntu/Config/config.last" or die "Could not open READ $!";
                my $data = (<$READ>);
                chomp $data;
                my @dataArray = split(//,$data);
                my $dataArray;
                my @BTTimeOFF = split(//,$newBTOFF);
                my $BTTimeOFF;

                $dataArray[5] = $BTTimeOFF[0];
                $dataArray[6] = $BTTimeOFF[1];

                $data = join('',@dataArray);
                open my $WRITE, "+> /home/ubuntu/Config/config.last" or die "Could not open it  $!";
                print $WRITE "$data";
                close $READ;
                close $WRITE;
        }




sub getLEDMode
	{
		open (my $CONFIG, '/home/ubuntu/Config/config.last');
		my $data =  (<$CONFIG>);
		my @dataArray = split(//,$data);
		my $dataArray;
		close $CONFIG;
		return $dataArray[7];
	}

sub changeLEDMode
	{
		my $newLEDMode = shift;
		#print "New $newLEDMode\n";
		open my $READ, "/home/ubuntu/Config/config.last" or die "Could not open READ $!";
		my $data = (<$READ>);
		chomp $data;
		my @dataArray = split(//,$data);
		my $dataArray;	
		$dataArray[7] = $newLEDMode;
		$data = join('',@dataArray);
		open my $WRITE, "+> /home/ubuntu/Config/config.last" or die "Could not open it  $!";	
		print $WRITE "$data";
		close $READ;
		close $WRITE;
	}		
		
sub getConfirmMode
	{
		open (my $CONFIG, '/home/ubuntu/Config/config.last');
		my $data =  (<$CONFIG>);
		my @dataArray = split(//,$data);
		my $dataArray;
		close $CONFIG;
		return $dataArray[8];
	}



sub changeConfirmMode
	{
		my $newTelMode = shift;
		open my $READ, "/home/ubuntu/Config/config.last" or die "Could not open READ $!";
		my $data = (<$READ>);
		chomp $data;
		my @dataArray = split(//,$data);
		my $dataArray;	
		$dataArray[8] = $newTelMode;
		$data = join('',@dataArray);
		open my $WRITE, "+> /home/ubuntu/Config/config.last" or die "Could not open it  $!";	
		print $WRITE "$data";
		close $READ;
		close $WRITE;
	}		
	
sub getGPSMode
	{
		open (my $CONFIG, '/home/ubuntu/Config/config.last');
		my $data =  (<$CONFIG>);
		my @dataArray = split(//,$data);
		my $dataArray;
		close $CONFIG;
		return $dataArray[9];
	}



sub changeGPSMode
	{
		my $newMode = shift;
		if ($newMode !~ m/[0-1]/)
			{
				print "gpsMode had a WRONG value!! Was not changed\n";
				return;
			}
		else 
			{
				open my $READ, "/home/ubuntu/Config/config.last" or die "Could not open READ $!";
				my $data = (<$READ>);
				chomp $data;
				my @dataArray = split(//,$data);
				my $dataArray;	
				$dataArray[9] = $newMode;
				$data = join('',@dataArray);
				open my $WRITE, "+> /home/ubuntu/Config/config.last" or die "Could not open it  $!";	
				print $WRITE "$data";
				close $READ;
				close $WRITE;
			}
	}			
		
1;
