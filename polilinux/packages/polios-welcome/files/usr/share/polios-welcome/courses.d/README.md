# Adding a course

Create `<course-id>.toml` in this folder (one file per course):

```toml
id = "course-id"                    # lowercase letters, digits, dashes
name = "Course name shown to students"
description = "One line: what gets installed"
apt = ["package1", "package2"]      # Ubuntu/Mint packages
flatpak = ["org.example.App"]       # Flathub application IDs (optional)
```

Only open-source or freely redistributable software here. Proprietary tools
(e.g. Vivado) need their own helper and are not installed from this list.
Check package names with `apt-cache policy <name>` on Mint 22.3.
