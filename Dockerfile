FROM cikl/base:0.0.2
MAINTAINER Mike Ryan <falter@gmail.com>

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y rabbitmq-server=3.2.4-1 && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

RUN gpg --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN	wget --quiet -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
	&& wget --quiet -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

# Define mount points.
VOLUME [ "/data" ]

# Define working directory.
WORKDIR /data

# Define environment variables.
ENV HOME /data
ENV RABBITMQ_LOG_BASE /data/log
ENV RABBITMQ_MNESIA_BASE /data/mnesia
ENV RABBITMQ_SERVER_START_ARGS -rabbit sasl_error_logger false -rabbit error_logger false

# rabbitmq takes care of dropping to the rabbitmq user, itself.
ENV ENTRYPOINT_DROP_PRIVS 0

# Expose ports.
EXPOSE 5672
EXPOSE 15672

ADD rabbitmq.config /etc/rabbitmq/rabbitmq.config
RUN rabbitmq-plugins enable rabbitmq_management
RUN usermod -d /data rabbitmq

ADD rabbitmq-command.sh /etc/docker-entrypoint/commands.d/rabbitmq
RUN chmod a+x /etc/docker-entrypoint/commands.d/rabbitmq

# Define default command.
CMD [ "rabbitmq" ]
