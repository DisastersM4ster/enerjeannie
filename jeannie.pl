#!/usr/bin/perl -w

use strict;
use LWP::UserAgent;
use Getopt::Long;

##############
#
# variables have to be set to your environment
#
##############

my $password = 1;
# with a working DNS hostnames are possible
# if hostname does not resolv, insert an IP instead
my $host = "pms.example.com";

# here you can set aliases for your PMS
# it is for a better human readable solution
# you can set any word as device name
# duplicated socket numbers are possible
# even the key word have to be unique
# socket with number 0 is special => all sockets will set to state you defined
# syntax: 'keyword' => <socket_number>,
my %socketMap = (
	'socket_1' => '1',
	'socket_2' => '2',
	'socket_3' => '3',
	'socket_4' => '4', 
	'all' => '0', 
);

##############
#
# variables do not need any change
#
##############


my $ua = LWP::UserAgent->new;
my $req = "";
my $res = "";
my $postContentType = "application/x-www-form-urlencoded";
my $socketAlias = 'empty';
my $reqTargetState = 'off'; 
my $socketNumber = 1;
my $doLoop =  0;


my %targetState = ();
my %socketState = ();


##############
#
# END VARIABLES
#
##############


# initialize %targetState hash with 0 (switch off) 
for ($socketNumber = 1; $socketNumber < 4; $socketNumber++) {
	$targetState{"$socketNumber"} = 0;
	$socketState{"$socketNumber"} = 0;
}
$socketNumber = 0;

# read options from command line
GetOptions (
	'number|nummer|socket|sockel=i' => \$socketNumber,
	'device|geraet=s' => \$socketAlias,
	'state|status=s' => \$reqTargetState, 
);

$socketNumber = $socketMap{"$socketAlias"} if (defined($socketMap{"$socketAlias"}));

if ( $socketNumber == 0 ) {
	$socketNumber = 1;
	$doLoop = 1;
}

$ua->agent("Jeannie Switcher/0.1");
$req = HTTP::Request->new(GET => 'http://'.$host.'/');
$res = $ua->request($req);

if ($res->is_success) {
	&logIn || die "Cannot login to $host. Error: $res->status_line \n";
	&getSocketState;
} else {
	die "Host $host cannot be reached. Error: $res->status_line \n";
}

while ($socketNumber < 5) {
	if ( "$reqTargetState" =~ /on/i || "$reqTargetState" == 1 ) {
		$targetState{"$socketNumber"} = 1;
	} else {
		$targetState{"$socketNumber"} = 0;
	}

	if ( $targetState{"$socketNumber"} != $socketState{"$socketNumber"} ) {
		&setSocketState ( socketNumber => $socketNumber, socketState => $targetState{"$socketNumber"} );
	} else {
		print "Nothing to do.\n" if ($doLoop == 0);
	}

	if ($doLoop == 1) { 
		$socketNumber++;
	} else {
		$socketNumber = 5; 
	}
}

&logOut || die "Cannot logout from $host. Error: $res->status_line \n";
exit 0;

###############################################################################
#
# sub routines
#
###############################################################################

sub logIn {
	$req = HTTP::Request->new(POST => 'http://'.$host.'/login.html');
	$req->content_type("$postContentType");
	$req->content("pw=".$password."");
	$res = $ua->request($req);

	return $res->is_success;
}

sub logOut {
	$req = HTTP::Request->new(GET => 'http://'.$host.'/login.html');
	$res = $ua->request($req);

	return $res->is_success;
}

sub getSocketState {

	my @states = ();
	my ($site, $i, $state) = ("", 1,"");
	$req = HTTP::Request->new(GET => 'http://'.$host.'/status.html');
	$res = $ua->request($req);

	if ( $res->is_success ) {
		$site = $res->content;
		# should match the string ";var ctl = [0,0,0,0];"
#		$site =~ "s/\;var\sctl\s=\s\[([0|1],[0|1],[0|1],[0|1])\]\;/\1/i";
		$site =~ /\;var ctl = \[([0|1],[0|1],[0|1],[0|1])\]\;/i;
		if (defined($1)) {
			#print $1."\n";
			@states = split(/,/,$1);
			$i = 1;
			foreach my $state (@states) {
				$socketState{"$i"} = $state;
				#print "socketState{$i} = ".$socketState{"$i"}."\n";
				$i++;
			}
		}
		
	} else {
		warn "Could not request status page of $host. Error: $res->status_line \n";
	}
}

sub setSocketState {
	my %args = @_;
	my $socket = $args{'socketNumber'};
	my $state = $args{'socketState'};

	if ( $socket < 1 or $socket > 4 ) {
		warn "Socket number have to be between 1 and 4. Socket number given is: $socket \n";
	}

	if ( $state =~ m/on/i or $state == 1 ) {
		$state = 1
	} elsif ( $state =~ m/off/i or $state == 0 ) {
		$state = 0
	} else {
		warn "Socket state should be on or off. State given is: $state \n";
	}

	$req = HTTP::Request->new(POST => 'http://'.$host.'/');
	$req->content_type("$postContentType");
	$req->content('ctl'.$socket.'='.$state);
	$res = $ua->request($req);

	$res->is_success or warn "Could not change socket state of socket ".$socket." on ".$host."\nError: ".$res->status_line."\n";

}

__END__

=head1 NAME

jeannie.pl -- switches sockets of an energenie PMS LAN

=head1 SYNOPSIS

B<jeannie.pl> --number|nummer|sockel=0|1|2|3|4 --state=0|1

B<jeannie.pl> --device|geraet=<device_name> --state=0|1

=head1 DESCRIPTION

The script B<jeannie> switches the state of sockets of an B<energenie PMS LAN>.
You can switch on or off each single socket or all sockets at once. 

=over 4

=item B<--number|nummer|sockel=<socket_number>>

Valid values for a socket number is 1 to 4. You can choose 0, too. Number 0 is a special for all sockets.

=back

=over 4

=item B<--state=0|1>

You can switch on or off each socket by using --state. Value 0 switches off the socket. 
With value 1 you can switch it on. The script scans current state of the socket and switches only if needed.

=back

=head1 EXAMPLES

=over 4

=item switch on socket number 1

jeannie.pl --number=1 --state=1

=item switch off socket number 3

jeannie.pl --number 3 --state 0

=item switch off all sockets

jeannie.pl

=item switch in on all sockets

jeannie.pl --state=on

=back

