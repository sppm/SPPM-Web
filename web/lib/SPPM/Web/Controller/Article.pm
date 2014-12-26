package SPPM::Web::Controller::Article;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }


sub base: Chained('/root') PathPart('pub') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub object: Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $page_name) = @_;

    unless ($page_name){
        # 404
        $c->forward('/default');
        $c->detach;
    }

    my $article = $c->model('DB::Article')->search({
        uri_path => $page_name
    }, {
        prefetch => 'author_hash'
    })->next;


    unless ($article){
        # 404
        $c->forward('/default');
        $c->detach;
    }

    $c->stash->{article} = $article;

    $c->stash->{content_template} = 'article.tx';

    $c->stash->{title} = $article->title;

}

sub show: Chained('object') PathPart('') Args(0) {

}

sub list: Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{author_hash} = exists $c->req->params->{author_hash} && $c->req->params->{author_hash}
        ? $c->req->params->{author_hash}
        : undef;

    $c->stash->{author} = $c->model('DB::Author')->search({ author_hash => $c->stash->{author_hash} } )->next
        if $c->stash->{author_hash};

    my @rows = $c->model('DB::Article')->search({
        published => 1,
        (
            $c->stash->{author_hash}
            ? ('me.author_hash' => $c->stash->{author_hash})
            : ()
        )
    }, {
        prefetch => 'author_hash',
        order_by => [qw/me.published_at me.created_at me.title/]
    })->all;

    $c->stash->{articles} = \@rows;


    $c->stash->{content_template} = 'list-article.tx';
}

__PACKAGE__->meta->make_immutable;

1;
