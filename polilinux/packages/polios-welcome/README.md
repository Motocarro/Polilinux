# polios-welcome (first-run wizard)

Runs once at first login (never in the live session; the guard file is
`~/.config/polios/welcome-done`), and can be launched again from the menu.

Pages: **Wi-Fi** (only if not already online; disabled until implemented) →
**Courses** (checkbox list) → **Install** (live log) → **Done**.

## How it works

- Courses are plain data: one TOML file per course in
  `files/usr/share/polios-welcome/courses.d/` (format in that folder's README).
  Polinetwork admins can add courses with a pull request: no new `.deb`, no apt repo.
- The GUI (`welcome.py`, PyQt5) never runs as root. It calls
  `pkexec /usr/lib/polios-welcome/install-courses <ids>`. That helper takes
  course IDs only and looks packages up itself, so it can't install arbitrary software.
- `wifi.py` is a stub: fill it in from the Polimi guide, then set `ENABLED = True`.

## Testing

```bash
# helper, without installing anything:
python3 files/usr/lib/polios-welcome/install-courses --dry-run \
  --courses-dir files/usr/share/polios-welcome/courses.d example-programming
# GUI from the source tree (needs python3-pyqt5):
python3 files/usr/lib/polios-welcome/welcome.py
```

The GUI from the source tree will ask for your password through pkexec only
if the helper is installed at `/usr/lib/polios-welcome/` (i.e. after installing the .deb).

## Qt version

Mint 22.3 / Plasma 5.27 → PyQt5. When moving to Mint 27 (Plasma 6) switch to PyQt6
or PySide6: the code is plain QtWidgets and should port with small changes.
