#!/bin/bash
set -e
set +H

URL_SDK="https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip"

# Options.
if [ -z "$PLATFORM" ]; then
    PLATFORM="34"
fi
if [ -z "$BUILD_TOOLS" ]; then
    BUILD_TOOLS="34.0.0"
fi
if [ -n "$BASE_PACKAGES" ]; then
    IFS=' ' read -ra PACKAGES <<< "$BASE_PACKAGES"
else
    PACKAGES=( "platform-tools" "platforms;android-$PLATFORM" "build-tools;$BUILD_TOOLS" )
fi
if [ -n "$EXTRA_PACKAGES" ]; then
    IFS=' ' read -ra extra <<< "$EXTRA_PACKAGES"
    PACKAGES=("${PACKAGES[@]}" "${extra[@]}")
fi

DEBIAN_FRONTEND="noninteractive" sudo apt update &&
    sudo apt install --no-install-recommends -y unzip wget usbutils &&
    apt clean

# Prepare install folder.
mkdir -p "$ANDROID_HOME"
chown -R "$_REMOTE_USER:$_REMOTE_USER" "$ANDROID_HOME"

su - "$_REMOTE_USER"

cd $ANDROID_HOME

wget -q "$URL_SDK" -O sdk.zip
unzip sdk.zip
rm sdk.zip

mkdir -p $ANDROID_HOME/cmdline-tools/latest
cd $ANDROID_HOME/cmdline-tools
shopt -s extglob dotglob
mv !(latest) latest
shopt -u dotglob

cd $ANDROID_HOME

export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

# TODO: Update everything to future-proof for the link getting stale.
# yes | sdkmanager "cmdline-tools;latest"
# Download the platform tools.
yes | sdkmanager "${PACKAGES[@]}"

# Make sure the Android SDK has the correct permissions.
sudo chown -R "$_REMOTE_USER:$_REMOTE_USER" "$ANDROID_HOME"

# Exist subshell.
exit
