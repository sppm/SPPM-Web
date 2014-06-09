use utf8;
package SPPM::Schema::Result::Article;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SPPM::Schema::Result::Article

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

=head1 TABLE: C<article>

=cut

__PACKAGE__->table("article");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'article_id_seq'

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 72

=head2 article_uid

  data_type: 'integer'
  is_nullable: 0

=head2 uri_path

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 old_uri_path

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 author

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 author_email

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

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

=head2 content_as_html

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

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

=head2 begin_ts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 end_ts

  data_type: 'timestamp'
  default_value: infinity
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "article_id_seq",
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 72 },
  "article_uid",
  { data_type => "integer", is_nullable => 0 },
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
  "author",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "author_email",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
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
  "content_as_html",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
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
  "begin_ts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "end_ts",
  { data_type => "timestamp", default_value => "infinity", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<article_article_uid_key>

=over 4

=item * L</article_uid>

=back

=cut

__PACKAGE__->add_unique_constraint("article_article_uid_key", ["article_uid"]);

=head1 RELATIONS

=head2 article_collaborations

Type: has_many

Related object: L<SPPM::Schema::Result::ArticleCollaboration>

=cut

__PACKAGE__->has_many(
  "article_collaborations",
  "SPPM::Schema::Result::ArticleCollaboration",
  { "foreign.article_uid" => "self.article_uid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 article_tags

Type: has_many

Related object: L<SPPM::Schema::Result::ArticleTag>

=cut

__PACKAGE__->has_many(
  "article_tags",
  "SPPM::Schema::Result::ArticleTag",
  { "foreign.article_uid" => "self.article_uid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-06-08 23:20:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:baXxnXgnsmb02jK4PHDRcQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
