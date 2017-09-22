#!/usr/bin/perl

################################################################################################
#
# parseLogs.pl
#
# Author: Robert Gray
#
# Licence: No rights reserved ¯\_(ツ)_/¯
#
# Custom perl script to parse apache access logs
#
################################################################################################


use strict;
use warnings;

#  _ _      _____      _____ 
# / / \|\ |(_  | /\ |\ ||(_  
# \_\_/| \|__) |/--\| \||__)
#

# Log Format 
# "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %{imagereader_source}n %{php_time_microsec}n %D" combined
# 213.48.246.107 - - [22/Sep/2017:15:36:08 +0100] "POST /?0-1.IFormSubmitListener-headerPanel-headerContainer-search-searchFormTabsPanel-packageSearchPanel-inputForm HTTP/1.1" 301 - "https://www.topflight.ie/" "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"

# Regular Expression for parsing the above log format
my $REGEX = '^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|-).* (\S+) (\S+) \[([\w:/]+\s[+\-]\d{4})\] "(\S+)\s?(\S+)?\s?(\S+)?" (\d{3}|-) (\d+|-)\s?"?([^"]*)"?\s?"?([^"]*)';

my %STATUS_TABLE = (    200 => "OK" , 
                        304 => "NOT MODIFIED" ,
                        404 => "NOT FOUND",
                        301 => "MOVED PERMANENTLY",
);
  
my $REQ_SUCCESS_MESSAGE = "Successfull Requests: ";
my $REQ_FAILURE_MESSAGE = "Un-successfull requests: ";

#         ___     
# |\/| /\  | |\ | 
# |  |/--\_|_| \| 
#

# Prints the header
GetHeader();

# Calls the main subroutine
Main();

sub Main {	
    
    my $LOGFILE = $ARGV[0];
    if ($LOGFILE =~ /^-h|--help$/) {
        print "Usage: $0 log_file.log\n";
        exit(0);
    }
    
    open my $fh, '<', $LOGFILE or die "Could not open '$LOGFILE': $!";
    
    my $reqCounter = 0;
    my $reqSuccessCounter = 0;
    my $reqFailureCounter = 0;
    my %reqFailureList;
    my @ipAddressList;
    my $UniqIpAddressCount = 0;
    my @fileSizesList;
    
    while (my $line = <$fh>) {
        my @logValue = $line =~ $REGEX;
        my $status = $logValue[7];
        my $uri = $logValue[5];
        my $source = $logValue[0];
        my $bytes = $logValue[8];
        
        # Count the number of requests for sanity checking
        $reqCounter++;
        
        # How many requests were successful?
        if ($status && $status eq '200') {
            $reqSuccessCounter++;
        }
        
        # Were any of the requests unsuccessful
        if ($status && ($status eq '404' || $status eq '500' )) {
            $reqFailureCounter++;
            $reqFailureList{$uri} = $status;
        }
        
        # How many unique IP addresses
        if ($source && $source ne '-') {
            push @ipAddressList, $source;
        }

        # What was the largest object served
        if ($bytes && $bytes ne '-') {
            push @fileSizesList, $bytes;
        }
        
        
        my $timeStamp = $logValue[3];
        my $requestType = $logValue[4];
        
        #print $bytes . "\n";
    }
    
    GetDoubleLineBreak();
    print $REQ_SUCCESS_MESSAGE . $reqSuccessCounter . "\n";
    print $REQ_FAILURE_MESSAGE . $reqFailureCounter . "\n";
    print "Largest object served: " . GetMaxBytes(@fileSizesList) . "\n";
    print "Average size of objects served: " . GetAvgBytes(@fileSizesList) . "\n";
    
    if (@ipAddressList > 0) {
        $UniqIpAddressCount = scalar uniq(@ipAddressList);
        print "Uniq IP Address Count: " . $UniqIpAddressCount . " of " . scalar @ipAddressList . "\n";
    }
    
    print "Total number of requests: " . $reqCounter . "\n";
    
    if ($reqFailureCounter > 0) {
        print "\nFailed URI Requests\n";
        GetLineBreak();
        # Print the URI's that failed and why
        my($reqUri, $statusCode);  # @cc{Declare two variables at once}
        while ( ($reqUri, $statusCode) = each(%reqFailureList) ) {
            print $reqUri . " | Status Code | " . $statusCode . " | " . $STATUS_TABLE{$statusCode} . "\n\n";
        }
    }
    
    exit;
}

sub GetHeader {
    print <<'END';
             _                      _                    
            | |    ___   __ _  __ _| |_   _ _______ _ __ 
            | |   / _ \ / _` |/ _` | | | | |_  / _ \ '__|
            | |__| (_) | (_| | (_| | | |_| |/ /  __/ |   
            |_____\___/ \__, |\__,_|_|\__, /___\___|_|   
                        |___/         |___/
            ---------------------------------------------
             Created by Rob Gray 2018 no rights reserved
            
            
END
}

sub GetLineBreak {
    print <<'END';
---------------------------------------------------------------------           
END
}

sub GetDoubleLineBreak {
    print <<'END';
=====================================================================           
END
}

sub uniq (@) {
    my %h;
    map { $h{$_}++ == 0 ? $_ : () } @_;
}

sub GetMaxBytes {
    my @array = @_;
    my $max;

    for (@array) {
        $max = $_ if !$max || $_ > $max
    };
    return $max . " Bytes";
}

sub GetAvgBytes {
    my @array = @_;
    my $count = 0;
    my $total;

    for (@array) {
        $total += $_;
        $count++;
    };
    print "total byes is " . $total . "\n";
    return $total / $count . " Bytes";
}

