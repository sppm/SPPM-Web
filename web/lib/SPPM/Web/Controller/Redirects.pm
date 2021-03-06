package SPPM::Web::Controller::Redirects;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }


sub test_redirect: Private {
    my ($self, $c, $args) = @_;

    my $path = $c->req->uri->path;

    if ($path eq '/principal'){
        $c->response->redirect( '/', 301 );
        $c->detach;
    }

    my $article = $c->model('DB::Article')->search({
        old_uri_path => substr($path, 1)
    })->next;


    if ($article){
        my $x = $c->uri_for_action('/article/show', [$article->uri_path]  );
        $c->response->redirect( $x, 301 );
        $c->detach;
    }

    if (my ($name) = $path =~ /\/artigo\/\d{4}\/(.+)$/){
        $name = lc $name;

        my $article = $c->model('DB::Article')->search(
            \[ 'replace(uri_path, \'-\',  \'\') = ?', $name ]
        )->next;


        if ($article){
            my $x = $c->uri_for_action('/article/show', [$article->uri_path]  );
            $c->response->redirect( $x, 301 );
            $c->detach;
        }
    }

}

__PACKAGE__->meta->make_immutable;

1;
