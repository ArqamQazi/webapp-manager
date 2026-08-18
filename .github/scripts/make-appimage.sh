#!/bin/sh
set -eu

ARCH=$(uname -m)
if [ "${GITHUB_EVENT_NAME:-}" = "release" ]; then
  export VERSION="${GITHUB_REF_NAME#v}"
else
  export VERSION=$(head -n 1 debian/changelog | awk -F '[()]' '{print $2}')
fi

# Clean previous build artifacts
rm -rf ./AppDir ./dist

export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export ICON=/usr/share/icons/hicolor/scalable/apps/webapp-manager.svg
export DESKTOP=/usr/share/applications/webapp-manager.desktop
export DEPLOY_PYTHON=1
export ALWAYS_SOFTWARE=1
export APPNAME="Webapp Manager"

SHARUN_URL="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
wget "$SHARUN_URL" -O ./quick-sharun
chmod +x ./quick-sharun

./quick-sharun /usr/bin/webapp-manager /usr/lib/webapp-manager /usr/share/webapp-manager/ /usr/lib/libgtk-3.so.0

# Fix the wrapper script to use relative paths and remove background execution
sed -i 's|/usr/lib/webapp-manager|${SHARUN_DIR}/lib/webapp-manager|g' ./AppDir/bin/webapp-manager
sed -i 's| &||g' ./AppDir/bin/webapp-manager

# Create usr symlinks so anylinux.so and unshare path interception works flawlessly
# (Removed as per anylinux philosophy: we patch the app instead)
sed -i 's|os.environ.get("APPDIR", "") + sys.prefix|os.environ.get("APPDIR", "")|g' ./AppDir/lib/webapp-manager/webapp-manager.py

./quick-sharun --make-appimage
