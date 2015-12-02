FROM java:8-jdk

USER root

# Extra deps
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
  build-essential \
  expect \
  lib32stdc++6 \
  maven \
  zlib1g:i386 \
  make \
  git \
  openssh-client \
  curl

# from nodejs/docker-node
RUN set -ex \
  && for key in \
    7937DFD2AB06298B2293C3187D33FF9D0246406D \
    114F43EE0176B71C7BC219DD50A3051F888C628D \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NODE_VERSION 0.10.40
ENV NPM_VERSION 2.14.1

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --verify SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
  && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
  && npm install -g npm@"$NPM_VERSION" \
  && npm cache clear

RUN curl -SLO "https://github.com/openshift/origin/releases/download/v1.0.5/openshift-origin-v1.0.5-96963b6-linux-amd64.tar.gz" \
  && mkdir -p /tmp/.jubicoy-jenkins-tmp \
  && tar -xvf "openshift-origin-v1.0.5-96963b6-linux-amd64.tar.gz" -C /tmp/.jubicoy-jenkins-tmp --strip-components=1 \
  && cp /tmp/.jubicoy-jenkins-tmp/oc /usr/local/bin/ \
  && rm "openshift-origin-v1.0.5-96963b6-linux-amd64.tar.gz" /tmp/.jubicoy-jenkins-tmp -rf

# Docker
ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.9.1
ENV DOCKER_SHA256 52286a92999f003e1129422e78be3e1049f963be1888afc3c9a99d5a9af04666

RUN curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION" -o /usr/local/bin/docker \
  && echo "${DOCKER_SHA256}  /usr/local/bin/docker" | sha256sum -c - \
  && chmod +x /usr/local/bin/docker

RUN rm -rf /var/lib/apt/lists/*

# Build
ADD build.sh /build.sh
CMD bash /build.sh
