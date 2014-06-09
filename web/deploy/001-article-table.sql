-- Deploy 001-article-table
-- requires: appschema

BEGIN;

-- sorry guys!
drop table article;

-- re-doing!
create table article (
    id serial not null primary key,

    title varchar(72) not null,
    -- http://blog.powermapper.com/blog/post/Page-Title-Length-for-Search-Engines.aspx

    article_uid int not null unique,
    uri_path varchar not null,

    old_uri_path varchar,

    author varchar,
    author_email varchar,

    sinopse varchar,

    content varchar,
    content_md5 varchar(32),

    content_as_html varchar,

    created_at timestamp without time zone,

    article_type varchar, -- se eh artigo ou equinocio

    published boolean not null default true,

    published_at timestamp without time zone,

    begin_ts timestamp without time zone not null default now(),
    end_ts timestamp without time zone not null default 'infinity'
);

create unique index ix_article_uri_path ON article ( uri_path ) where end_ts = 'infinity';


create table article_tag (
    id serial not null primary key,
    article_uid int not null REFERENCES article (article_uid),
    tag_name varchar(20) not null,
    unique(article_uid, tag_name)
);

create table article_collaboration (
    id serial not null primary key,
    article_uid int not null REFERENCES article (article_uid),
    email varchar,
    name varchar not null,
    unique(article_uid, email)
);


COMMIT;
