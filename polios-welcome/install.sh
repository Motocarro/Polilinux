#!/bin/sh
# Install PoliOS Welcome system-wide.   Usage: sudo ./install.sh
# Works on a normal Mint system and inside the Cubic chroot terminal.
set -eu
[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0" >&2; exit 1; }
SRC=$(cd "$(dirname "$0")" && pwd)
DEST=/opt/polios-welcome

echo "==> Installing dependencies"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pyqt5 python3-dbus pkexec network-manager

echo "==> Installing files to $DEST (root-owned: the root helper refuses to run otherwise)"
rm -rf "$DEST"
install -d -m 755 "$DEST" "$DEST/ca"
install -m 755 "$SRC/polios-welcome" "$SRC/polios-welcome-helper" "$DEST/"
install -m 644 "$SRC/polios_common.py" "$SRC/courses.conf" "$DEST/"
for pem in "$SRC"/ca/*.pem; do
  [ -e "$pem" ] && install -m 644 "$pem" "$DEST/ca/"
done
ln -sf "$DEST/polios-welcome" /usr/local/bin/polios-welcome
ln -sf "$DEST/polios-welcome-helper" /usr/local/bin/polios-welcome-helper

mkdir -p /usr/share/applications /etc/xdg/autostart
cat > /usr/share/applications/polios-welcome.desktop << 'EOT'
[Desktop Entry]
Type=Application
Name=PoliOS Welcome
Comment=Polimi Wi-Fi and the software for your courses
Exec=/usr/local/bin/polios-welcome
Icon=system-software-install
Categories=System;Settings;
EOT
cat > /etc/xdg/autostart/polios-welcome.desktop << 'EOT'
[Desktop Entry]
Type=Application
Name=PoliOS Welcome
Exec=/usr/local/bin/polios-welcome --first-run
EOT

[ -f "$DEST/ca/cachain_geant_harica.pem" ] || \
  echo "WARNING: ca/cachain_geant_harica.pem is missing: the Wi-Fi page will be disabled (see README)."
echo "==> Done. Run: polios-welcome"
