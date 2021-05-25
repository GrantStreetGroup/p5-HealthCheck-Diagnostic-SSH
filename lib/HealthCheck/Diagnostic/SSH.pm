package HealthCheck::Diagnostic::SSH;

use strict;
use warnings;

use parent 'HealthCheck::Diagnostic';

use Net::SSH::Perl;

# ABSTRACT: Verify SSH connectivity to specified host.
# VERSION

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    return $class->SUPER::new(
        id     => 'ssh',
        label  => 'SSH',
        %params,
    );
}

sub check {
    my ($self, %params) = @_;

    # Make it so that the diagnostic can be used as an instance or a
    # class, and the `check` params get preference.
    if ( ref $self ) {
        $params{ $_ } = $self->{ $_ }
            foreach grep { ! defined $params{ $_ } } keys %$self;
    }

    # The host is the only required parameter.
    return {
        id     => $params{'id'},
        label  => $params{'label'},
        status => 'UNKNOWN',
        info   => "No host specified",
    } unless $params{host};

    return $self->SUPER::check(%params);
}

sub run {
    my ($self, %params) = @_;

    # required host
    my $host          = $params{host};
    # command related params
    my $command       = $params{command};
    my $stdin         = $params{stdin};
    # Get our description of the connection.
    my $user          = $params{user};
    my $name          = $params{name};
    my $target        = ( $user ? $user.'@' : '' ).$host;
    my $description   = $name ? "$name ($target) SSH" : "$target SSH";

    my $return_critical = sub {
        my ( $error, $add_args ) = @_;

        return {
            status => 'CRITICAL',
            info   => "Error for $description: $error",
            %{ $add_args // {} },
        };
    };

    # connect to SSH
    my $ssh;
    local $@;
    eval {
        local $SIG{__DIE__};
        $ssh = $self->ssh_connect( \%params );
    };
    return $return_critical->( $@ ) if $@;

    # if there were no errors, it should've connected
    return {
        status => 'OK',
        info   => "Successful connection for $description",
    } unless $command;

    # run command if exists
    my $results;
    eval {
        local $SIG{__DIE__};
        $results = $self->run_command(
            $ssh, $command, $stdin
        );
    };
    return $return_critical->( $@ ) if $@;

    # return additional arguements whether it's an error
    my $add_arg = {
        command => $command,
        map { $_ => $results->{ $_ } } qw( stdout stderr exit_code )
    };
    return $return_critical->( "Error running '$command'\n".$results->{stderr},
            $add_arg )
        if $results->{exit_code};
    return {
        status  => 'OK',
        info    => "Successful connection for $description: Ran '$command'",
        %$add_arg
    };
}

sub ssh_connect {
    my ( $self, $params ) = @_;

    my $host       = $params->{host};
    my $user       = $params->{user};
    my $password   = $params->{password};
    my %ssh_params = (
        protocol => 2,
        %{ $params->{ssh_args} // {} },
    );

    my $ssh = Net::SSH::Perl->new( $host, %ssh_params );
    $ssh->login( $user, $password );

    return $ssh;
}

sub run_command {
    my $self = shift;
    my $ssh  = shift;
    my ( $command, $stdin ) = @_;

    my ( $stdout_string, $stderr, $exit_code ) = $ssh->cmd( $command, $stdin );

    return {
        stdout    => $stdout_string,
        stderr    => $stderr,
        exit_code => $exit_code
    };
}

1;
__END__

=head1 SYNOPSIS

Checks and verifies connection to SSH.
Can optionally run commands through the connection.

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::SSH->new(
            host => 'somehost.com',
            user => 'some_user,
        )
    ]);

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::SSH->new(
            host     => 'somehost.com',
            user     => 'some_user,
            ssh_args => {
                identity_files => [ '~/user/somepath/privatefile' ]
            },
            command  => 'echo "Hello World!"',
        )
    ]);


=head1 DESCRIPTION

Determines if a SSH connection to a host is achievable. Sets the
C<status> to "OK" if the connection is successful and we can run the optional
C<command> parameter. The C<status> is set to "UNKNOWN" if required parameters
are missing. Otherwise, the C<status> is set to "CRITICAL".

=head2 host

The server name to connect to for the test.
This is required.

=head2 name

A descriptive name for the connection test.
This gets populated in the resulting C<info> tag.

=head2 user

Optional argument that can get passed into C<login> method of L<Net::SSH::Perl>.
Represents the authentication user credential for the host.

=head2 password

Optional argument that can get passed into C<login> method of L<Net::SSH::Perl>.
C<identity_files> in L<ssh_args> can be used to authenticate by default.
Represents the authentication password credential for the host.

=head2 ssh_args

Optional argument that can get passed into the L<Net::SSH::Perl> constructor.
Additional SSH connection parameters.
Only default parameter is the protocol set as 2.
C<identity_files> can be set in here to authenticate using the files by default.

=head2 command

Optional argument that can get passed into C<cmd> method of L<Net::SSH::Perl>.
If provided, runs command and outputs it into C<stdout> tag. An error output
from running the command would result in a non-zero value of C<exit_code> tag
and error message in C<stderr> tag.

=head2 stdin

Optional argument that can get passed into C<cmd> method of L<Net::SSH::Perl>.
If provided, it's supplied to the L<command> on standard input.

=head1 DEPENDENCIES

=over 4

=item *

L<HealthCheck::Diagnostic>

=item *

L<Net::SSH::Perl>

=back
