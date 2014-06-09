-- Deploy 002-article-file-type.sql
-- requires: 001-article-table

BEGIN;

alter table article add column file_type varchar(4) not null default 'txt';

COMMIT;
