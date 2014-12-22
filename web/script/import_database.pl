#!/usr/bin/env perl

# Criado em 2014-07-05
# Script para importação dos artigos do site sao-paulo.pm.org
# Esta importação se refere apenas aos artigos. Equinocios estão em outro modelo.

use strict;
use utf8;
use File::Find;

use HTML::TreeBuilder::XPath;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use open qw/:std :utf8/;

my $root_src = "$Bin/../root/src/";

my $authors;
foreach my $base_dir (("$root_src/artigos")){

    find(sub {
        next if -d $File::Find::name;

        my $dir = "$File::Find::dir";
        my $qdir = quotemeta($base_dir);
        $dir =~ s/$qdir//;

        my $fname = $_;

        if ($fname !~ /.pod$/){
            # print "$_ is not a .POD\n";
            next;
        }

        print "root/artigos$dir/$fname\n";

        my ($artigo, $parser) = SPPM::Web::Model::Artigo->new->content( "$root_src/artigos/$dir/$fname" );

        my $tree  = HTML::TreeBuilder::XPath->new_from_content($parser->asString);

        my $title = eval{$tree->findnodes('//h1')->[0]->as_text};

        my $title_b = $parser->title;
        $title_b =~ s/\s+$//;

        my $author = $parser->author;

        $author =~ s/\s+$//;

        if (!defined $author){

            die "not found author!";

        }

        print "\t", $title_b || $title, "\n";
        print "\t\t[$author]\n";


        push @{$authors->{$author}}, "$root_src/artigos/$dir/$fname";

        if($title_b ne $title){
  #          use DDP; p  $title;
   #         p $title_b;
        }
        $tree->delete;


        #use DDP; p\ @fo;
#exit;
    }, $base_dir);


}

use DDP; p [keys %$authors];

my $name_to_gravatar = {
    'Marcio Vitor De Matos' => '58dbbfa6bcf55eee7b12d512adbe9a61',
    'Gabriel Andrade' => 'b54aed2483426894ec4ca220abdadc36',
    'Renato CRON' => '13b2467128dda64a63f50860e191033b',
    'Andre Garcia Carneiro' => '0650ada673b0b61a238687a3a4f935ea',
    'Giuliani D. Sanches.' => '50815d79224b6891aec3d5b442f37558',
    'Monsenhor' => 'd8e885611d1d12ec31aaaf1ac5a0765f',
    'Hernan Lopes' => 'a6a667781baf5eec0126f4c7277acd6e',
    'Nelson Ferraz' => '8f93fb445472595fa2bd8a7c3d781f93',
    'Eden Cardim' => 'c5007e8e801065d90ca9e9c206a222bc',
    'Stanislaw Pusep' => 'f93e90d4db9dc0eb3b5681c6fccfa0e2',
    'Wallace Reis' => '2547197e5ddd5ab29a569943002dd7ee',
    'Luis Motta' => '625c670068ccdf39ee487d1213c522be',
    'HAILTON DAVID LEMOS' => '30aaecfc7490cd129b193945c897ba63',
    'Thiago Rondon' => '871dcf0d5209649d772fc14377a020d3',
    'Alexei Znamensky' => '672922f05e324482fa82e4013e3a453d',
    'Otavio Fernandes' => '1365c8b3836eee4eaa57626acd1ad793',
    'Daniel Ruoso' => '923d562209b7beb2522e2208cb8e3054',
    'Ronaldo Ferreira de Lima aka jimmy' => 'eba21845a85538aa6e993d8322b7d3f1',
    'Frederico Recsky' => 'abcb478efe13707c8719c72c4500c821',
    'Marcio Ferreira' => 'ac08869c35a8c525cafb1c517c83f309',
    'Blabos de Blebe' => '06ce0be1d92c8ad880cdbb3a7cf9c89b',
    'Flávio S. Glock' => 'e54737686fab4426a0407a9620432b8c',
    'Solli M. Honório' => 'e0ec011d1cd5bc232da524ec3e353cad',
    'Daniel Vinciguerra' => '1fb6cf1869fd18b454f379814da98d90',
    'Thiago Glauco' => 'f810c78e6a9fd2685ae07870b07e2382',
    'Alceu Junior' => '79634884ebe3937fd20207f2aa6b3e67',
    'Breno G. de Oliveira' => '85d70829278770da7b5a4faa9efe4657',
    'Lindolfo Rodrigues' => 'c4eaae387543eb8602ebc9697abf65c6',
    'José Eduardo Perotta de Almeida' => '1eca55de2cbcdff5735607cebbd4b6eb',
    'Daniel de Oliveira Mantovani' => '0edd3573f84024f996e614e8445a0143',
    'Joenio Costa' => '5aff57c7238795d3b159d493ab071d6c',
    'Marco Aurelio' => '37fb4d13adf535a2f0a57e7ab7763144',
    'David Dias' => '',
};


# copiados da arvore https://github.com/sppm/SPPM-Web/tree/b02f6b098690fc2ae192e25fc936280339d1ab23



package SPPM::Web::Pod;
use base 'Pod::Xhtml';
use strict;

sub new {
    my $class = shift;
    $Pod::Xhtml::SEQ{L} = \&seqL;
    $class->SUPER::new(@_);
}

sub textblock {
    my $self = shift;
    my ($text) = @_;
    $self->{_first_paragraph} ||= $text;

    if ( $self->{_in_author_block} ) {
        $text =~ /((?:[\w.]+\s+)+)/       and $self->{_author} = $1;
        $text =~ /<([^<>@\s]+@[^<>\s]+)>/ and $self->{_email}  = $1;
        $self->{_in_author_block} = 0;    # not anymore
    }

    return $self->SUPER::textblock(@_);
}

sub command {
    my $self = shift;
    my ( $command, $paragraph, $pod_para ) = @_;

    $self->{_title} = $paragraph
        if $command eq 'head1' and not defined $self->{_title};

    $self->{_in_author_block} = 1
        if $command =~ /^head/ and $paragraph =~ /AUTHOR/;

    return $self->SUPER::command(@_);
}

sub seqL {
    my ( $self, $link ) = @_;
    $self->{LinkParser}->parse($link);
    my $page = $self->{LinkParser}->page;
    my $kind = $self->{LinkParser}->type;
    my $targ = $self->{LinkParser}->node;
    my $text = $self->{LinkParser}->text;

    if ( $kind eq 'hyperlink' ) {
        return $self->SUPER::seqL($link);
    }

    $targ ||= $text;
    $text = Pod::Xhtml::_htmlEscape($text);
    $targ = Pod::Xhtml::_htmlEscape($targ);

    return qq{<a href="http://search.cpan.org/perldoc?$targ">$text</a>};
}

sub title   { $_[0]->{_title} }
sub summary { $_[0]->{_first_paragraph} }
sub author  { $_[0]->{_author} }
sub email   { $_[0]->{_email} }


# codigo modificado para atender demandas da importacao apenas.
package SPPM::Web::Model::Artigo;

use Moose;

use POSIX qw(strftime);
use DateTime;
#use SPPM::Web::Pod;
use HTML::TreeBuilder::XPath;

has title => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

sub content {
    my $self = shift;
    my $file = shift or die "give me file name, stupid!";


    my $parser = SPPM::Web::Pod->new(
        StringMode   => 1,
        FragmentOnly => 1,
        MakeIndex    => 0,
        TopLinks     => 0,
    );


    my $fh;
    eval {
        open $fh, '<:utf8', $file
            or die "Failed to open $file: $!";

        $parser->parse_from_filehandle($fh);
    };

    if ($@ && $@ =~ /Malformed UTF-8 character/){
        close $fh;
        open $fh, '<:encoding(iso-8859-1)', $file
            or die "Failed to open $file: $!";

        $parser = SPPM::Web::Pod->new(
            StringMode   => 1,
            FragmentOnly => 1,
            MakeIndex    => 0,
            TopLinks     => 0,
        );

        $parser->parse_from_filehandle($fh);
    }

    close $fh;

    my $cached_pod = $parser->asString;


    return ($cached_pod, $parser);
}

#
# Based on CatalystAdvent::POD.pm example of Catalyst svnweb by :
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

=head1 NAME

CatalystAdvent::Pod - parse POD into XHTML + metadata

=cut