
drop foreign table if exists resource_stream cascade;
create foreign table resource_stream (
  url text,
  content text
) server pipelinedb;

create view resources with (action=materialize) as
    select url,
    to_tsvector('english'::regconfig, content) as indexed
    from resource_stream
;
create index tsvector_idx ON resources USING gin(indexed);
