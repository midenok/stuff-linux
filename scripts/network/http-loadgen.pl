#!/usr/bin/perl
use strict;
use HTTP::LoadGen;
use Socket;
use Data::Dumper;

die "Usage: $0 proxy server url_list\n"
    if @ARGV < 3;

$ARGV[0] =~ m/^([^:]+)(:(\d+))?$/;

my %C = (
    proxy => $1,
    proxy_port => $3 ? $3 : 80,
    server => $ARGV[1],
    url_list => $ARGV[2],
    progress_step => 3 # in seconds
);

$C{proxy_ip} = inet_ntoa((gethostbyname($C{proxy}))[4]);

my %loadgen = (
    NWorker => 1,
    RampUpStart => 100,
    RampUpMax => 100,
    RampUpDuration => 0,
    InitURLs => \&url_iterator_init,
    ReqDone => \&request_done
);

HTTP::LoadGen::loadgen \%loadgen;

sub url_iterator_init
{
    open FH, '<', $C{url_list}
        or die "$C{url_list}: $!";
    return \&url_iterator;
}

sub url_iterator
{
    $_ = <FH>;
    return undef
        unless defined $_;
    m/^(\d+\.){3}\d+ - - \[[^\]]+\] "GET ([^"]+) HTTP\/1\.\d" [\d-]+ [\d-]+ "([^"]+)" "([^"]+)"/;
    my $uri = $2;
    my $referer = $3;
    my $useragent = $4;
    my $server = $C{server};

    if ($uri =~ m|^/ps/|
        || $uri =~ m|^/tag/|
        || $uri =~ m|^/toolbar/|) {
        $server = 'b.' . $server;
    } elsif ($uri =~ m|^/tags/|) {
        $uri = '/tags/0/34/71beda2.html';
        $server = 'oixssp-stage.net';
    } elsif ($uri =~ m|^/creatives(/.+)$|) {
        if ($1) {
            $uri = '/creatives/banner_flash_multiclk.html';
        }
        $server = 'oixcrv-stage.net';
    } else {
        $server = 'a.' . $server;
    }

    my $headers = [ Host => $server ];
    if ($referer ne "-") {
        push @$headers, (Referer => $referer);
    }
    if ($useragent ne "-") {
        push @$headers, ('User-Agent' => $useragent);
    }

    if ($uri =~ m|^/services/obind|) {
        push @$headers, (Cookie => "uid=Bjr0Q8UwSIGsAZzdURwmGg..; OPTED_IN=1");
    }

    return ['GET', 'http', $C{proxy_ip}, $C{proxy_port}, $uri,
        {
            headers => $headers
        }];
}

my $progress_next = time();
my $reqs_prev = 0;
my $reqs_now = 0;
my %resp_stats;
my %resp_details;

STDOUT->autoflush(1);

sub request_done
{
    my $rc = shift;
    my $rq = shift;

    my $resp_code = $rc->[0];
    ++$resp_stats{$resp_code};

    if ($resp_code >= 400) {
        $rq->[4] =~ m/^([^?]+)/;
        ++($resp_details{$resp_code}->{$1});
    }

    $reqs_now++;
    my $now = time();
    return
        unless $now > $progress_next;

    my $reqs_per_sec = int(($reqs_now - $reqs_prev) / $C{progress_step});
    $reqs_prev = $reqs_now;
    my $resp_stats;
    map { $resp_stats .= " ${_}: $resp_stats{$_}" } sort keys %resp_stats;
    $progress_next = $now + $C{progress_step};
    print $reqs_per_sec, " reqs/sec, requests: ${reqs_now}, ${resp_stats}", "\n";
    print Dumper(\%resp_details);
}
