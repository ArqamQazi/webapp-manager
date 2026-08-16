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
export PATH_MAPPING='/usr/share/webapp-manager:${SHARUN_DIR}/share/webapp-manager'
export APPNAME="Webapp Manager"

SHARUN_URL="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
wget "$SHARUN_URL" -O ./quick-sharun
chmod +x ./quick-sharun

./quick-sharun /usr/bin/webapp-manager /usr/lib/libgtk-3.so.0 /usr/lib/librsvg-2.so.2 /usr/lib/libxapp.so.1

# Manually copy python libraries and shared assets because quick-sharun only tracks ELF binaries
mkdir -p ./AppDir/lib ./AppDir/share/webapp-manager ./AppDir/share/icons ./AppDir/share/mime
cp -r /usr/lib/webapp-manager ./AppDir/lib/
cp -r /usr/share/webapp-manager/* ./AppDir/share/webapp-manager/ || true
cp -r /usr/share/mime/* ./AppDir/share/mime/ || true
cp -r /usr/share/icons/hicolor ./AppDir/share/icons/ || true
cp -r /usr/lib/girepository-1.0 ./AppDir/lib/ || true

# allow relocating locales inside AppDir
sed -i -e 's|LOCALE_DIR =.*|LOCALE_DIR = os.environ.get("TEXTDOMAINDIR", "/usr/share/locale")|' ./AppDir/lib/webapp-manager/webapp-manager.py

# fix hardcoded absolute path in the wrapper script
sed -i 's|/usr/lib/webapp-manager|${SHARUN_DIR}/lib/webapp-manager|g' ./AppDir/bin/webapp-manager
sed -i 's| &||g' ./AppDir/bin/webapp-manager

# Create symlink for /usr/share so hardcoded paths work natively
mkdir -p ./AppDir/usr
ln -s ../share ./AppDir/usr/share
ln -s ../lib ./AppDir/usr/lib
ln -s ../bin ./AppDir/usr/bin

./quick-sharun --make-appimage
