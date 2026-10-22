# PoliOS Welcome (standalone)

First-run wizard: (1) Polimi Wi-Fi credentials, (2) pick your courses, (3) install their
software. No packaging or repo needed: copy this folder anywhere and run `install.sh`.

```
courses.conf            <- THE file to edit: courses and their apt / flatpak packages
polios-welcome          the wizard (PyQt5)
polios-welcome-helper   small root helper (via pkexec): installs, or --check validates
polios_common.py        shared code
install.sh / uninstall.sh / fetch-ca.sh
ca/                     put cachain_geant_harica.pem here
tests/                  python3 -m unittest discover tests
```

## 1. Test on the Mint VM

```bash
cd polios-welcome
./fetch-ca.sh            # optional, see "CA" below
sudo ./install.sh
polios-welcome --dry-run # real run: polios-welcome
```

- `--dry-run` simulates the software installation (apt `-s`): nothing is installed, but
  package names and dependencies are really resolved. Wi-Fi profiles ARE really created
  (delete with `nmcli connection delete polimi-protected`).
- No Wi-Fi adapter (VM)? The Wi-Fi page is skipped. Use `polios-welcome --force-wifi` to see it.
- Test the first-login behavior: `rm ~/.config/polios/welcome-done`, log out and in.
  (Autostart runs `--first-run`: once per user, never in the live session.)
- Start over: `sudo ./uninstall.sh`, or restore a VM snapshot.

## 2. Where the apps go: `courses.conf`

```ini
[aerospace]
title = Aerospace Engineering
description = Simulation and CAD
apt = octave freecad
flatpak = org.kicad.KiCad
```

- `apt` = apt package names, `flatpak` = Flathub app IDs (installed system-wide).
- Check names before shipping, no root needed: `polios-welcome-helper --check`
  (reports any apt package that does not exist on this system).
- Edit the copy in this folder and re-run `sudo ./install.sh`, or edit
  `/opt/polios-welcome/courses.conf` directly while testing.
- The root helper only installs what is listed in the root-owned `courses.conf`.

## 3. Into Cubic

In the chroot terminal: copy this folder in, `./install.sh`, and check
`ls /etc/xdg/autostart/polios-welcome.desktop /opt/polios-welcome`.
(The wizard does not start in the live session and starts at the first login of the
installed system.) Put `ca/cachain_geant_harica.pem` in before installing.

## CA (Wi-Fi certificate)

Without `ca/cachain_geant_harica.pem` the Wi-Fi page disables itself. `fetch-ca.sh`
downloads it from the Polimi ICT page (untested against the live site; otherwise download
the zip from the guide and extract it into `ca/`). Confirm with Polinetwork that it can
be bundled in the ISO.

## Wi-Fi settings used (from the Polimi ICT guide, "TTLS - Linux")

`polimi-protected`, WPA/WPA2 Enterprise, TTLS, anonymous identity `anonymous@polimi.it`,
domain `wifi.polimi.it`, CA `cachain_geant_harica.pem`, inner auth PAP, username
`<codice persona>@polimi.it` (added automatically). The optional wired profile uses the same
values; it can fail at home, so it is off by default.

## Known limits

- Tested: config parsing, helper (dry run, refusals, flatpak path), wizard flow in an offscreen
  window. NOT tested: the real NetworkManager profile, a real (non-dry) install, `fetch-ca.sh`.
- Qt5 on purpose (follows the Plasma 5.27 theme). Mint 27 / Plasma 6 may need a PyQt6 port.
- English only for now.
