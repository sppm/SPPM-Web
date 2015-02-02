#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'SPPM-Web';
all_from 'lib/SPPM/Web.pm';

requires 'Catalyst::Runtime' => '5.90082';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose', '2.1403';
requires 'namespace::autoclean', '0.24';
requires 'Config::General';
requires 'Catalyst::Model::DBIC::Schema';
# basic deps:
requires 'DateTime';
requires 'FindBin';
requires 'File::Basename';
requires 'JSON::XS';
requires 'Text2URI';
requires 'File::Slurp::Tiny';
# Database related
requires 'DBD::Pg' => '3.4.2';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::TimeStamp';
requires 'DateTime::Format::Pg';
requires 'App::Sqitch';

# parsing de artigos
requires 'HTML::TreeBuilder::XPath';
requires 'Pod::Xhtml';


# not really dep, but good
requires 'Data::Printer';

# view
requires 'Catalyst::View::Xslate', '0.00018';
requires 'Text::Xslate::Bridge::TT2Like';

# minify css/js
requires 'Catalyst::Plugin::Assets';
requires 'JavaScript::Minifier::XS';
requires 'CSS::Minifier::XS';

requires 'Mojo::DOM';

# uma hora ou outra aparece um modulo falando que falta estes dois caras aqui:
requires 'MooseX::MarkAsMethods', '0.15';
requires 'MooseX::NonMoose', '0.26';

# tests
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
