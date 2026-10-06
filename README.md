# Polilinux: Project Plan

An (un)official Ubuntu-based distro for Politecnico di Milano students, built together with Polinetwork. Designed to be a ready-to-go environment for lectures: mainly for VMs (VMware, VirtualBox, UTM), also bare metal / dual boot.

## 0. Decisions already made

- [x] Base: Ubuntu, Kubuntu flavor (KDE Plasma, familiar to Windows users)
- [x] Release: Ubuntu 26.04 LTS (supported until 2031)
- [x] Architecture: "Ubuntu plus a thin layer" (meta-package + ISO), low maintenance, updates via `apt`
- [x] Target: engineering and CS students; **architecture students are explicitly out of scope**
- [x] First deliverable: ISO (for bare-metal testing and for testers); prebuilt VM images come later
- [x] Vivado is **not** part of the base system: it lives in a helper script only
- [x] Politecnico name/logo licensing is eventually handled by Polinetwork

## 1. Things to verify early

- [x] Does Kubuntu 26.04 still ship an X11 session? (affects clipboard sharing and auto-resize in VMs) answer: No, it finally uses Wayland!
- [x] Does Kubuntu publish arm64 desktop ISOs for 26.04, or must I build one? answer: no support for arm64, and [it seems to be quite a problemt to implement](https://discuss.kde.org/t/still-no-iso-for-installing-kubuntu-on-arm64/43130/3#:~:text=Plus-,The,development).
- [ ] Which tools do courses actually require? Ask students/professors and build a list beyond gcc, git, Vivado and the flowchart tool
- [x] Which course uses the flowchart tool, and for what: drawing diagrams or running them? answer: not really an issue
- [ ] Vivado 2026.2: check AMD release notes for 26.04 support (2026.1 supports 24.04) answer: not yet released
- [x] Canonical trademark rules: no "Ubuntu" name/logo implying official status; say "based on Ubuntu" answer: who cares
- [x] Choose a license for the project repo answer: GNUGPG 3.0

## 2. Repo and build setup

- [x] Create the GitHub repo
- [ ] Create the `polilinux-desktop` meta-package (depends on all the tools)
- [-] Decide where to host packages (own apt repo or PPA) answer: likely an actual repo
- [ ] First prototype ISO from Kubuntu 26.04 that only adds the meta-package (Cubic or `live-build`)
- [ ] Keep all customizations inside packages, not in manual ISO edits
- [ ] Branding: name, wallpaper, theme, boot splash (note the trademark rules above)

## 3. Package contents (meta-package)

- [ ] Compilers and tools: gcc, make, gdb, git
- [ ] Editors: Kate (GUI default for beginners), Vim as an extra
- [ ] Flowchart tool (see section 1): candidates are draw.io desktop, PseInt, Dia, yEd. Avoid Wine/Mono as it is terribly unreliable
- [ ] Open-source EDA/engineering tools: GHDL, KiCad, others as courses require
- [ ] Optional extras: FreeCAD, Blender, LibreCAD/QCAD (documented as NOT for architecture students)
- [ ] Note-taking app
- [ ] Guest integration: `open-vm-tools`, VirtualBox guest utilities, `spice-vdagent`, `qemu-guest-agent`

## 4. Eduroam / NetworkManager (reminder: set up during the build)

- [ ] Get the official Politecnico profile from eduroam CAT (cat.eduroam.org), including the CA certificate and server name
- [ ] Create the NetworkManager connection file without the password (root-owned, permissions `600`, in `/etc/NetworkManager/system-connections/`)
- [ ] Ship it in the meta-package or a small `polilinux-eduroam` package
- [ ] Test that it works in the live session and on the installed system, and that the user is asked for credentials on first connection

## 5. Vivado helper

- [ ] Script/small GUI: "Install Vivado" (opens the AMD download page, explains the steps, runs the installer once the file is downloaded)
- [ ] Detect the CPU architecture and explain clearly on arm64 that Vivado is x86-only
- [ ] Check the Ubuntu version: warn, don't block, on unsupported releases
- [ ] Handle the known missing-library workarounds
- [ ] Update the helper when Vivado 2026.2 is released
- [ ] (Optional) Installer integration, similar to the "proprietary codecs" checkbox in the Ubuntu/Mint installers (Calamares post-install step)

## 6. Testing

- [ ] Bare-metal test on the debug PC
- [ ] VM tests: VirtualBox, VMware, UTM
- [ ] Compare X11 and Wayland sessions in each VM (clipboard, resizing, performance)
- [ ] Tune KDE defaults for VMs (lighter effects)
- [ ] Share the ISO with a few helpers/testers and collect feedback
- [ ] Dual-boot test (including Secure Boot and NVIDIA drivers)

## 7. Apple Silicon / arm64

- [ ] Build an arm64 ISO/image
- [ ] Test on a Mac and on an iPad with UTM (check JIT availability on iPad)
- [ ] Experiment with x86 emulation for Vivado (Rosetta or QEMU user-mode) before promising anything
- [ ] Document honestly what works and what doesn't on Apple Silicon

## 8. Automation and release

- [ ] CI pipeline (e.g. GitHub Actions) that rebuilds the ISO from the meta-package
- [ ] Prebuilt VM images: `.ova` for VirtualBox/VMware and a UTM bundle
- [ ] Documentation: install guide for VM, dual boot and UTM
- [ ] Clear README: who it's for, who it's NOT for, how it differs from WSL
- [ ] Coordinate the announcement with Polinetwork

## 9. Later / nice to have

- [ ] Rebase on newer point releases of 26.04 as needed
- [ ] Add tools for more courses as the list grows
- [ ] Feedback channel for students (issues, form, or Polinetwork channel)

## Note

This readme file was mostly written by Claude, so will be most of the tools. You are free to report me any problem or give me any suggestion, as i still am the one prompting Claude to do stuff.
