use utf8;
package SPPM::Schema::Result::ArticleCollaboration;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SPPM::Schema::Result::ArticleCollaboration

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

=head1 TABLE: C<article_collaboration>

=cut

__PACKAGE__->table("article_collaboration");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'article_collaboration_id_seq'

=head2 article_uid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 email

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "article_collaboration_id_seq",
  },
  "article_uid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "email",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<article_collaboration_article_uid_email_key>

=over 4

=item * L</article_uid>

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "article_collaboration_article_uid_email_key",
  ["article_uid", "email"],
);

=head1 RELATIONS

=head2 article_uid

Type: belongs_to

Related object: L<SPPM::Schema::Result::Article>

=cut

__PACKAGE__->belongs_to(
  "article_uid",
  "SPPM::Schema::Result::Article",
  { article_uid => "article_uid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-06-08 23:20:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v1ybtPmCKFX6/4iQ6HkCoA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;