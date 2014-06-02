-- Deploy appschema

BEGIN;


create table article (
    id serial not null primary key,

    title varchar(100) not null,

    uri_path varchar(100) not null,

    old_uri_path varchar,

    author varchar,
    author_email varchar,

    sinopse varchar,

    content varchar,
    content_md5 varchar(32),

    published_at timestamp without time zone,

    article_type varchar, -- se eh artigo ou equinocio

    tags varchar[],

    published boolean not null default true,

    begin_ts timestamp without time zone not null default now(),
    end_ts timestamp without time zone not null default 'infinity'
);

create unique index ix_article_uri_path ON article ( uri_path ) where end_ts = 'infinity';


COMMIT;
