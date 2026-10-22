"""Course manifests, shared by the GUI and the root install helper.

Each course is one TOML file in COURSES_DIR. See ../../share/polios-welcome/courses.d/README.md
"""
import re
import sys
import tomllib
from pathlib import Path

COURSES_DIR = Path("/usr/share/polios-welcome/courses.d")

ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
APT_RE = re.compile(r"^[a-z0-9][a-z0-9+.\-]*$")
FLATPAK_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._\-]*$")


def _names(data, key, regex, path):
    values = data.get(key, [])
    if not isinstance(values, list):
        raise ValueError(f"'{key}' must be a list")
    for v in values:
        if not isinstance(v, str) or not regex.match(v):
            raise ValueError(f"invalid {key} entry: {v!r}")
    return values


def _validate(data, path):
    cid = data.get("id", "")
    if not ID_RE.match(str(cid)):
        raise ValueError("missing or invalid 'id' (lowercase letters, digits, dashes)")
    if not str(data.get("name", "")).strip():
        raise ValueError("missing 'name'")
    return {
        "id": cid,
        "name": str(data["name"]).strip(),
        "description": str(data.get("description", "")).strip(),
        "apt": _names(data, "apt", APT_RE, path),
        "flatpak": _names(data, "flatpak", FLATPAK_RE, path),
    }


def load_courses(directory=COURSES_DIR):
    """Return {id: course}. Broken files are skipped with a warning, never fatal."""
    courses = {}
    for path in sorted(Path(directory).glob("*.toml")):
        try:
            with open(path, "rb") as f:
                course = _validate(tomllib.load(f), path)
        except (OSError, tomllib.TOMLDecodeError, ValueError) as e:
            print(f"polios-welcome: skipping {path.name}: {e}", file=sys.stderr)
            continue
        courses[course["id"]] = course
    return courses
