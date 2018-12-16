FROM alpine:edge as build

RUN apk add --no-cache postgresql-dev zeromq-dev curl curl-dev make g++ libc-dev

RUN curl -sL https://github.com/pipelinedb/pipelinedb/archive/1.0.0-6.tar.gz | tar xz
COPY 0001-ignore-glibc-specific-code.patch pipelinedb-1.0.0-6/
RUN cd pipelinedb-1.0.0-6/ && \
    patch -p1 < 0001-ignore-glibc-specific-code.patch && \
    make USE_PGXS=1 && \
    make install

RUN curl -sL https://github.com/pramsey/pgsql-http/archive/v1.3.0.tar.gz | tar xz
COPY 0001-add-uri-in-response.patch pgsql-http-1.3.0/
RUN cd pgsql-http-1.3.0 && \
    patch -p1 < 0001-add-uri-in-response.patch && \
    make && \
    make install


FROM alpine:edge

RUN apk add --no-cache postgresql postgresql-contrib zeromq-dev curl-dev curl hunspell-en

RUN cp /usr/share/hunspell/en_US.aff /usr/share/postgresql/tsearch_data/en_us.affix
RUN cp /usr/share/hunspell/en_US.dic /usr/share/postgresql/tsearch_data/en_us.dict

COPY --from=build /usr/lib/postgresql/* /usr/lib/postgresql/
COPY --from=build /usr/share/postgresql/extension/* /usr/share/postgresql/extension/

EXPOSE 5432

ARG PGDATA=/var/lib/data/postgres
ENV PGDATA=$PGDATA

ARG LANG=en_US.utf8

RUN mkdir -p $PGDATA /run/postgresql /etc/postgres && \
    chown postgres:postgres $PGDATA /run/postgresql /etc/postgres

USER postgres

RUN pg_ctl initdb -o "--locale=$LANG"

VOLUME $PGDATA

WORKDIR /usr/src/app

CMD ["postgres",  "-c", "config_file=/etc/postgres.conf"]

COPY hba.conf /etc/postgres.hba
COPY postgres.conf /etc/postgres.conf
