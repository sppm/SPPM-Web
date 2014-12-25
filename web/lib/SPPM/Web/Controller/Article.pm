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
        $c->forward('/default');
        $c->detach;
    }

    my $article = $c->model('DB::Article')->search({
        id => $id
    }, {
        prefetch => 'author_hash'
    })->next;

    unless ($article){
        # 404
        $c->forward('/default');
        $c->detach;
    }

    if ($article->uri_path ne $page_name ){
        my $x = $c->uri_for_action('/article/show', [$article->id, $article->uri_path]  );
        $c->response->redirect( $x, 302 );
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
