create extension "pipelinedb";
create extension "unaccent";
create extension "http";

create text search configuration fr ( copy = french );
alter text search configuration fr alter mapping
for hword, hword_part, word with unaccent, french_stem;

create text search configuration en ( copy = english );
alter text search configuration en alter mapping
for hword, hword_part, word with unaccent, english_stem;

create text search configuration de ( copy = german );
alter text search configuration de alter mapping
for hword, hword_part, word with unaccent, german_stem;

create text search configuration usimple ( copy = simple );
alter text search configuration usimple alter mapping
for hword, hword_part, word with unaccent, simple;

drop foreign table if exists url_stream cascade;
create foreign table url_stream (
  url text,
  language text
) server pipelinedb;

select http_set_curlopt('CURLOPT_TIEMOUT', '2');

create view resources with (action=materialize) as
    select url,
    to_tsvector(coalesce(language, 'en')::regconfig, (select content from http_get(url))) as indexed
    from url_stream
;
create index tsvector_idx ON resources USING gin(indexed);
