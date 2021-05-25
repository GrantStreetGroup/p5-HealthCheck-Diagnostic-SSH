# Add your requirements here
requires 'perl', 'v5.10.0'; # for kwalitee
requires 'strict';
requires 'warnings';
requires 'parent';

requires 'HealthCheck::Diagnostic';
requires 'Net::SSH::Perl';

on test => sub {
    requires 'Test::Differences';
    requires 'Test::MockModule';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
