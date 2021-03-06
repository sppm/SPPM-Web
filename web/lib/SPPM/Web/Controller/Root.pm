package SPPM::Web::Controller::Root;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=encoding utf-8

=head1 NAME

SPPM::Web::Controller::Root - Root Controller for SPPM::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut


sub root : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # funciona mais como wrapper do que template, mas blz.
    $c->stash->{template} = 'html5_template.tx';
}

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    # nao tente fazer chain. serio. nao no index
    $self->root($c);

    my @rows = $c->model('DB::Article')->search({
        published => 1,
        uri_path => [
            'primeiros-passos-em-perl',

        ]
    }, {
        prefetch => 'author_hash',
        order_by => [ qw/me.title/]
    })->all;


    push @rows, $c->model('DB::Article')->search({
           published => 1,
           uri_path => {
             '!=' => 'primeiros-passos-em-perl',
           },
        
    }, {
        prefetch => 'author_hash',
        order_by => \'random()',
        rows => 8
    })->all;


    $c->stash->{articles} = \@rows;

    my @rows2 = $c->model('DB::Article')->search({
        published => 1,
        published_at => {
            '>=' => '2015-03-01',
            '<=' => '2015-03-21'
        },
    }, {
        prefetch => 'author_hash',
        order_by => [ qw/me.published_at/]
    })->all;

    $c->stash->{equinox_articles} = \@rows2;

    # nome do include.
    $c->stash->{content_template} = 'index.tx';
}

sub default : Path {
    my ( $self, $c) = @_;

    # tenta verificar se a pagina não precisa de um redirect do site antigo
    $c->forward('Controller::Redirects', 'test_redirect');

    # nao tente fazer chain. serio. nao no default
    $self->root($c);

    $c->response->status(404);
    $c->stash->{content_template} = '404.tx';

}

sub end : ActionClass('RenderView') { }

=head1 AUTHOR

renato,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
