package SPPM::Web::Controller::Pages;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }


sub base: Chained('/root') PathPart('pages') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub object: Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $page_name) = @_;

    $page_name =~ s/[^-a-z0-9]+//go;

    # existe o arquivo ?
    if (-e $c->path_to('root', 'src', 'pages', "$page_name.tx")){

        $c->stash->{content_template} = "pages/$page_name.tx";

    }else{
        # 404
        $c->forward('/default');
        $c->detach;
    }

}

sub render: Chained('object') PathPart('') Args(0) {

}

__PACKAGE__->meta->make_immutable;

1;
