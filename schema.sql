create extension "pipelinedb";
create extension "unaccent";

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

drop foreign table if exists resource_stream cascade;
create foreign table resource_stream (
  url text,
  content text,
  language text
) server pipelinedb;

create view resources with (action=materialize) as
    select url,
    to_tsvector(language::regconfig, content) as indexed
    from resource_stream
;
create index tsvector_idx ON resources USING gin(indexed);
