create extension "pipelinedb";
create extension "unaccent";
create extension "http";
create extension "pg_trgm";

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

drop foreign table if exists input_stream cascade;
create foreign table input_stream (
    uri text,
    language text,
    content text,
    type text
) server pipelinedb;

select http_set_curlopt('CURLOPT_TIMEOUT', '2');

-- drop function if exists get;
-- create function get(uri text) returns http_response as $$
--     begin
--         raise info 'fetching uri: %', uri;
--         return http_get(uri);
--     exception
--         when others then
--             raise info 'uri failed: %', uri;
--         return null;
--     end
-- $$ language plpgsql parallel unsafe;

create view resources with (action=materialize) as
    select uri,
    to_tsvector(coalesce(language, 'en')::regconfig, response.content) as indexed
    from input_stream input
    left join coalesce(
        (case when input.content is not null then (uri, 200, coalesce(input.type, 'text/html'), null, input.content)::http_response else null end),
        http_get(uri)
    ) response using (uri)
    where status = 200
    and content_type like 'text/%'
;
create index concurrently tsvector_idx ON resources USING gin(indexed);
