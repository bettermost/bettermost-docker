FROM debian:buster-slim

# Some ENV variables
ENV PATH="/mattermost/bin:${PATH}"
ARG PUID=2000
ARG PGID=2000
ARG MM_PACKAGE="https://github.com/bettermost/mattermost-server/releases/download/v5.23.1-rc16/bettermost-oss-linux-amd64.tar.gz"

COPY entrypoint.sh /home/mattermost/
RUN chmod +x /home/mattermost/entrypoint.sh
# Install some needed packages
RUN apt-get update && apt-get install -y \
  ca-certificates \
  curl \
  mime-support \
  tzdata \
  && rm -rf /tmp/*

RUN apt-get clean autoclean
RUN apt-get autoremove --yes
RUN rm -rf /var/lib/{apt,dpkg,cache,log}
# Get Mattermost
RUN mkdir -p /mattermost/data /mattermost/plugins /mattermost/client/plugins \
  && if [ ! -z "$MM_PACKAGE" ]; then curl -L $MM_PACKAGE | tar -xvz ; \
  else echo "please set the MM_PACKAGE" ; fi \
  && addgroup --gid ${PGID} mattermost \
  && adduser --uid ${PUID} --gid ${PGID} --home /mattermost mattermost \
  && chown -R mattermost:mattermost /mattermost /mattermost/plugins /mattermost/client/plugins

RUN rm -rf /var/lib/apt/lists/*
USER mattermost

#Healthcheck to make sure container is ready
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:8065/api/v4/system/ping || exit 1


#Remov

# Configure entrypoint and command
ENTRYPOINT ["/home/mattermost/entrypoint.sh"]
WORKDIR /mattermost
CMD ["mattermost"]

EXPOSE 8065 8067 8074 8075

# Declare volumes for mount point directories
VOLUME ["/mattermost/data", "/mattermost/logs", "/mattermost/config", "/mattermost/plugins", "/mattermost/client/plugins"]

