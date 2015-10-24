#!/bin/bash
set -o pipefail
IFS=$'\n\t'

# DOCKER_SOCKET = Openshift's exposed socket
# TAG = Docker tag suffix. Consumed in Makefile
# SOURCE_REPOSITORY = URL of the source code repo
# SOURCE_REF = Commit/tag ref to build
# BUILD_ROOT = Folder to build in
# HTTP_REPO_BASIC = username:password for git user

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [[ "${SOURCE_REPOSITORY}" != "git://"* ]] && [[ "${SOURCE_REPOSITORY}" != "git@"* ]]; then
  URL="${SOURCE_REPOSITORY}"
  if [[ "${URL}" != "http://"* ]] && [[ "${URL}" != "https://"* ]]; then
    URL="https://${URL}"
  fi
  if [ -e "${HTTP_REPO_BASIC}" ]; then
    BASIC_CREDS="-u ${HTTP_REPO_BASIC}"
  fi
  curl ${BASIC_CREDS} --head --silent --fail --location --max-time 16 $URL > /dev/null
  if [ $? != 0 ]; then
    echo "Could not access source url: ${SOURCE_REPOSITORY}"
    exit 1
  fi
fi

if [ -n "${SOURCE_REF}" ]; then
  BUILD_DIR=$(mktemp --directory --suffix=docker-build)
  git clone --recursive "${SOURCE_REPOSITORY}" "${BUILD_DIR}"
  if [ $? != 0 ]; then
    echo "Error trying to fetch git source: ${SOURCE_REPOSITORY}"
    exit 1
  fi
  pushd "${BUILD_DIR}"
  git checkout "${SOURCE_REF}"
  if [ $? != 0 ]; then
    echo "Error trying to checkout branch: ${SOURCE_REF}"
    exit 1
  fi
  popd
else
  echo "No branch specified for ${SOURCE_REPOSITORY}"
  exit 1
fi

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

if true || [ -s "/root/.dockercfg" ]; then
  pushd "${BUILD_DIR}/${BUILD_ROOT}"
  make container push
  popd
fi
