#!/usr/bin/perl
use warnings;

sub debug 
        {
                my $text = shift;
                if ($debug == 2)
                        {
                                open LOG, '>>/mnt/sdcard/log/main.log' or die "Can't write to /mnt/sdcard/log/main.log: $!";
                                select LOG;
                                my $time = gmtime();
                                my @arrayTime = split(/ /,$time);
                                my $arrayTime;
                                 $time = "$arrayTime[1]"."$arrayTime[2]"." ". "$arrayTime[4]".","."$arrayTime[3]";


                                print "$time: $text\n";
                                select STDOUT;
                                close (LOG);
                        }
                if ($debug == 1)
                        {
                                my $time = gmtime();
                                my @arrayTime = split(/ /,$time);
                                my $arrayTime;
                                $time = "$arrayTime[1]"."$arrayTime[2]"." ". "$arrayTime[4]".","."$arrayTime[3]";

                                print "$time: $text\n";
                        }

        }

1;
