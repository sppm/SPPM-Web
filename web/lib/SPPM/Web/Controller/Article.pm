package SPPM::Web::Controller::Article;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }


sub base: Chained('/root') PathPart('pub') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub object: Chained('base') PathPart('') CaptureArgs(2) {
    my ($self, $c, $id, $page_name) = @_;

    unless ($id && $id =~ /^[0-9]{1,11}$/){
        # 404
        $c->forward('/default', [ 1 ]);
        $c->detach;
    }

    my $article = $c->model('DB::Article')->search({
        id => $id
    }, {
        prefetch => 'author_hash'
    })->next;

    unless ($article){
        # 404
        $c->forward('/default', [ 1 ]);
        $c->detach;
    }

    $c->stash->{article} = $article;

    $c->stash->{content_template} = 'article.tx';

    $c->stash->{title} = $article->title;

}

sub show: Chained('object') PathPart('') Args(0) {

}

__PACKAGE__->meta->make_immutable;

1;
