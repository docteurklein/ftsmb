
create extension if not exists "pipelinedb";
create extension if not exists "unaccent";
create extension if not exists "http";
create extension if not exists "pg_trgm";

drop text search dictionary if exists english_hunspell cascade;
create text search dictionary english_hunspell (
    template = ispell,
    DictFile = en_us,
    AffFile = en_us,
    Stopwords = english
);
drop text search dictionary if exists english_snowball cascade;
create text search dictionary english_snowball (
    template = snowball,
    language = english
);
drop text search configuration if exists en cascade;
create text search configuration en ( copy = english );
alter text search configuration en alter mapping
for hword, hword_part, word with unaccent, english_hunspell;

drop foreign table if exists input_stream cascade;
create foreign table input_stream (
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
-- $$ language plpgsql parallel safe;

drop view if exists resources;
create view resources with (action=materialize) as
    select uri,
    response.content,
    to_tsvector(coalesce(language, 'en')::regconfig, uri || ' ' || response.content) as indexed,
    coalesce(language, 'en') as language
    from input_stream input
    join coalesce(
        case when input.content is not null then
            (uri, 200, coalesce(input.content_type, 'text/html'), null, input.content)::http_response
        end,
        http_get(uri)
    ) response using (uri)
    where status = 200
    and response.content_type like 'text/%'
;
create index concurrently tsvector_idx ON resources USING gin(indexed);

\set password `cat /run/secrets/postgres_password`
alter user postgres with encrypted password :'password';

drop function if exists search;
create function search(query text, out uri text, out language text, out headline text) returns setof record as $$
    select uri, language, regexp_replace(ts_headline(language::regconfig, content, websearch_to_tsquery(language::regconfig, query),
        'StartSel="\033[1;4m", StopSel="\033[0m",
        MaxWords=35, MinWords=15, ShortWord=3, HighlightAll=false,
        MaxFragments=2, FragmentDelimiter=" ... "'), '\s+', ' ', 'g')
    from resources
    where indexed @@ websearch_to_tsquery(query)
$$ language sql;
