"""Polimi Wi-Fi setup: STUB. Fill this in once the guide and screenshots are available.

Needed from the guide: SSID, EAP method, phase-2 authentication, domain / server name,
anonymous identity, CA certificate (and where to install it), username format.

Notes for the real implementation:
- Do NOT pass the password on a command line (visible to other users via `ps`).
  Use NetworkManager's D-Bus API, or feed nmcli through stdin/--ask.
- Never log the password, and never write it to a file of our own: only NetworkManager stores it.
- The connection must work for the student without root; decide system vs. user connection.
"""

# Flip to True in welcome.py only when configure() is implemented and tested.
ENABLED = False


def configure(username: str, password: str) -> None:
    raise NotImplementedError("Wi-Fi setup is not implemented yet")
