# NAME

HealthCheck::Diagnostic::SSH - Verify SSH connectivity to specified host.

# VERSION

version v0.1.0

# SYNOPSIS

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
            command       => 'echo "Hello World!"',
            return_output => 1,
        )
    ]);

# DESCRIPTION

Determines if a SSH connection to a host is achievable. Sets the
`status` to "OK" if the connection is successful and we can run the optional
`command` parameter. The `status` is set to "UNKNOWN" if required parameters
are missing. Otherwise, the `status` is set to "CRITICAL".

## host

The server name to connect to for the test.
This is required.

## name

A descriptive name for the connection test.
This gets populated in the resulting `info` tag.

## user

Optional argument that can get passed into `login` method of [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl).
Represents the authentication user credential for the host.

For more information, see ["login" in Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl#login).

## password

Optional argument that can get passed into `login` method of [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl).
`identity_files` in [ssh\_args](https://metacpan.org/pod/ssh_args) can be used to authenticate by default.
Represents the authentication password credential for the host.

## ssh\_args

Optional argument that can get passed into the [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl) constructor.
Additional SSH connection parameters.
Only default parameter is the protocol set as 2.
`identity_files` can be set in here to authenticate using the files by default.

For more information on the possible arguments, refer to [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl).

## command

Optional argument that can get passed into `cmd` method of [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl).
If provided, runs command and prints output into `data` depending on the
value of ["display"](#display) input. An error output from running the command would
result in a non-zero value of `data-`exit\_code> which is always provided.
If `display` is enabled, output of the command is shown in `data-`stdout>
and an error message, if any, is stored in `data-`stderr>.

## stdin

Optional argument that can get passed into `cmd` method of [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl).
If provided, it's supplied to the [command](https://metacpan.org/pod/command) on standard input.

## return\_output

Optional argument that determines whether output of [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl)->`cmd`
should be displayed. If provided a truthy value, (preferrably 1 for clarity)
the `data` field of the output will be populated with `stdout` and `stderr`.
If ommitted, only the `exit_code` will show by default as noted in ["command"](#command).

# DEPENDENCIES

- [HealthCheck::Diagnostic](https://metacpan.org/pod/HealthCheck%3A%3ADiagnostic)
- [Net::SSH::Perl](https://metacpan.org/pod/Net%3A%3ASSH%3A%3APerl)

# AUTHOR

Grant Street Group <developers@grantstreet.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 - 2023 by Grant Street Group.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
