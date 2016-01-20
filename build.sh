#!/bin/bash
set -o pipefail
IFS=$'\n\t'

# DOCKER_SOCKET = Openshift's exposed socket
# TAG = Docker tag suffix. Consumed in Makefile
# SOURCE_REPOSITORY = URL of the source code repo
# SOURCE_REF = Commit/tag ref to build
# BUILD_ROOT = Folder to build in

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
	DOCKER_URI="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
else
  echo "No output image specified"
  exit 1
fi
export DOCKER_URI="${DOCKER_URI}"

cat <<EOSTATUS
#
# Building Docker image
# *******************************************************************
System:
  docker -> $(docker -v)
  java   -> $(java -version 2>&1|head -1)
  javac  -> $(javac -version 2>&1|head -1)
  maven  -> $(mvn -v|head -1)
  node   -> $(node -v)
  npm    -> $(npm -v)
EOSTATUS

if [[ "${SOURCE_REPOSITORY}" != "git://"* ]] && [[ "${SOURCE_REPOSITORY}" != "git@"* ]]; then
  URL="${SOURCE_REPOSITORY}"
  if [[ "${URL}" != "http://"* ]] && [[ "${URL}" != "https://"* ]]; then
    URL="https://${URL}"
  fi
  if [ -f "${SOURCE_SECRET_PATH}/username" ] \
        && [ -f "${SOURCE_SECRET_PATH}/password" ] \
        && [[ "${URL}" == "https://"* ]]; then
    USERNAME=$(cat "${SOURCE_SECRET_PATH}/username")
    PASSWORD=$(cat "${SOURCE_SECRET_PATH}/password")
    ENCODED_BASIC=$(echo "${USERNAME}:${PASSWORD}" | sed 's/@/%40/g')
    URL="https://${ENCODED_BASIC}@${URL:8}"
  fi
  git ls-remote $URL &> /dev/null
  if [ $? != 0 ]; then
    echo "Could not access source url: ${SOURCE_REPOSITORY}"
    exit 1
  fi
  SRC_REPO="${URL}"
else
  SRC_REPO="${SOURCE_REPOSITORY}"
fi

if [ -n "${SOURCE_REF}" ]; then
  BUILD_DIR=$(mktemp --directory --suffix=docker-build)
  git clone --recursive "${SRC_REPO}" "${BUILD_DIR}"
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
  GIT_COMMIT=$(git rev-parse HEAD)
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
  echo "${DOCKER_URI} \(${TAG}\)"
  DOCKER_REPO="${DOCKER_URI%:*}"
  if [ -z ${APPEND_SHA+x} ]; then
    DOCKER_TAG="${DOCKER_URI##*:}"
  else
    DOCKER_TAG="${DOCKER_URI##*:}-${GIT_COMMIT:0:8}"
  fi
  DOCKER_REPO="${DOCKER_REPO}" DOCKER_TAG="${DOCKER_TAG}" make container push
  popd
fi
