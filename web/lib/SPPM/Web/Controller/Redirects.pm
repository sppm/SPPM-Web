package SPPM::Web::Controller::Redirects;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }


sub test_redirect: Private {
    my ($self, $c, $args) = @_;

    my $path = $c->req->uri->path;
    use DDP; p $path;



}

__PACKAGE__->meta->make_immutable;

1;
