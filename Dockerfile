# vim:set ft=dockerfile:
FROM debian:jessie

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
  && localedef  -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && localedef  -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10

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

ENV PG_MAJOR 12
ENV PG_VERSION 12.1

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list \
  \
  && apt-get update && apt-get install -y postgresql-client \
  \
  && apt-get update && apt-get install -y cron pbzip2 python-pip heirloom-mailx wget \
  && pip install s3cmd \
  && touch /var/log/cron.log \
  && touch /var/log/backup.log

ENV LANG en_US.utf8
ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH

# 1) cron doesn't forward its invocation environment to cron tasks,
#    so we use create_env.sh to store it to initially empty env.sh
# 2) when we run the container with /backup.sh command as entry-point,
#    its environment is ready (so empty env.sh is ok)
COPY create_env.sh start.sh backup.sh restore.sh env.sh /

CMD ["/start.sh"]

