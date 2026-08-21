#!/bin/sh
set -eu

ARCH=$(uname -m)
DEBLOATED_URL="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
sudo pacman -Syu --noconfirm base-devel wget gettext python python-gobject python-configobj python-pillow python-setproctitle python-tldextract python-cairo gtk3 xapp xorg-server-xvfb

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
if command -v get-debloated-pkgs >/dev/null 2>&1; then
  get-debloated-pkgs --add-common --prefer-nano
else
  wget --retry-connrefused --tries=30 "$DEBLOATED_URL" -O /tmp/get-debloated-pkgs.sh
  chmod +x /tmp/get-debloated-pkgs.sh
  /tmp/get-debloated-pkgs.sh --add-common --prefer-nano
fi

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

# If the application needs to be manually built that has to be done down here
make buildmo
# Remove the pre-compiled schema if it exists so we don't overwrite the system's registry
rm -f usr/share/glib-2.0/schemas/gschemas.compiled

sudo cp -a usr/* /usr/
if [ -d "etc" ]; then
  sudo cp -a etc/* /etc/
fi

# Compile schemas on the system so quick-sharun can pick them up properly
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

# if you also have to make nightly releases check for DEVEL_RELEASE = 1
#
# if [ "${DEVEL_RELEASE-}" = 1 ]; then
# 	nightly build steps
# else
# 	regular build steps
# fi
