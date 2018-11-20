FROM alpine:edge as build

RUN apk add --no-cache postgresql-dev zeromq-dev curl make g++ libc-dev

#RUN curl -sL https://github.com/pipelinedb/pipelinedb/archive/1.0.0-6.tar.gz | tar xz
COPY pipelinedb-1.0.0-6 pipelinedb-1.0.0-6

RUN cd pipelinedb-1.0.0-6/ && \
    make USE_PGXS=1 && \
    make install


##################################

FROM alpine:edge

RUN apk add --no-cache postgresql postgresql-contrib zeromq-dev

COPY --from=build /usr/lib/postgresql/* /usr/lib/postgresql/
COPY --from=build /usr/share/postgresql/extension/* /usr/share/postgresql/extension/

EXPOSE 5432

ENV PGDATA=/var/lib/data/postgres
ARG LANG=en_US.utf8

RUN mkdir -p $PGDATA /run/postgresql /etc/postgres && \
    chown postgres:postgres $PGDATA /run/postgresql /etc/postgres

USER postgres

RUN pg_ctl initdb -o "--locale=$LANG"

CMD ["postgres",  "-c", "config_file=/etc/postgres.conf"]

COPY hba.conf /etc/postgres.hba
COPY postgres.conf /etc/postgres.conf
