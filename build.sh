#!/usr/bin/env bash
set -e

STAMP='default'
SERVER_VERSION='1.5.2'
CTRACKS_VERSION='0.2.1'
# LIBRARY_VERSION='0.9.4' # this will be specified in the CTRACKS_LIBRARY

usage() {
  echo "USAGE: $0 -w WORKERS [-s STAMP] [-l]" >&2
  exit 1
}

while getopts 's:w:l' OPT; do
  case $OPT in
    s)
      STAMP=$OPTARG
      ;;
    w)
      WORKERS=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z $WORKERS ]; then
  usage
fi

set -o verbose # Keep this after the usage message to reduce clutter.

# When development settles down, consider going back to static Dockerfile.
perl -pne "s/<SERVER_VERSION>/$SERVER_VERSION/g; s/<CTRACKS_VERSION>/$CTRACKS_VERSION/g" \
          web-context/Dockerfile.template > web-context/Dockerfile

REPO=visdesignlab/ctracks
# docker pull $REPO # Defaults to "latest", but just speeds up the build, so precise version doesn't matter.
# docker pull $REPO # Defaults to "latest", but just speeds up the build, so precise version doesn't matter.
#--cache-from $REPO \
docker build --build-arg WORKERS=$WORKERS \
             --tag image-$STAMP \
             web-context

rm web-context/Dockerfile # Ephemeral: We want to prevent folks from editing it by mistake.

