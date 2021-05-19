use Test2::V0 -target => 'HealthCheck::Diagnostic::SSH',
    qw< ok diag done_testing >;

diag(qq($CLASS Perl $], $^X));

ok CLASS, "Loaded $CLASS";

done_testing;
