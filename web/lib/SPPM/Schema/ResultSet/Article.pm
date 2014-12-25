package SPPM::Schema::ResultSet::Article;
use namespace::autoclean;

use utf8;
use Moose;
extends 'DBIx::Class::ResultSet';

# this function does NOT take care of history
sub upsert {
    my ($self, $article) = @_;


    my $author_rs = $self->result_source->schema->resultset('Author');

    my $author_name = delete $article->{_author_name};

    my $author = $author_rs->search({
        author_hash => $article->{author_hash}
    })->next;
    unless ($author){
        $author = $author_rs->create({
            author_hash => $article->{author_hash},
            name        => $author_name,
            created_at  => \'NOW()'
        });
    }

    my $row = $self->search({ uri_path => $article->{uri_path} })->next;

    if ($article->{article_type} eq 'article'){

        ($article->{published_at}) = $article->{old_uri_path} =~ /(\d{4})/;

        if (my ($d, $m, $y) = $article->{content} =~ /(\d{2})\s+([A-Za-z]{3})\s+(\d{2,4})/ ){


            my %meses = qw/
                Jan 01 Fev 02 Mar 03 Abr 04 Mai 05 Jun 06 Jul 07 Ago 08 Set 09 Out 10 Nov 11 Dez 12
                Jan 01 Feb 02 Mar 03 Apr 04 May 05 Jun 06 Jul 07 Aug 08 Sep 09 Oct 10 Nov 11 Dec 12
            /;

            $m = ucfirst lc $m;
            if (exists $meses{$m}){
                $m = $meses{$m};
                $article->{published_at} = "$y-$m-$d";
            }

        }

        $article->{published_at} .= '-01-01' if $article->{published_at} && $article->{published_at} !~ /-/;

    }

    if (!$row){
        $row = $self->create( $article );
    }else{
        $row->update( $article );
    }


}

1;