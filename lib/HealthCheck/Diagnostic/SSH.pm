package HealthCheck::Diagnostic::SSH;

use strict;
use warnings;

use parent 'HealthCheck::Diagnostic';

use Net::SSH::Perl;

use Data::Dumper;
# ABSTRACT: Verify SSH connectivity to specified host
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

Checks and verifies connection to SSH

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::SSH->new(
            host    => 'smtp.gmail.com',
            timeout => 5,
        )
    ]);


=head1 DESCRIPTION

