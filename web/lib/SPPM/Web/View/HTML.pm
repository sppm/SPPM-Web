package SPPM::Web::View::HTML;
use Moose;
use utf8;

extends 'Catalyst::View::Xslate';

has '+syntax' => (
    default => sub {'TTerse'},
);

has '+path' => (
    builder => '_build_path',
);

has '+encode_body' => (
    default => sub {'0'},
);

sub _build_path { return [ shift->_app->path_to('root', 'src') ] }

has '+module' => (
    default => sub {
        ['Text::Xslate::Bridge::TT2Like'];
    }
);

my @meses = qw/
    Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro
/;

sub month_br {
    my ($self, $c, $x) = @_;
    return $meses[$x-1];
}

1;

=head1 NAME

SPPM::Web::View::HTML - Xslate View for SPPM::Web

=head1 DESCRIPTION

Xslate View for SPPM::Web.

=cut
