FROM jenkins:latest

USER jenkins

RUN mkdir -p /var/jenkins_home/restore_db
COPY databases /var/jenkins_home/restore_db/
COPY backups.sh /var/jenkins_home/restore_db/

#################
#     DOCKER    #
#################
USER root

# Install Docker (to be used as a client only)
#RUN wget -qO- https://get.docker.com/ | sh
#RUN usermod -aG docker jenkins

#################
#     MONGO    #
#################
ENV GPG_KEYS \
# gpg: key 7F0CEB10: public key "Richard Kreuter <richard@10gen.com>" imported
	492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10

RUN set -ex; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done; \
	gpg --export $GPG_KEYS > /etc/apt/trusted.gpg.d/mongodb.gpg; \
	rm -r "$GNUPGHOME"; \
	apt-key list

ENV MONGO_MAJOR 3.0
ENV MONGO_VERSION 3.0.14
ENV MONGO_PACKAGE mongodb-org

RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		${MONGO_PACKAGE}-tools=$MONGO_VERSION

#################
#   POSTGRESQL  #
#################
# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN set -ex; \
# pub   4096R/ACCC4CF8 2011-10-13 [expires: 2019-07-02]
#       Key fingerprint = B97B 0AFC AA1A 47F0 44F2  44A0 7FCC 7D46 ACCC 4CF8
# uid                  PostgreSQL Debian Repository
	key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	gpg --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; \
	rm -r "$GNUPGHOME"; \
  apt-key list

ENV PG_MAJOR 9.6
ENV PG_VERSION 9.6.2-1.pgdg80+1

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
  && apt-get install -y postgresql-common \
  && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
  && apt-get install -y \
  	postgresql-$PG_MAJOR=$PG_VERSION \
  	postgresql-contrib-$PG_MAJOR=$PG_VERSION \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/dumps
RUN chmod -R 777 /opt/dumps
