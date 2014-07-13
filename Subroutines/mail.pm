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

                 my $commandNum = commandNum();                         # putting command into archives
                 open my $COMMAND, ">/home/ubuntu/Mail/Commands/$commandNum" or die "Could not create file $!";
                                                print $COMMAND $inMessage;
                                                close ($COMMAND);

        }


1;
