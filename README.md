# full text search for your browsing history

## run pipelinedb

    docker run --rm -p 5432:5432 pipelinedb/pipelinedb-postgresql-11
    psql 'host=0 user=postgres' < schema.sql

## import your content

> This uses chromium's sqlite history. sqlite will fail to open this file if chromium is open.


    sqlite3 ~/.config/chromium/Default/History \
        "select url from urls where url like '%twitter.com/%status/%'" \
        | xargs -n1 ./urltocsv \
        | psql 'host=0 user=postgres' -c '\copy resource_stream(url,content) from stdin with (format csv)'


## ???

## profit

    psql 'host=0 user=postgres' -c \
        "select url from resources where indexed @@ websearch_to_tsquery('english', 'some words')"
