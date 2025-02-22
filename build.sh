#!/bin/bash

set -e

absolutize ()
{
  if [ ! -d "$1" ]; then
    echo
    echo "ERROR: '$1' doesn't exist or not a directory!"
    kill -INT $$
  fi

  pushd "$1" >/dev/null
  echo `pwd`
  popd >/dev/null
}

TARGET_ARCHITECTURE=$1
TARGET_VARIANT=$2
TARGET_DEVICE=$3

BUILD=`dirname "$0"`"/build/"
BUILD=`absolutize $BUILD`

###
### chose a release
###
#RELEASE="15.05.1"
RELEASE="17.01.1"

IMGBUILDER_NAME="lede-imagebuilder-ramips-rt3883.Linux-x86_64"
IMGBUILDER_DIR="${BUILD}/${IMGBUILDER_NAME}"
IMGBUILDER_ARCHIVE="${IMGBUILDER_NAME}.tar.xz"

IMGTEMPDIR="${BUILD}/openwrt-build-image-extras"
#https://downloads.lede-project.org/snapshots/targets/ar71xx/generic/lede-imagebuilder-ar71xx-generic.Linux-x86_64.tar.xz
#https://downloads.lede-project.org/snapshots/targets/ar71xx/generic/lede-imagebuilder-ar71xx-generic.Linux-x86_64.tar.xz
IMGBUILDERURL="http://downloads.lede-project.org/snapshots/targets/ramips/rt3883/lede-imagebuilder-ramips-rt3883.Linux-x86_64.tar.xz"

if [ -z ${TARGET_DEVICE} ]; then
    echo "Usage: $0 architecture variant device-profile"
    echo " e.g.: $0 ar71xx generic tl-wr1043nd-v2"
    echo "       $0 ramips mt7621 zbt-wg3526"
    echo " to get a list of supported devices issue a 'make info' in the OpenWRT image builder directory:"
    echo "   '${IMGBUILDER_DIR}'"
    kill -INT $$
fi

# the absolute minimum for extroot to work at all (i.e. when the disk is already set up, for example by hand).
# this list may be smaller and/or different for your router, but it works with my ar71xx.
PREINSTALLED_PACKAGES="block-mount kmod-usb2 kmod-usb-storage kmod-fs-ext4"

# some kernel modules may also be needed for your hardware
PREINSTALLED_PACKAGES+=" kmod-usb-uhci kmod-usb-ohci"

# these are needed for the proper functioning of the auto extroot scripts
PREINSTALLED_PACKAGES+=" blkid mount-utils swap-utils e2fsprogs fdisk"

# the following packages are optional, feel free to (un)comment them
PREINSTALLED_PACKAGES+=" wireless-tools firewall iptables"
PREINSTALLED_PACKAGES+=" kmod-usb-storage-extras kmod-mmc"
PREINSTALLED_PACKAGES+=" ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe"
PREINSTALLED_PACKAGES+=" luci"

mkdir -pv ${BUILD}

rm -rf $IMGTEMPDIR
cp -r image-extras/common/ $IMGTEMPDIR
PER_PLATFORM_IMAGE_EXTRAS=image-extras/${TARGET_DEVICE}/
if [ -e $PER_PLATFORM_IMAGE_EXTRAS ]; then
    rsync -pr $PER_PLATFORM_IMAGE_EXTRAS $IMGTEMPDIR/
fi

if [ ! -e ${IMGBUILDER_DIR} ]; then
    pushd ${BUILD}
    # --no-check-certificate if needed
    wget  --continue ${IMGBUILDERURL}
    xz -d <${IMGBUILDER_ARCHIVE} | tar vx
    popd
fi

pushd ${IMGBUILDER_DIR}

make image PROFILE=${TARGET_DEVICE} PACKAGES="${PREINSTALLED_PACKAGES}" FILES=${IMGTEMPDIR}

pushd bin/${TARGET_ARCHITECTURE}/
ln -s ../../packages .
popd

popd