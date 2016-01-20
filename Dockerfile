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
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NODE_VERSION 0.10.41
ENV NPM_VERSION 2.14.15

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

# PhantomJS
RUN apt-get update && apt-get install -y \
  build-essential \
  chrpath \
  libssl-dev \
  libxft-dev \
  libfreetype6 \
  libfreetype6-dev \
  libfontconfig1 \
  libfontconfig1-dev

ENV PHANTOMJS phantomjs-1.9.8-linux-x86_64
RUN curl -SLO "https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOMJS.tar.bz2" \
  && mkdir -p /tmp/.jubicoy-phantomjs-tmp \
  && tar -xjf "$PHANTOMJS.tar.bz2" -C /tmp/.jubicoy-phantomjs-tmp \
  && mv "/tmp/.jubicoy-phantomjs-tmp/$PHANTOMJS" /usr/local/share/ \
  && ln -s "/usr/local/share/$PHANTOMJS/bin/phantomjs" /usr/local/bin/phantomjs \
  && rm "$PHANTOMJS.tar.bz2" -f

RUN rm -rf /var/lib/apt/lists/*

# Build
ADD build.sh /build.sh
CMD bash /build.sh
