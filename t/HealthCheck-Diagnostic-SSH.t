use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Differences;
use Sys::Hostname qw(hostname);

use Data::Dumper;

BEGIN { use_ok('HealthCheck::Diagnostic::SSH') };

diag(qq(HealthCheck::Diagnostic::SSH Perl $], $^X));

# check that expected errors come out properly
{
    my $hc = HealthCheck::Diagnostic::SSH->new;
    my $res;

    $res = $hc->check;
    is $res->{info}, "No host specified", 'Expected check error with no host';

    # Mock the SSH module so that we can pretend to have bad hosts.
    my $mock = Test::MockModule->new( 'Net::SSH::Perl' );
    $mock->mock( new => sub {
        my ( $class, $host, %params ) = @_;

        # In-accessible hosts should not be reached.
        die "Net::SSH::Perl: Bad host name: $host"
            if $host eq 'inaccessible-host';

        return bless( \%params, 'Net::SSH::Perl' );
    } );

    $res = $hc->check( host => 'inaccessible-host');
    is   $res->{status}, 'CRITICAL', 'Cannot run with bad host';
    like $res->{info}  , qr/Net::SSH::Perl: Bad host name: inaccessible-host/,
        'Connection error displayed correctly';
}

{
    my $host = hostname();
    my ($user, $home) = (getpwuid($>))[0, 7];

    my %default = (
        host     => $host,
        user     => $user,
        ssh_args => {
            identity_files => [ "$home/.ssh/id_dsa" ]  # Local private key file
        },
    );

    my $hc = HealthCheck::Diagnostic::SSH->new( %default );
    my $res;

    $res = $hc->check;
    is_deeply $res, {
            id     => 'ssh',
            label  => 'SSH',
            status => 'OK',
            info   => "Successful connection for $user\@$host SSH"
        }, "Healthcheck completed using local user credentials";

    # health check should fail with incorrect user overriden
    $res = $hc->check( user => 'test-ssh' );
    like $res->{info}, qr/test-ssh.*Permission denied/,
        "Healthcheck result displays overridden parameters";
    is $res->{status}, 'CRITICAL',
        "Healthcheck failed with wrong user";

    # health check displays the correct message and should pass as the previous
    # override should not persist
    my $name = 'HealthCheck SSH in test';
    $res = $hc->check( name => $name );
    is_deeply $res, {
            id     => 'ssh',
            label  => 'SSH',
            status => 'OK',
            info   => "Successful connection for $name ($user\@$host) SSH"
        }, "Healthcheck passed with correct display";
}

done_testing;
