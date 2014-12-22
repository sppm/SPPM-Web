use utf8;
package SPPM::Schema::Result::ArticleHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SPPM::Schema::Result::ArticleHistory

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<article_history>

=cut

__PACKAGE__->table("article_history");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'article_history_id_seq'

=head2 article_id

  data_type: 'integer'
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 uri_path

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 old_uri_path

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 author_hash

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 sinopse

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 content

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 content_md5

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 html_content

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 article_type

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 published

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 published_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 content_ext

  data_type: 'varchar'
  is_nullable: 0
  size: 4

=head2 removed_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 removed_by_hash

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "article_history_id_seq",
  },
  "article_id",
  { data_type => "integer", is_nullable => 0 },
  "title",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "uri_path",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "old_uri_path",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "author_hash",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "sinopse",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "content",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "content_md5",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "html_content",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "article_type",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "published",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "published_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "content_ext",
  { data_type => "varchar", is_nullable => 0, size => 4 },
  "removed_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "removed_by_hash",
  { data_type => "varchar", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-12-22 04:36:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2XFhupJSVsNaG9/4TOcDWw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
