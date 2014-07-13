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
                                                                #debug("MO: $MO\nMOMSN: $MOMSN\nMT: $MT\nMTMSN: $MTMSN\nRI: $RI\nNum of messages waiting: $numOfMessages");
                                                                return $RI;
                                                        }
                                        }
                                return $RI;
                        }
        }


sub registrationNotification 
        {
                my $registration;
             	BEGININGREG:    $ob->write("AT+SBDREG?\r");
                debug("Checking registratin");
                sleep(1);

                $rx = $ob->read(255);

                if ($rx =~ m/SBDREG/)
                        {
                                my @array = split(':',$rx);
                                my $array;
                                $registration = $array[1];
                                $registration = substr( $registration,0,1);
                                if ($registration == 0)
                                        {
                                                $ob->write("AT+SBDREG\r");
                                                debug("Will register again");
                                                sleep(1);
                                                $rx = $ob->read(255);
                                                if ($rx =~ m/OK/)
                                                        {
                                                                goto BEGININGREG;
                                                        }
                                        }

                        }

                debug("Registration done : $registration");
                $ob->write("AT+SBDMTA=1\r");
                sleep(1);
                $rx = $ob->read(255);
                 if ($rx =~ m/OK/)
                        {
                             debug("Notification enabled");
 			}                  	

        }


sub signalNetwork{


                $ob->write("AT+CIER=1,1,1,0\r");
                debug("Checking network and signal strenght");
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
                                                                                debug("Network available");
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

sub satCom 
        {
                BEGININGSAT:
                signalNetwork();        # check the network and wait for good signal
                debug("Executing SBDIXA command");

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

                debug("Status before download -> MO: $MO, MOMSN: $MOMSN, MT: $MT, MTMSN: $MTMSN, numOfMessages: $numOfMessages");

                if ($MO == 0)   # MO=0 - transfered ok, MO=1 

                        {
                                $ob->write("AT+SBDD0\r");
                                sleep(1);
                                $rx = $ob->read(255);
                                if ($rx =~ m /0/)
                                        {

                                                debug("Message sent and MO buffer cleaned");
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
                                debug("There is a MT in the buffer");
                                $inMessage = readMessage();
                               # processMessage();
                        }
                if ($numOfMessages > 1)
                        {
                                debug("More mesages waiting at GSS, will get them.");
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
                                        debug("Buffer MT cleaned succesfully");
                                }
                        debug("Received message is: $inMessage");


                                if ($inMessage =~ m/%%/)        # check if this is regular mail or command
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
                                debug("One message to be send from MO");
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


1;
