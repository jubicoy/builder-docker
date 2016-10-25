FROM java:8-jdk

USER root

# Extra deps
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
    build-essential \
    ca-certificates \
    openssl \
    expect \
    lib32stdc++6 \
    maven \
    zlib1g:i386 \
    make \
    git \
    openssh-client \
    curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# from nodejs/docker-node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 6.9.1

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# OC etc
RUN curl -SLO "https://github.com/openshift/origin/releases/download/v1.0.5/openshift-origin-v1.0.5-96963b6-linux-amd64.tar.gz" \
  && mkdir -p /tmp/.jubicoy-jenkins-tmp \
  && tar -xvf "openshift-origin-v1.0.5-96963b6-linux-amd64.tar.gz" -C /tmp/.jubicoy-jenkins-tmp --strip-components=1 \
  && cp /tmp/.jubicoy-jenkins-tmp/oc /usr/local/bin/ \
  && rm "openshift-origin-v1.0.5-96963b6-linux-amd64.tar.gz" /tmp/.jubicoy-jenkins-tmp -rf

# Docker
ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.12.2
ENV DOCKER_SHA256 cb30ad9864f37512c50db725c14a22c3f55028949e4f1e4e585a6b3c624c4b0e

RUN set -x \
  && curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
  && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
  && tar -xzvf docker.tgz \
  && mv docker/* /usr/local/bin/ \
  && rmdir docker \
  && rm docker.tgz \
  && docker -v

# PhantomJS
RUN apt-get update && apt-get install -y \
    build-essential \
    chrpath \
    libssl-dev \
    libxft-dev \
    libfreetype6 \
    libfreetype6-dev \
    libfontconfig1 \
    libfontconfig1-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64
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
