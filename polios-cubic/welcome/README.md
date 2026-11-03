# PoliOS Welcome

First-run wizard: (1) Polimi Wi-Fi credentials, (2) pick your courses, (3) install their software.
Italian by default, English with one click. Part of `polios-cubic` (the script installs it), but it also
works on its own: `sudo ./install.sh`.

```
courses.conf            the course list built into the system  <- the file to edit
polios.conf             where the ONLINE course list lives (GitHub URL, empty = off)
polios-welcome          the wizard (PyQt5)
polios-welcome-helper   small root helper (via pkexec): installs, lists, or --check validates
polios_common.py        shared code
ca/                     the Polimi certificate chain (included)
install.sh / uninstall.sh      tests/   (python3 -m unittest discover tests)
```

## Test on a VM

```bash
sudo ./install.sh
polios-welcome --dry-run      # nothing is installed; apt dependencies are really resolved
```
`--force-wifi` shows the Wi-Fi page without a Wi-Fi adapter; `--lang=en` starts in English.
First-login behaviour: `rm ~/.config/polios/welcome-done`, log out and in. Start over: `sudo ./uninstall.sh`.

## Course list: built-in and online

```ini
[aerospace]
title = Ingegneria Aerospaziale
title_en = Aerospace Engineering
description = Simulazione e CAD
apt = octave freecad
flatpak = org.kicad.KiCad
extra = google-chrome        # optional; only recipes known to the helper
```
- **Built in**: `courses.conf` (installed to `/opt/polios-welcome/`). Always works, also offline.
- **Online**: put the same kind of file in the PoliOS GitHub repo and set, in `polios.conf`:
  `courses_url = https://raw.githubusercontent.com/ORG/REPO/BRANCH/courses.conf`
  The wizard shows the built-in list immediately, then replaces it with the online one when it arrives
  (offline or on any error it silently keeps the built-in list). New course = edit the file on GitHub,
  no new ISO and no new `polios-welcome`.
- Check names before publishing a list: `polios-welcome-helper --check path/to/courses.conf`.

### Who can install what (security)

Whoever can edit the online file decides what gets installed on students' computers (as root, after the
student's password). So:
- **Protect that branch** on GitHub: pull requests + required review, no direct pushes.
- The list can only name **apt packages, Flathub apps, or built-in recipes** (`extra`: only `google-chrome`
  for now). It cannot carry URLs, scripts or new apt sources: those checks are in the root helper.
- The URL is fixed in the root-owned `polios.conf`, must be `https://raw.githubusercontent.com/...`, redirects
  elsewhere are refused, size is capped (256 KB), and the root helper fetches the list itself (it never trusts
  a copy made by the user-level wizard).
- Students can hover a course to see exactly which packages it installs.

## Wi-Fi

`polimi-protected`, WPA/WPA2 Enterprise, TTLS, anonymous identity `anonymous@polimi.it`, domain
`wifi.polimi.it`, certificate `ca/cachain_geant_harica.pem` (included with Polinetwork's permission),
inner authentication PAP, username `<codice persona>@polimi.it` (added automatically). The profile is
created over D-Bus (the password never appears on a command line); re-running the wizard replaces it, which
is how to update an expired password. The optional wired 802.1X profile is off by default.

## Known limits

Tested: list parsing, online fetch (real HTTPS and local server), helper (dry run, refusals), wizard flow
and async list update in an offscreen window, both languages. NOT tested: the real NetworkManager profile,
a real (non-dry) install, the real Chrome download. Qt5 on purpose (Plasma 5.27); Mint 27 may need PyQt6.
