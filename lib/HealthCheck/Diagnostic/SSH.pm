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

    my $host        = $params{host};
    # Get our description of the connection.
    my $user        = $params{user};
    my $name        = $params{name};
    my $target      = ( $user ? $user.'@' : '' ).$host;
    my $description = $name ? "$name ($target) SSH" : "$target SSH";

    # connect to SSH
    my $ssh;
    local $@;
    eval {
        local $SIG{__DIE__};
        $ssh = $self->ssh_connect( \%params );
    };
    return {
        status => 'CRITICAL',
        info   => "Error for $description: $@",
    } if $@;

    # if there were no errors, it should've connected
    return {
        status => 'OK',
        info   => "Successful connection for $description",
    }
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
    $ssh->login($user, $password);

    return $ssh;
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

