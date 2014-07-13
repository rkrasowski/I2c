
# check for time when last raport was sent
sub lastRapTime
	{
		open my $LASTRAPORT, "/home/ubuntu/Data/lastTime.dat" or die "Could not open LASTRAPORT $!";
		my $value = (<$LASTRAPORT>);
		close $LASTRAPORT;
		return $value;
	}

sub recordRapTime
	{
	 	open my $LASTRAPORT, ">/home/ubuntu/Data/lastTime.dat" or die "Could not open LASTRAPORT $!";
                my $time = time();
		print $LASTRAPORT $time;
                close $LASTRAPORT;
        }


1;


