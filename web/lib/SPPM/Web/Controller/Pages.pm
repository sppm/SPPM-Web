package SPPM::Web::Controller::Pages;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

my %actions = (
    'quem-somos' => sub {
        my ($self, $c) = @_;

        my @rows = $c->model('DB::Article')->search({
            published => 1,
        }, {
            columns => ['me.author_hash', 'author_hash.name'],
            group_by => ['me.author_hash', 'author_hash.name', 'author_hash.author_hash'],
            order_by => \'random()',
            rows => 12,
            prefetch => 'author_hash'
        })->all;

        $c->stash->{authors} = {map { $_->get_column('author_hash') => $_->author_hash->name } @rows};


    }
);

sub base: Chained('/root') PathPart('pagina') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub object: Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $page_name) = @_;

    $page_name =~ s/[^-a-z0-9]+//go;

    # existe o arquivo ?
    if (-e $c->path_to('root', 'src', 'pages', "$page_name.tx")){

        $c->stash->{content_template} = "pages/$page_name.tx";

        $actions{$page_name}($self, $c) if exists $actions{$page_name};

    }else{
        # 404
        $c->forward('/default');
        $c->detach;
    }

}

sub show: Chained('object') PathPart('') Args(0) {

}

__PACKAGE__->meta->make_immutable;

1;
