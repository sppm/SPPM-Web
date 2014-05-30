#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'SPPM-Web';
all_from 'lib/SPPM/Web.pm';

requires 'Catalyst::Runtime' => '5.90051';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General';



# view
requires 'Catalyst::View::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';

# minify css/js
requires 'Catalyst::Plugin::Assets';
requires 'JavaScript::Minifier::XS';
requires 'CSS::Minifier::XS';

# uma hora ou outra aparece um modulo falando que falta estes dois caras aqui:
requires 'MooseX::MarkAsMethods';
requires 'MooseX::NonMoose';

# tests
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
