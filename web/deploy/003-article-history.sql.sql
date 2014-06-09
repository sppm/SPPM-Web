-- Deploy 003-article-history.sql
-- requires: 001-article-table

-- ao inserir, basta usar $row->copy({ end_ts => \"now()" });
BEGIN;

alter table article_collaboration drop column article_uid;
alter table article_tag drop column article_uid;

alter table article drop column article_uid;

alter table article_collaboration add column article_id int not null references article(id);
alter table article_tag add column article_id int not null references article(id);

alter table article_collaboration add unique (article_id, email);
alter table article_tag add unique (article_id, tag_name);

COMMIT;
