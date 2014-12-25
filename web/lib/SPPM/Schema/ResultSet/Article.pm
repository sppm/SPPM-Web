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

    if (!$row){
        $row = $self->create( $article );
    }else{
        $row->update( $article );
    }


}

1;