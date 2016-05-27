# vim:set ft=dockerfile:
FROM debian:jessie

ENV PG_MAJOR 9.5
ENV PG_VERSION 9.5.2-1.pgdg80+1

# explicitly set user/group IDs
#RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
  && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
  && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
  && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu \
  && gosu nobody true \
  && apt-get purge -y --auto-remove ca-certificates wget


# make the "ru_RU.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
  && localedef  -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && localedef  -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8
ENV LANG ru_RU.utf8

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
  && apt-get install -y postgresql-client

#RUN sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

#  && apt-get install -y \
#    postgresql-$PG_MAJOR=$PG_VERSION \
#    postgresql-contrib-$PG_MAJOR=$PG_VERSION \
#  && rm -rf /var/lib/apt/lists/*

# make the sample config easier to munge (and "correct by default")
#RUN mv -v /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample /usr/share/postgresql/ \
#&& ln -sv ../postgresql.conf.sample /usr/share/postgresql/$PG_MAJOR/ \
#&& sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample

#RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

RUN apt-get update && apt-get install -y cron pbzip2 python-pip vim
RUN pip install s3cmd
RUN touch /var/log/cron.log
RUN touch /var/log/backup.log

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH

ADD start.sh /start.sh
ADD create_env.sh /create_env.sh
ADD backup.sh /backup.sh

CMD ["/start.sh"]

# DEBUG
#CMD ["/bin/bash"]

