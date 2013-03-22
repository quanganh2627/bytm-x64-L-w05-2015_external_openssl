#!/bin/bash

SUPPORTED_ARCH="x86_64"

MANUAL_RECOVER="You need to recover the source directory by hand and build again."

if [ ! -d "$ANDROID_BUILD_TOP" ] ; then
    echo "Android top dir is invalid. Did you forget to run these commands first?"
    echo " . ./build/envsetup.sh"
    echo " lunch "
    exit 1
fi

for arch in $SUPPORTED_ARCH ; do
    if [ $arch == "ia32" ] ; then
        ARCH_SUFFIX=x86
    else
        ARCH_SUFFIX=$arch
    fi

    PREBUILTS_PATH=$ANDROID_BUILD_TOP/prebuilts/tools/linux-$ARCH_SUFFIX/openssl

    MAKE_ANDROID_CMD="make ARCH=$arch -f Prebuilts.mk"

# Prepare config head files
    for h in $(find . -name  opensslconf.h) ; do
        if ! cp -v $h $h.bak || ! cp -v $h.$arch $h ; then
            echo "Failed to prepare $h"
            exit 1
        fi
    done
# Start prebuild procedure...

    if ! $MAKE_ANDROID_CMD clean ; then
        echo "make clean failed. $MANUAL_RECOVER"
        exit 1
    fi

    if ! $MAKE_ANDROID_CMD ; then
        echo "make failed. $MANUAL_RECOVER"
        exit 1
    fi

    if ! mkdir -p $PREBUILTS_PATH ; then
        echo "Could not create prebuilt path: $PREBUILTS_PATH"
        exit 1
    fi

    if ! cp $PWD/*.a $PREBUILTS_PATH/ ; then
        echo "Failed to copy the built to $PREBUILTS_PATH"
        exit 1
    fi

    if ! $MAKE_ANDROID_CMD clean; then
        echo "Post build clean failed. $MANUAL_RECOVER"
        exit 1
    fi

# Restore config head files
    for h in $(find . -name  opensslconf.h) ; do
        if ! mv $h.bak $h ; then
            echo "Failed to restore $h. $MANUAL_RECOVER"
            exit 1
        fi
    done
    echo "Installed Prebuild in $PREBUILTS_PATH"
done

echo "Installed openssl libaries in all supported architectures."
