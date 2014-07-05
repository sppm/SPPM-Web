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

        if ($_ !~ /.pod$/){
            # print "$_ is not a .POD\n";
            next;
        }

        print "root/artigos$dir/$_\n";

        my ($artigo, $parser) = SPPM::Web::Model::Artigo->new->content( "$root_src/artigos/$dir/$_" );

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


        push @{$authors->{$author}}, $_;

        if($title_b ne $title){
  #          use DDP; p  $title;
   #         p $title_b;
        }
        $tree->delete;


        #use DDP; p\ @fo;
#exit;
    }, $base_dir);


}

use DDP; p $authors;

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