# polios-cubic: PoliOS customization for Cubic

One script that turns the Mint 22.3 chroot into PoliOS (KDE Plasma). It replaces the commands
from rentry.co/PoliOS, with fixes (see "What changed").

## Import into Cubic (everything in one go)

Contents of this folder: the PoliOS customization (`polios-cubic.sh`, `assets/`, `files/`) AND the first-boot
wizard (`welcome/`). One copy, one command.

**Before Cubic**
1. Unzip `polios-cubic.zip` on your computer.
2. Put the Polimi certificate in `welcome/ca/cachain_geant_harica.pem` (the Wi-Fi page is disabled without it;
   `welcome/fetch-ca.sh` tries to download it). Skip this and everything else still works.

**In Cubic**
3. Start a NEW project from the original `linuxmint-22.3-cinnamon-64bit.iso` (recommended: clean and
   reproducible). If you must start from your coworker's ISO, it also works (the script removes his hand-written
   panel file), but anything else he changed stays.
4. On the terminal page, copy the whole `polios-cubic` folder in with the Copy button (or drag and drop).
   Then find it: `ls` and `pwd`. If it landed in /tmp, move it: `cp -a /tmp/polios-cubic /root/ && cd /root/polios-cubic`.
5. Run it (use `bash`, so file permissions don't matter):
   ```
   cd polios-cubic && bash polios-cubic.sh
   ```
   It takes a while (downloads KDE, icons, language packs) and needs internet in the chroot. It stops at the first
   error with a message. Log: `/var/log/polios-cubic.log`.
6. Check:
   ```
   dpkg -l | grep -E 'konsole|gnome-terminal|kwin-x11|systemsettings|plasma-nm'
   readlink -f /usr/share/plymouth/themes/default.plymouth   # ends in polios.plymouth
   ls /opt/polios-welcome /usr/share/polios-assets
   ```
7. Next pages: on "packages to remove" do NOT tick konsole, gnome-terminal, plasma-*, kwin-*. If Cubic offers
   to update the kernel/initrd, accept (the boot splash lives in the initrd). Generate the ISO.

**After the ISO: test in a VM**
- Live session: PoliOS wallpaper, panel with start button, terminal available, boot splash on boot.
- Install it, log in: the wizard opens once (Italian by default, English button bottom left);
  `neofetch` shows the PoliOS logo.

## What it sets up

Locale/keyboard/time zone (Italian), PoliOS name (os-release, lsb-release, issue), Cinnamon removal,
KDE Plasma + apps, WhiteSur icons (pinned release), default theme/panel/wallpaper for new users,
default apps, Chrome/Firefox bookmarks, neofetch/fastfetch logo, PoliOS boot splash (Plymouth) and a GRUB background.

## Boot splash and GRUB

- **Boot splash**: new Plymouth theme `polios` (centered `logo.png`, blue-to-navy background like the wallpaper,
  spinner). It is Ubuntu's own `spinner` theme with the logo swapped, so the disk-encryption password prompt
  still works. Step 9 registers it (`update-alternatives`, priority 300) and runs `update-initramfs -u -k all`.
  If the live ISO still shows the Mint splash, regenerate the kernel/initrd in Cubic and check
  `readlink -f /usr/share/plymouth/themes/default.plymouth`.
- **GRUB** (installed system only): `/etc/default/grub.d/90-polios.cfg` sets a dark-blue background with the
  logo and blue highlight. It takes effect when the installer runs `update-grub`. To go back to stock, delete
  that file. The USB boot menu of the live ISO is separate (Cubic's boot page) and not changed.
  `splash.jpg` is not used for GRUB: its white area would make the menu text unreadable.

## What changed compared to the original commands

- **Panel and wallpaper**: the hand-written `plasma-org.kde.plasma.desktop-appletsrc` is gone. Plasma
  ignores or breaks such files (the desktop needs a real activity id; no clock/tray were listed).
  The default layout now comes from a look-and-feel package (`org.polios.desktop`), the mechanism
  Plasma's own Breeze uses. A one-time autostart (`polios-first-login`) re-applies the wallpaper as a fallback.
- **Terminals**: `konsole` and `gnome-terminal` are installed explicitly, marked manual, verified at the
  end of step 4 (the script stops if one is missing), and a terminal is pinned in the panel.
- **`--no-install-recommends` side effect**: `kwin-x11`, `systemsettings`, `plasma-nm`, `plasma-pa`,
  `powerdevil`, `bluedevil`, `kscreen` and the portals are only *recommended* by Plasma, so they were being
  skipped. They are now listed explicitly.
- **Purge list**: `konsole kate kwrite keditbookmarks gwenview` removed from it. They are not on Mint, and
  if purged after Plasma is installed apt removes `kde-baseapps` and KDE with them.
- **os-release** is edited, not replaced: `VERSION_CODENAME`/`UBUNTU_CODENAME` stay (apt/PPA/installer
  scripts read them); `ID_LIKE` uses `linuxmint`, the real Mint ID.
- `LC_ALL` is no longer forced; `language-pack-kde-it` added (KDE apps in Italian).
- WhiteSur pinned to a release tag; hiding settings modules inserts `NoDisplay=true` under `[Desktop Entry]`.
- Cleanup no longer runs `rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*`.
- neofetch/fastfetch configs with the PoliOS logo (new): `${c1}` = blue, `${c2}` = white in both.
- Boot splash and GRUB background (the original commands did neither).

## Still open

- The panel pins `google-chrome`, `webeep-sync` and `mintinstall`, but nothing installs Chrome or WeBeep Sync;
  Plasma hides launchers whose app is missing.
- The login screen is still Mint's LightDM (Mint logo).
- fastfetch is not in Ubuntu 24.04's repositories: check `apt-cache policy fastfetch` on Mint; the config is ready.
- Untested here: a real Cubic run, Plasma applying the layout, and the Plymouth splash on screen (its files and
  theme structure were validated, not rendered). Test the splash first in a VM; `Esc` shows boot text if it misbehaves.
