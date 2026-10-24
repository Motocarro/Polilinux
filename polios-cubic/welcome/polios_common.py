"""Shared code for PoliOS Welcome. No Qt, no D-Bus: safe to use from the root helper."""
import collections
import configparser
import os
import re
import stat
import subprocess

INSTALL_DIR = os.path.dirname(os.path.realpath(__file__))
CONF = os.path.join(INSTALL_DIR, "courses.conf")

REALM = "@polimi.it"
ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
APT_RE = re.compile(r"^[a-z0-9][a-z0-9+.-]+$")
FLATPAK_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)+$")  # reverse-DNS app id

Course = collections.namedtuple(
    "Course", "id title description title_en description_en apt flatpak")


def localized(course, lang):
    """(title, description) in `lang`. The default texts are Italian; English falls
    back to them when title_en / description_en are not set in courses.conf."""
    if lang == "en":
        return course.title_en or course.title, course.description_en or course.description
    return course.title, course.description


def normalize_username(text):
    """'10123456' -> '10123456@polimi.it'. Raises ValueError("empty") or
    ValueError("realm"): the GUI turns these codes into translated messages."""
    text = text.strip().lower()
    if not text or re.search(r"\s", text):
        raise ValueError("empty")
    if "@" not in text:
        return text + REALM
    if not text.endswith(REALM) or text.count("@") != 1 or text.startswith("@"):
        raise ValueError("realm")
    return text


def load_courses(path=CONF):
    """Read courses.conf. Returns (courses, problems); a bad section is reported
    in `problems` and skipped, it never crashes the wizard."""
    parser = configparser.ConfigParser(interpolation=None)
    try:
        parser.read(path, encoding="utf-8")
    except (configparser.Error, OSError, UnicodeDecodeError) as exc:
        return [], ["cannot read %s: %s" % (path, exc)]
    courses, problems = [], []
    for cid in parser.sections():
        sec = parser[cid]
        if sec.get("enabled", "yes").strip().lower() in ("no", "false", "0"):
            continue
        apt, flat = sec.get("apt", "").split(), sec.get("flatpak", "").split()
        bad = [p for p in apt if not APT_RE.match(p)] + \
              [f for f in flat if not FLATPAK_RE.match(f)]
        if not ID_RE.match(cid):
            problems.append("[%s]: course id must be lowercase letters, digits and -" % cid)
        elif bad:
            problems.append("[%s]: invalid package name(s): %s" % (cid, " ".join(bad)))
        elif not apt and not flat:
            problems.append("[%s]: no apt or flatpak packages listed" % cid)
        else:
            courses.append(Course(
                cid, sec.get("title", "").strip() or cid, sec.get("description", "").strip(),
                sec.get("title_en", "").strip(), sec.get("description_en", "").strip(),
                apt, flat))
    return courses, problems


def apt_candidate(pkg):
    """Version apt would install, or None if the package doesn't exist."""
    try:
        out = subprocess.run(["apt-cache", "policy", pkg], capture_output=True,
                             text=True, timeout=30).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("Candidate:"):
            version = line.split(":", 1)[1].strip()
            return None if version in ("", "(none)") else version
    return None


def untrusted_files():
    """Files the root helper depends on that are not root-owned or are writable by others."""
    bad = []
    for path in (INSTALL_DIR, os.path.join(INSTALL_DIR, "polios_common.py"),
                 os.path.join(INSTALL_DIR, "polios-welcome-helper"), CONF):
        try:
            st = os.stat(path)
        except OSError:
            bad.append(path)
            continue
        if st.st_uid != 0 or st.st_mode & (stat.S_IWGRP | stat.S_IWOTH):
            bad.append(path)
    return bad
