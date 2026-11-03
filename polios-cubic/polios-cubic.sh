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

STEP=0
step() { STEP=$((STEP + 1)); printf '\n==> [%s] %s\n' "$STEP" "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Hide an application from every menu: per-user override (skel) + NoDisplay in the system file.
hide_app() {   # desktop-file name, e.g. uxterm.desktop
  mkdir -p "$ROOT/etc/skel/.local/share/applications"
  printf '[Desktop Entry]\nType=Application\nNoDisplay=true\n' > "$ROOT/etc/skel/.local/share/applications/$1"
  local f="$ROOT/usr/share/applications/$1"
  if [ -f "$f" ] && ! grep -q '^NoDisplay=' "$f"; then
    sed -i '0,/^\[Desktop Entry\]/s//[Desktop Entry]\nNoDisplay=true/' "$f"
  fi
}

# Purge a package only if apt would remove nothing else that matters (no other Mint/KDE/login
# packages). Returns 1 when it kept the package, so the caller can hide it instead.
purge_or_hide() {   # package
  local pkg=$1 others
  dpkg -s "$pkg" >/dev/null 2>&1 || return 0
  others=$(apt-get -s purge "$pkg" | awk '/^(Remv|Purg) /{print $2}' | grep -vx "$pkg" \
           | grep -E '^(mint|cinnamon|lightdm|slick-greeter|kde-|plasma-|kwin|sddm|konsole|dolphin)' || true)
  if [ -n "$others" ]; then
    warn "not purging $pkg: apt would also remove: $(echo "$others" | tr '\n' ' ')"
    return 1
  fi
  apt-get purge -y "$pkg"
}

mkdir -p "$ROOT/var/log"
exec > >(tee -a "$ROOT/var/log/polios-cubic.log") 2>&1

step "Checks"
[ "$SYS" = 0 ] || [ "$(id -u)" -eq 0 ] || die "run as root (in Cubic's terminal)"
for f in background.png logo.svg logo.png logo.txt; do
  [ -s "$HERE/assets/$f" ] || die "missing assets/$f (read assets/README.txt)"
done

step "Language, time zone, keyboard"
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

step "PoliOS assets and name"
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

step "Remove Cinnamon and the apps we replace"
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

step "KDE Plasma and the application suite"
if [ "$SYS" = 1 ]; then
  # kde-plasma-desktop only RECOMMENDS these, so --no-install-recommends would leave them out
  # (no window manager, no System Settings, no network/audio/power applets):
  plasma_essentials="kwin-x11 systemsettings plasma-nm plasma-pa powerdevil bluedevil kscreen xdg-desktop-portal-kde xdg-desktop-portal-gtk"
  # shellcheck disable=SC2086
  apt-get install -y --no-install-recommends \
    kde-plasma-desktop plasma-workspace plasma-desktop $plasma_essentials \
    dolphin kcalc eog totem konsole okular ark zip unzip p7zip-full unrar-free gedit \
    git curl wget ca-certificates cups printer-driver-gutenprint network-manager-vpnc network-manager-openvpn \
    intel-microcode amd64-microcode linux-firmware ubuntu-drivers-common \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav ffmpeg libavcodec-extra fonts-noto fonts-noto-color-emoji fonts-liberation neofetch flatpak
  apt-mark manual konsole neofetch >/dev/null
  if update-alternatives --list x-session-manager 2>/dev/null | grep -q startplasma-x11; then
    update-alternatives --set x-session-manager /usr/bin/startplasma-x11
  fi
  missing=""
  for p in plasma-desktop kwin-x11 systemsettings plasma-nm plasma-pa konsole gedit okular dolphin neofetch flatpak; do
    dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
  done
  [ -z "$missing" ] || die "not installed after the KDE step:$missing"
  # GNOME Terminal looks out of place in KDE: remove it (or hide it if Mint's packages depend on it)
  purge_or_hide gnome-terminal || true
fi
hide_app org.gnome.Terminal.desktop

step "WeBeep Sync (GPL-3.0, from its GitHub release)"
if [ "$SYS" = 1 ]; then
  tmp=$(mktemp -d); chmod 755 "$tmp"
  if curl -fsSL --max-time 300 -o "$tmp/webeep-sync.deb" \
       https://github.com/toto04/webeep-sync/releases/latest/download/webeep-sync-debian.deb \
     && [ "$(dpkg-deb -f "$tmp/webeep-sync.deb" Package 2>/dev/null)" = "webeep-sync" ]; then
    apt-get install -y "$tmp/webeep-sync.deb"
    echo "WeBeep Sync $(dpkg-query -W -f='${Version}' webeep-sync) installed"
  else
    warn "could not download WeBeep Sync: it will be missing (the panel hides launchers of missing apps)"
  fi
  rm -rf "$tmp"
fi

step "WhiteSur icon theme ($WHITESUR_TAG)"
if [ "$SYS" = 1 ] && [ ! -d /usr/share/icons/WhiteSur ]; then
  tmp=$(mktemp -d)
  git clone --depth 1 --branch "$WHITESUR_TAG" https://github.com/vinceliuice/WhiteSur-icon-theme.git "$tmp/ws"
  "$tmp/ws/install.sh" -t default
  rm -rf "$tmp"
  [ -d /usr/share/icons/WhiteSur ] || die "WhiteSur was not installed"
fi

step "KDE defaults, look-and-feel, mime types, browser bookmarks (from files/)"
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

step "Hide settings modules and uxterm from the menu"
hide_app uxterm.desktop
for f in "$ROOT"/usr/share/applications/kcm_*.desktop; do
  [ -e "$f" ] && hide_app "$(basename "$f")"
done

step "Mint first-run popups and login screen"
# 1) "Welcome to Linux Mint": remove it, or hide every autostart entry that starts it.
if [ "$SYS" = 1 ]; then purge_or_hide mintwelcome || true; fi
mkdir -p "$ROOT/etc/skel/.config/autostart"
for f in "$ROOT"/etc/xdg/autostart/*.desktop; do
  [ -e "$f" ] || continue
  if grep -qi 'mintwelcome' "$f"; then
    name=$(basename "$f")
    printf '[Desktop Entry]\nType=Application\nHidden=true\n' > "$ROOT/etc/skel/.config/autostart/$name"
    grep -q '^Hidden=' "$f" || sed -i '0,/^\[Desktop Entry\]/s//[Desktop Entry]\nHidden=true/' "$f"
    echo "hid Mint Welcome autostart: $name"
  fi
done
echo "Other Mint autostart entries still present (decide if you want them in KDE):"
grep -li 'mint' "$ROOT"/etc/xdg/autostart/*.desktop 2>/dev/null | sed 's|.*/|   |' || true
# 2) Login screen (LightDM + slick-greeter): PoliOS background and logo.
GREETER="$ROOT/etc/lightdm/slick-greeter.conf"
mkdir -p "$ROOT/etc/lightdm"
if [ "$SYS" = 1 ] && dpkg -S "$GREETER" >/dev/null 2>&1 && [ -z "$(dpkg-divert --list "$GREETER")" ]; then
  # owned by a Mint package: divert it so package upgrades cannot bring back the Mint wallpaper
  dpkg-divert --local --rename --add --divert "$GREETER.mint" "$GREETER"
fi
cat > "$GREETER" << 'EOF'
[Greeter]
background=/usr/share/polios-assets/background.png
background-color=#032650
draw-user-backgrounds=false
draw-grid=false
logo=/usr/share/polios-assets/logo.png
EOF
chmod 644 "$GREETER"

step "neofetch / fastfetch"
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

step "Boot splash (Plymouth) and GRUB look"
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

step "First-boot wizard (Wi-Fi + course software)"
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

step "Cleanup"
if [ "$SYS" = 1 ]; then
  apt-get autoremove -y --purge
  apt-get clean
fi
# Deliberately NOT done: rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* (it deletes anything staged
# in /tmp, such as this folder, and the apt lists the first-boot wizard needs).

step "Done"
echo "Check:  dpkg -l | grep -E 'konsole|gnome-terminal|kwin-x11|systemsettings|plasma-nm'"
echo "        ls /usr/share/polios-assets /usr/share/plasma/look-and-feel/org.polios.desktop"
echo "        readlink -f /usr/share/plymouth/themes/default.plymouth   # should end in polios.plymouth"
