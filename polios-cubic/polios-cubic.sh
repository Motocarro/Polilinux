#!/bin/bash
# PoliOS: customization for the Cubic chroot terminal (Linux Mint 22.3 -> PoliOS with KDE Plasma).
# Run as root, from this folder:   ./polios-cubic.sh        (safe to re-run; log: /var/log/polios-cubic.log)
# Test mode (no system changes, just writes the files):  POLIOS_ROOT=/some/dir POLIOS_SKIP_APT=1 ./polios-cubic.sh
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="${POLIOS_ROOT:-}"                 # empty = the real system
SYS=1; [ -z "$ROOT" ] || SYS=0          # SYS=1: also run apt/locale/icon-theme steps
WHITESUR_TAG="2026-09-10"               # pinned release of the WhiteSur icon theme
export DEBIAN_FRONTEND=noninteractive

step() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

mkdir -p "$ROOT/var/log"
exec > >(tee -a "$ROOT/var/log/polios-cubic.log") 2>&1

step "0/12 Checks"
[ "$SYS" = 0 ] || [ "$(id -u)" -eq 0 ] || die "run as root (in Cubic's terminal)"
for f in background.png logo.svg logo.png logo.txt; do
  [ -s "$HERE/assets/$f" ] || die "missing assets/$f (read assets/README.txt)"
done

step "1/12 Language, time zone, keyboard"
if [ "$SYS" = 1 ]; then
  apt-get update
  apt-get install -y locales language-pack-it language-pack-gnome-it language-pack-kde-it
  locale-gen it_IT.UTF-8
  update-locale LANG=it_IT.UTF-8 LANGUAGE=it:en      # no LC_ALL: it blocks per-user language changes
  ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
  echo "Europe/Rome" > /etc/timezone
fi
mkdir -p "$ROOT/etc/default"
cat > "$ROOT/etc/default/keyboard" << 'EOF'
XKBMODEL="pc105"
XKBLAYOUT="it"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
if [ "$SYS" = 1 ]; then
  dpkg-reconfigure -f noninteractive keyboard-configuration
  dpkg-reconfigure -f noninteractive tzdata
fi

step "2/12 PoliOS assets and name"
install -d -m 755 "$ROOT/usr/share/polios-assets"
for f in background.png logo.svg logo.png logo.txt splash.jpg; do
  [ -f "$HERE/assets/$f" ] && install -m 644 "$HERE/assets/$f" "$ROOT/usr/share/polios-assets/$f"
done
# logo.txt uses neofetch colour markers (${c1}, ${c2}); fastfetch writes them $1, $2
cp "$ROOT/usr/share/polios-assets/logo.txt" "$ROOT/usr/share/polios-assets/logo.neofetch"
sed -E 's/\$\{c([0-9])\}/$\1/g' "$ROOT/usr/share/polios-assets/logo.txt" > "$ROOT/usr/share/polios-assets/logo.fastfetch"
chmod 644 "$ROOT"/usr/share/polios-assets/logo.neofetch "$ROOT"/usr/share/polios-assets/logo.fastfetch

# Edit Mint's os-release instead of replacing it: keep the codenames that apt/PPA/installer scripts read.
OSREL="$ROOT/usr/lib/os-release"
[ -f "$OSREL" ] || die "$OSREL not found"
# shellcheck source=/dev/null
codename=$(. "$OSREL"; echo "${VERSION_CODENAME:-}")
# shellcheck source=/dev/null
[ -n "$codename" ] || codename=$(. "$ROOT/etc/lsb-release" 2>/dev/null; echo "${DISTRIB_CODENAME:-}")
# shellcheck source=/dev/null
ubuntu_codename=$(. "$OSREL"; echo "${UBUNTU_CODENAME:-noble}")
{
  echo 'NAME="PoliOS"'
  echo 'VERSION="1.0"'
  echo 'ID=polios'
  echo 'ID_LIKE="linuxmint ubuntu debian"'
  echo 'PRETTY_NAME="PoliOS 1.0"'
  echo 'VERSION_ID="1.0"'
  [ -z "$codename" ] || echo "VERSION_CODENAME=$codename"
  echo 'HOME_URL="https://polinetwork.org"'
  echo 'SUPPORT_URL="https://polinetwork.org"'
  echo 'BUG_REPORT_URL="https://polinetwork.org"'
  echo 'PRIVACY_POLICY_URL="https://polinetwork.org"'
  echo "UBUNTU_CODENAME=$ubuntu_codename"
} > "$OSREL.new" && mv "$OSREL.new" "$OSREL"
[ -L "$ROOT/etc/os-release" ] || cp "$OSREL" "$ROOT/etc/os-release"
# Mint also describes itself here; change only the human-readable parts, keep ID/codename.
[ ! -f "$ROOT/etc/lsb-release" ] || sed -i 's/^DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION="PoliOS 1.0"/' "$ROOT/etc/lsb-release"
for f in "$ROOT/etc/issue" "$ROOT/etc/issue.net"; do
  [ ! -f "$f" ] || sed -i -E 's/Linux Mint [0-9.]+ [A-Za-z]+/PoliOS 1.0/' "$f"
done
echo "polios" > "$ROOT/etc/hostname"

step "3/12 Remove Cinnamon and the apps we replace"
if [ "$SYS" = 1 ]; then
  # Only things Mint ships. (konsole/kate/kwrite/... must NOT be purged here: they are hard
  # dependencies of kde-plasma-desktop, purging them later would remove KDE itself.)
  named="mint-artwork-cinnamon hexchat thunderbird celluloid hypnotix drawing pix xterm file-roller evince gnome-calculator xed"
  doomed=$( { dpkg-query -W -f='${Package}\n' 'cinnamon*' 'nemo*' 2>/dev/null || true
              for p in $named; do dpkg -s "$p" >/dev/null 2>&1 && echo "$p" || true; done; } | sort -u )
  # shellcheck disable=SC2086
  [ -z "$doomed" ] || apt-get purge -y $doomed
  apt-get autoremove -y --purge
fi

step "4/12 KDE Plasma and the application suite"
if [ "$SYS" = 1 ]; then
  # kde-plasma-desktop only RECOMMENDS these, so --no-install-recommends would leave them out
  # (no window manager, no System Settings, no network/audio/power applets):
  plasma_essentials="kwin-x11 systemsettings plasma-nm plasma-pa powerdevil bluedevil kscreen xdg-desktop-portal-kde xdg-desktop-portal-gtk"
  # shellcheck disable=SC2086
  apt-get install -y --no-install-recommends \
    kde-plasma-desktop plasma-workspace plasma-desktop $plasma_essentials \
    dolphin kcalc eog totem gnome-terminal konsole okular ark zip unzip p7zip-full unrar-free gedit \
    git curl wget ca-certificates cups printer-driver-gutenprint network-manager-vpnc network-manager-openvpn \
    intel-microcode amd64-microcode linux-firmware ubuntu-drivers-common \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav ffmpeg libavcodec-extra fonts-noto fonts-noto-color-emoji fonts-liberation neofetch
  apt-mark manual konsole gnome-terminal neofetch >/dev/null
  if update-alternatives --list x-session-manager 2>/dev/null | grep -q startplasma-x11; then
    update-alternatives --set x-session-manager /usr/bin/startplasma-x11
  fi
  missing=""
  for p in plasma-desktop kwin-x11 systemsettings plasma-nm plasma-pa konsole gnome-terminal gedit okular dolphin neofetch; do
    dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
  done
  [ -z "$missing" ] || die "not installed after step 4:$missing"
fi

step "5/12 WhiteSur icon theme ($WHITESUR_TAG)"
if [ "$SYS" = 1 ] && [ ! -d /usr/share/icons/WhiteSur ]; then
  tmp=$(mktemp -d)
  git clone --depth 1 --branch "$WHITESUR_TAG" https://github.com/vinceliuice/WhiteSur-icon-theme.git "$tmp/ws"
  "$tmp/ws/install.sh" -t default
  rm -rf "$tmp"
  [ -d /usr/share/icons/WhiteSur ] || die "WhiteSur was not installed"
fi

step "6/12 KDE defaults, look-and-feel, mime types, browser bookmarks (from files/)"
cp -a --no-preserve=ownership "$HERE/files/." "$ROOT/"
rm -f "$ROOT/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc"   # from earlier manual attempts
chmod 755 "$ROOT/usr/local/bin/polios-first-login"
find "$ROOT/etc/skel" "$ROOT/etc/opt/chrome" "$ROOT/etc/firefox" "$ROOT/etc/default/grub.d" \
     "$ROOT/usr/share/plymouth/themes/polios" "$ROOT/usr/share/polios-assets/grub-background.png" \
     "$ROOT/usr/share/plasma/look-and-feel/org.polios.desktop" \
     "$ROOT/etc/xdg/autostart/polios-first-login.desktop" -type f -exec chmod 644 {} +
for j in "$ROOT/etc/opt/chrome/policies/managed/bookmarks.json" "$ROOT/etc/firefox/policies/policies.json"; do
  python3 -m json.tool "$j" > /dev/null || die "invalid JSON: $j"
done

step "7/12 Hide settings modules and uxterm from the menu"
apps="$ROOT/etc/skel/.local/share/applications"
mkdir -p "$apps"
hide() { # per-user override + NoDisplay inside the system file (inserted right after [Desktop Entry])
  printf '[Desktop Entry]\nType=Application\nNoDisplay=true\n' > "$apps/$(basename "$1")"
  if [ -f "$1" ] && ! grep -q '^NoDisplay=' "$1"; then
    sed -i '0,/^\[Desktop Entry\]/s//[Desktop Entry]\nNoDisplay=true/' "$1"
  fi
}
hide "$ROOT/usr/share/applications/uxterm.desktop"
for f in "$ROOT"/usr/share/applications/kcm_*.desktop; do
  [ -e "$f" ] && hide "$f"
done

step "8/12 neofetch / fastfetch"
mkdir -p "$ROOT/etc/skel/.config/neofetch"
if command -v neofetch >/dev/null 2>&1; then
  conf="$ROOT/etc/skel/.config/neofetch/config.conf"
  neofetch --print_config > "$conf"
  sed -i -e 's|^image_backend=.*|image_backend="ascii"|' \
         -e 's|^image_source=.*|image_source="/usr/share/polios-assets/logo.neofetch"|' \
         -e 's|^ascii_colors=.*|ascii_colors=(4 7)|' "$conf"
  grep -q 'logo.neofetch' "$conf" || die "could not set the neofetch logo"
else
  warn "neofetch is not installed: skipped its config (step 4 installs it)"
fi
# fastfetch is not in Ubuntu 24.04's repositories; its config is ready for when it is installed.

step "9/12 Boot splash (Plymouth) and GRUB look"
# Theme files and the GRUB drop-in came with files/. The theme uses your logo.png as its centered logo.
install -m 644 "$HERE/assets/logo.png" "$ROOT/usr/share/plymouth/themes/polios/watermark.png"
if [ "$SYS" = 1 ]; then
  update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
      /usr/share/plymouth/themes/polios/polios.plymouth 300
  update-alternatives --set default.plymouth /usr/share/plymouth/themes/polios/polios.plymouth
  [ ! -f /etc/plymouth/plymouthd.conf ] || sed -i 's/^Theme=.*/Theme=polios/' /etc/plymouth/plymouthd.conf
  update-initramfs -u -k all        # puts the splash into the initramfs
  # GRUB is not touched here: update-grub runs on the installed system and reads
  # /etc/default/grub.d/90-polios.cfg then (it would also fail inside the chroot).
fi

step "10/12 First-boot wizard (Wi-Fi + course software)"
if [ -d "$HERE/welcome" ]; then
  if [ "$SYS" = 1 ]; then
    [ -f "$HERE/welcome/ca/cachain_geant_harica.pem" ] || warn "welcome/ca/cachain_geant_harica.pem is missing: the Wi-Fi page will be disabled"
    sh "$HERE/welcome/install.sh"
  else
    echo "(test mode: skipped)"
  fi
else
  warn "no welcome/ folder next to this script: wizard skipped"
fi

step "11/12 Cleanup"
if [ "$SYS" = 1 ]; then
  apt-get autoremove -y --purge
  apt-get clean
fi
# Deliberately NOT done: rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* (it deletes anything staged
# in /tmp, such as this folder, and the apt lists the first-boot wizard needs).

step "12/12 Done"
echo "Check:  dpkg -l | grep -E 'konsole|gnome-terminal|kwin-x11|systemsettings|plasma-nm'"
echo "        ls /usr/share/polios-assets /usr/share/plasma/look-and-feel/org.polios.desktop"
echo "        readlink -f /usr/share/plymouth/themes/default.plymouth   # should end in polios.plymouth"
