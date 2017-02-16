#!/usr/bin/env bash
set -e
set -v

# Docker image is pinned here, so that you can checkout older
# versions of this script, and get reproducible deployments.
# Other scripts may grep this script to get the version.
#
# version bump? ==> Remember to update README.md as well!
DOCKER_VERSION=v0.0.8
IMAGE=gehlenborglab/higlass:$DOCKER_VERSION
STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
PORT=0

# NOTE: No parameters should change the behavior in a deep way:
# We want the tests to cover the same setup as in production.

usage() {
  echo "USAGE: $0 [-i IMAGE] [-s STAMP] [-p PORT] [-v VOLUME]" >&2
  exit 1
}

while getopts 'i:s:p:v:' OPT; do
  case $OPT in
    i)
      IMAGE=$OPTARG
      ;;
    s)
      STAMP=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    v)
      VOLUME=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$VOLUME" ]; then
    VOLUME=/tmp/higlass-docker/volume-$STAMP-with-redis
fi

docker network create --driver bridge network-$STAMP

for DIR in redis-data hg-data/log hg-tmp; do
  mkdir -p $VOLUME/$DIR || echo "$VOLUME/$DIR already exists"
done
mkdir -p /tmp/hg-share-$STAMP

REDIS_HOST=container-redis-$STAMP

docker run --name $REDIS_HOST \
           --network network-$STAMP \
           --volume $VOLUME/redis-data:/data \
           --detach redis:3.2.7-alpine \
           redis-server

docker run --name container-$STAMP-with-redis \
           --network network-$STAMP \
           --publish $PORT:80 \
           --volume /tmp/hg-share-$STAMP:/share \
           --volume $VOLUME/hg-data:/data \
           --volume $VOLUME/hg-tmp:/tmp \
           --env REDIS_HOST=$REDIS_HOST \
           --env REDIS_PORT=6379 \
           --detach \
           --publish-all \
           $IMAGE