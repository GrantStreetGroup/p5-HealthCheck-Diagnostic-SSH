# Add your requirements here
requires 'perl', 'v5.10.0'; # for kwalitee
#requires 'App::Cmd', '== 0.331'; # avoid minimum perl version update from 0.332+
#requires 'Pod::Weaver', '< 4.016';

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
