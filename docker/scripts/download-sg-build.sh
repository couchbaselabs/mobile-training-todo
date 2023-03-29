#!/bin/sh

if [ "$#" -lt 2 ]; then
    echo "Usage: download-sg-build.sh <version: 3.1.0> <build-number: 578> [arch: arm64 or x86_64, default=auto-detect]" >&2
    exit 1
fi

SCRIPT_DIR=`dirname $0`

OUT_DIR="$SCRIPT_DIR/../sg/deb"
mkdir -p "$OUT_DIR"

ARCH_ARG=$3
if [ -z "$ARCH_ARG" ]; then
    ARCH_ARG=`uname -m`
fi

ARCH=""
case $ARCH_ARG in
    arm64)  ARCH="aarch64" ;;
    x86_64) ARCH="x86_64" ;;
    *) echo "Unsupported architecture : $ARCH_ARG" && exit 1 ;;
esac

SG_DEB="couchbase-sync-gateway-enterprise_$1-$2_$ARCH.deb"
SG_URL="http://latestbuilds.service.couchbase.com/builds/latestbuilds/sync_gateway/$1/$2/$SG_DEB"

echo "" >&2
echo "Download : $SG_URL" >&2
echo "" >&2

if curl -L "$SG_URL" --fail --output "$OUT_DIR/$SG_DEB" >&2; then
    echo "" >&2
    echo "@`realpath -q $OUT_DIR/$SG_DEB`" >&2
    echo "SG_DEB=deb/$SG_DEB"
fi
