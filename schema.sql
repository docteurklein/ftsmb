create extension if not exists "pipelinedb";
create extension if not exists "unaccent";
create extension if not exists "http";
create extension if not exists "pg_trgm";

create schema if not exists api;

create text search configuration api.fr ( copy = french );
alter text search configuration api.fr alter mapping
for hword, hword_part, word with unaccent, french_stem;

create text search configuration api.en ( copy = english );
alter text search configuration api.en alter mapping
for hword, hword_part, word with unaccent, english_stem;

create text search configuration api.de ( copy = german );
alter text search configuration api.de alter mapping
for hword, hword_part, word with unaccent, german_stem;

create text search configuration api.usimple ( copy = simple );
alter text search configuration api.usimple alter mapping
for hword, hword_part, word with unaccent, simple;

drop foreign table if exists api.input_stream cascade;
create foreign table api.input_stream (
    uri text,
    language text,
    content text,
    content_type text
) server pipelinedb;

select http_set_curlopt('CURLOPT_TIMEOUT', '2');

-- drop function if exists try_get;
-- create function try_get(uri text) returns http_response as $$
--     begin
--         raise info 'fetching uri: %', uri;
--         return http_get(uri);
--     exception
--         when others then
--             raise info 'uri failed: %', uri;
--         return null;
--     end
-- $$ language plpgsql parallel unsafe;

create view api.resources with (action=materialize) as
    select uri,
    to_tsvector(coalesce(language, 'api.en')::regconfig, response.content) as indexed
    from api.input_stream input
    join coalesce(
        case when input.content is not null then
            (uri, 200, coalesce(input.content_type, 'text/html'), null, input.content)::http_response
        end,
        http_get(uri)
    ) response using (uri)
    where status = 200
    and response.content_type like 'text/%'
;
create index concurrently tsvector_idx ON api.resources USING gin(indexed);

