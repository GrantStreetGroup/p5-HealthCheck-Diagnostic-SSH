use strict;
use warnings;

use Test::More import => [ qw( use_ok is like is_deeply done_testing diag ) ];
use Test::MockModule ();
use Sys::Hostname qw(hostname);

BEGIN { use_ok('HealthCheck::Diagnostic::SSH') };

diag(qq(HealthCheck::Diagnostic::SSH Perl $], $^X));

# check that expected errors come out properly
my $hc = HealthCheck::Diagnostic::SSH->new;
my $res;

$res = $hc->check;
is $res->{info}, "Missing required input: No host specified",
    'Expected check error with no host';

# Mock a SSH connection and its relevant subroutines for this healthcheck to
# verify output is correct
my $mock = Test::MockModule->new( 'Net::SSH::Perl' );
$mock->mock( new => sub {
    # Mock the SSH module so that we can pretend to have bad hosts.
        my ( $class, $host, %params ) = @_;
        # In-accessible hosts should not be reached.
        die "Net::SSH::Perl: Bad host name: $host"
            if $host eq 'inaccessible-host';

        $params{host} = $host;

        return bless( \%params, 'Net::SSH::Perl' );
    })->mock( login => sub {
    # Mock the SSH module so that we can pretend to have bad logins
        my ( $class, $user ) = @_;
        my $host = $class->{host};

        die "Permission denied for $user at $host" if $user eq 'invalid-user';
    })->mock( cmd => sub {
    # Mock the SSH module so that we can pretend to throw errors on commands
    # ran through a SSH connection
        my ( $class, $command, $stdin ) = @_;

        return ( undef, "error msg at line#", 255) if $command eq 'throw error';
        return ( "sample std_out", undef, 0);
    }
);

# Run with a bad host name
$res = $hc->check( host => 'inaccessible-host');
is   $res->{status}, 'CRITICAL', 'Cannot run with bad host';
like $res->{info}  , qr/Net::SSH::Perl: Bad host name: inaccessible-host/,
    'Connection error displayed correctly';

# default input for further tests
my $host = 'good-host';
my $user = 'good-user';
my %default = (
    host     => $host,
    user     => $user,
    ssh_args => {
        identity_files => [ 'valid_path/valid_file' ]
    },
);
my %success_res = (
    id     => 'ssh',
    label  => 'SSH',
    status => 'OK',
    data   => {},
);

$hc = HealthCheck::Diagnostic::SSH->new( %default );
$res = $hc->check;
is_deeply $res, {
        %success_res,
        info   => "Successful connection for $user\@$host SSH",
    }, "Healthcheck completed using local user credentials";

# health check should fail with incorrect user overriden
$res = $hc->check( user => 'invalid-user' );
like $res->{info}, qr/invalid-user.*Permission denied/,
    "Healthcheck result displays overridden parameters";
is $res->{status}, 'CRITICAL',
    "Healthcheck fails with wrong user";

# health check displays the correct message and should pass as the previous
# override should not persist
my $name = 'HealthCheck SSH in test';
$res = $hc->check( name => $name );
is_deeply $res, {
        %success_res,
        info   => "Successful connection for $name ($user\@$host) SSH",
    }, "Healthcheck passed with correct display";

# check that it can display cmd outputs
$res = $hc->check( command => "good command", display => 1 );
is $res->{status}, 'OK', "HealthCheck ran with command input";
is $res->{data}->{stdout}, 'sample std_out',
    "Stdout shows proper output based on the command input";

# run commands that generate errors
$res = $hc->check( command => 'throw error' , display => 1 );
is $res->{status}, 'CRITICAL', 'Healthcheck failed correctly';
is $res->{data}->{exit_code}, 255, 'Healthcheck exit code presented correctly';
is $res->{data}->{stderr}, 'error msg at line#', 'Healthcheck error saved properly';
like $res->{info}, qr/Error for .*: Ran .*/,
    'Healthcheck error correctly displayed';

# check that the stdout and stderr only displays when told to
$res = $hc->check( command => "good command" );
is_deeply $res, {
        %success_res,
        info   => "Successful connection for $user\@$host SSH: Ran 'good command'",
        data   => {
            exit_code => 0,
            command   => 'good command'
        },
    }, 'Commandline results only show if "display" input is specified';

done_testing;
