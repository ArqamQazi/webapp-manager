#!/bin/sh
set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
sudo pacman -Syu --noconfirm base-devel wget gettext python python-gobject python-configobj python-pillow python-setproctitle python-tldextract python-cairo gtk3 xapp

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
if ! command -v get-debloated-pkgs >/dev/null 2>&1; then
    wget "https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh" -O ./get-debloated-pkgs
    chmod +x ./get-debloated-pkgs
    ./get-debloated-pkgs --add-common --add-mesa --prefer-nano
else
    get-debloated-pkgs --add-common --add-mesa --prefer-nano
fi

echo "Installing webapp-manager..."
echo "---------------------------------------------------------------"
make all
sudo cp -r usr/* /usr/
