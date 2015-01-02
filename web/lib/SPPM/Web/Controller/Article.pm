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

    $page_name = lc $page_name;

    my $rs = $c->model('DB::Article');

    my $article = $rs->search({
        uri_path => $page_name
    }, {
        prefetch => 'author_hash'
    })->next;

    $self->_deep_article_search( $c, $rs, $page_name ) unless $article;

    unless ($article){
        # 404
        $c->forward('/default');
        $c->detach;
    }

    $c->stash->{article} = $article;

    $c->stash->{content_template} = 'article.tx';

    $c->stash->{title} = $article->title;

}

sub _deep_article_search {
    my ($self, $c, $rs, $page_name) = @_;

    my @list = split /-/, $page_name;
    return unless @list;

    # primeira tentativa:
    # titulos digitados incompletos (no final apenas)
    my $qtde = scalar @list;
    my $run = 0;

    while ($run < $qtde){
        $run++;
        my $start = join '-', @list[ 0 .. $qtde-$run];

        my $article = $rs->search({
            uri_path => { like => "$page_name%" }
        }, {
            columns => ['uri_path']
        })->next;

        if ($article){
            my $x = $c->uri_for_action('/article/show', [$article->uri_path] );
            $c->response->redirect( $x );
            $c->detach;
        }
    }


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
        order_by => [ {-desc => 'me.published_at'}, qw/me.title/]
    })->all;

    $c->stash->{articles} = \@rows;


    $c->stash->{content_template} = 'list-article.tx';
}

__PACKAGE__->meta->make_immutable;

1;
