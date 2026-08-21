#!/bin/sh
set -eu

ARCH=$(uname -m)
if [ "${GITHUB_EVENT_NAME:-}" = "release" ]; then
  export VERSION="${GITHUB_REF_NAME#v}"
else
  export VERSION=$(head -n 1 debian/changelog | awk -F '[()]' '{print $2}')
fi
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/scalable/apps/webapp-manager.svg
export DESKTOP=/usr/share/applications/webapp-manager.desktop
export DEPLOY_PYTHON=1
export PATH_MAPPING='
	/usr/share/webapp-manager:${SHARUN_DIR}/share/webapp-manager
	/usr/share/locale:${SHARUN_DIR}/share/locale
	/usr/lib/webapp-manager:${SHARUN_DIR}/lib/webapp-manager
'
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

wget "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
# Deploy dependencies
quick-sharun \
  /usr/bin/webapp-manager \
  /usr/lib/webapp-manager \
  /usr/share/webapp-manager \
  /usr/lib/libgtk-3.so* \
  /usr/lib/libxapp.so*

# Fix the wrapper script to use dynamic AppImage paths (required for musl/Alpine compatibility where LD_PRELOAD fails)
sed -i 's|/usr/lib/webapp-manager|${SHARUN_DIR}/lib/webapp-manager|g' ./AppDir/bin/webapp-manager

if [ -f AppDir/bin/webapp-manager.py ]; then
  mv AppDir/bin/webapp-manager.py AppDir/lib/webapp-manager/webapp-manager.py
fi

echo "Bundling GSettings schemas..."
mkdir -p "$PWD/AppDir/share/glib-2.0/schemas"
cp -f /usr/share/glib-2.0/schemas/org.x.webapp-manager.gschema.xml "$PWD/AppDir/share/glib-2.0/schemas/"
glib-compile-schemas "$PWD/AppDir/share/glib-2.0/schemas/"

echo "Restoring toolkit locale files..."
restore_locale_domain() {
    domain=$1
    if [ -d "po" ]; then
        for file in po/*.po; do
            [ -e "$file" ] || continue
            lang=$(basename "$file" .po | sed 's/webapp-manager-//')
            src="/usr/share/locale/$lang/LC_MESSAGES/$domain.mo"
            dst="$PWD/AppDir/share/locale/$lang/LC_MESSAGES"
            if [ -f "$src" ]; then
                mkdir -p "$dst"
                cp "$src" "$dst/"
            fi
        done
    fi
}
for domain in gtk30 glib20 webapp-manager; do
    restore_locale_domain "$domain"
done

quick-sharun --make-appimage

quick-sharun --simple-test ./dist/*.AppImage
