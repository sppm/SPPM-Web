-- Deploy 004-remodel.sql
-- requires: 003-article-history.sql

BEGIN;


drop table article cascade;
drop table article_collaboration cascade ;
drop table article_tag cascade;


CREATE TABLE article
(
    id serial NOT NULL,
    title character varying(72) NOT NULL,
    uri_path character varying NOT NULL,
    old_uri_path character varying,
    author_hash character varying(32),
    collaborators character varying(32)[],
    sinopse character varying,
    content character varying,
    content_md5 character varying(32),
    html_content character varying,
    article_type character varying,
    published boolean NOT NULL DEFAULT true,
    published_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    content_ext character varying(4) NOT NULL DEFAULT 'txt'::character varying,
    CONSTRAINT article_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);


CREATE UNIQUE INDEX ix_article_uri_path
  ON article
  USING btree
  (uri_path COLLATE pg_catalog."default");


CREATE TABLE article_history
(
    id serial NOT NULL primary key,
    article_id int NOT NULL,
    title character varying NOT NULL,
    uri_path character varying NOT NULL,
    old_uri_path character varying,
    author_hash character varying(32),
    sinopse character varying,
    content character varying,
    content_md5 character varying(32),
    html_content character varying,
    article_type character varying,
    published boolean NOT NULL DEFAULT true,
    published_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    content_ext character varying(4) NOT NULL,
    removed_at timestamp without time zone NOT NULL default now(),
    removed_by_hash character varying(32) not null
);


CREATE TABLE author
(
    author_hash character varying(32) NOT null primary key,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);

ALTER TABLE article
   ALTER COLUMN title TYPE character varying(93);

COMMIT;
