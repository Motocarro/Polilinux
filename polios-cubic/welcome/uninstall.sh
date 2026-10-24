#!/bin/sh
# Remove PoliOS Welcome.   Usage: sudo ./uninstall.sh
set -eu
[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0" >&2; exit 1; }
rm -rf /opt/polios-welcome
rm -f /usr/local/bin/polios-welcome /usr/local/bin/polios-welcome-helper \
      /usr/share/applications/polios-welcome.desktop /etc/xdg/autostart/polios-welcome.desktop
echo "Removed. (Per-user state, if any: ~/.config/polios)"
