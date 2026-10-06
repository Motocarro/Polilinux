# Polilinux

**An (un)official Ubuntu-based Linux distribution for Politecnico di Milano students.**

[Note: Italian version of this README file coming soon!]

Many courses at Politecnico require Linux, but not every student is comfortable with it. Polilinux is a ready-to-use system with the tools needed for lectures already installed and configured, built by a student for students, with the approval of [Polinetwork](https://polinetwork.org).

> ⚠️ **Alpha software.** This is an early test build. Expect rough edges, and don't use it as your only system. Back up your data before installing it on real hardware, especially for dual boot.

## What is it?

Polilinux is **Kubuntu 26.04 LTS plus a thin layer**: a set of packages that installs the course tools and (soon) the Polimi-specific configuration on top of a normal Kubuntu system. It is not a from-scratch distribution, and it stays close to Ubuntu on purpose:

- Course instructions are written for Debian/Ubuntu and `apt`, and they work as written.
- Searching "`<problem>` Ubuntu" finds answers that apply to Polilinux.
- Updates arrive through Ubuntu's normal update mechanism. Polilinux only adds its own packages on top.

It uses the KDE Plasma desktop, whose layout (taskbar, start menu) is familiar to Windows users.

## Who is it for?

**For:** engineering and computer science students who need a Linux environment for their courses, particularly inside a virtual machine (VMware, VirtualBox, UTM) or as a dual boot.

**Not for:**
- **Architecture students.** The workflow of that faculty depends on software that doesn't run on Linux, and we prefer not to promise what we can't deliver. Some basic 2D/3D tools are included only as extras.
- **Everyday use.** Like Kali Linux, it is meant to get specific work done, not to be a general-purpose system.
- **People who already use WSL happily.** WSL is a good option too. Polilinux offers a full graphical desktop with everything preconfigured.

## Current state (alpha)

### What works

- Live session boots and the system installs on a full installation
- Meta-packages install correctly and the included programs run

### What's included

| Category | Software |
|---|---|
| Development | gcc and the standard build tools (`build-essential`), gdb, git |
| Editors | Kate (graphical, beginner-friendly), Vim |
| Digital design | GHDL, GTKWave, KiCad |
| Virtual machine integration | open-vm-tools (VMware), VirtualBox guest utilities, SPICE/QEMU guest agents (UTM) |
| Extras (optional) | LibreCAD, Blender, Dia (flowcharts and diagrams), Xournal++ (handwritten notes) |

### Known limitations

- **The installer and the look are still stock Kubuntu.** Branding, wallpaper and installer customization haven't been done yet.
- **Wayland only.** Kubuntu 26.04 no longer includes an X11 session. Clipboard sharing and automatic window resizing in VMs are still being tested on each hypervisor.
- **Vivado is not included.** It is proprietary, can't be redistributed, and isn't yet officially supported on Ubuntu 26.04. An install helper is planned for when support arrives.
- **amd64 only.** There's no native ARM build yet. On Apple Silicon Macs and iPads, UTM can emulate the amd64 image, but it is slow.
- Wi-Fi for the university network is not preconfigured yet.

### System Requirements:

| *Hardware* | **Required** | **Recommended** |
|---|---|---|
| CPU | 2/2 Cores/Threads 64bit | 4/4 Cores/Threads 64bit |
| GPU | *not required* | AMD Radeon or Vega |
| RAM | 4 GiB (4096 MiB) | 8 GiB (8192 MiB) |
| Storage| 25 GiB | 64 GiB |
|Graphics| a display | 1920x1080 |
| IO (bare metal only) | 1x USB-A 2.0 | 1x USB-A or USB-C 3.0 |

### Tested on
Device: Lenovo Thinkpad T14 Gen 1 20S1 running macOS Sonoma 14.7.1; YMMV

| Environment | Live | Install | VM tools | Notes |
|---|---|---|---|---|
| _VirtualBox_ | | | | |
| _VMware_ |Works|Works|Works|*Tested on VMWare Fusion 26H2u1 for macOS*|
| _UTM (Apple Silicon)_ | | | | |
| _Bare metal_ | | | | |

## Download and install

1. Download the latest ISO from the [Releases page](../../releases) (check the MD5 checksum published with it).
2. **In a virtual machine:** create a VM, attach the ISO, and boot. In VirtualBox, choose the *VMSVGA* graphics controller; in UTM, use a *virtio-gpu* display. Give the VM enough RAM and disk space for a full KDE Plasma desktop.
3. **On a real computer:** write the ISO to a USB drive and boot from it. Use a dual boot only if you know how to keep your other system safe.
4. Try the live session first, then run the installer from the desktop.

## Roadmap

### Coming next

- [ ] Branding: name, wallpaper, theme, boot splash
- [ ] KDE defaults tuned for students and for use inside VMs
- [ ] **Custom installer**: replace the stock Kubuntu look and flow with a Polilinux one
- [ ] Polimi Wi-Fi (`polimi-protected`) and wired 802.1X preconfigured with the university's CA certificate (users only enter their own credentials)

### Planned

- [ ] Vivado install helper (waiting for official Ubuntu 26.04 support in Vivado 2026.2)
- [ ] Google Chrome install helper
- [ ] Better flowchart tooling (a tool that can also run the flowcharts, not just draw them)
- [ ] Ready-made VM images (`.ova` for VirtualBox/VMware, UTM bundle)
- [ ] Automatic ISO builds (CI)
- [ ] A native arm64 build for Apple Silicon, if feasible
- [ ] Package repository hosted under Polinetwork
- [ ] More tools, as courses ask for them (the list of courses is still being collected)

The detailed task list is in [`Checklist.md`](Checklist.md).

## Building from source

Polilinux is defined by Debian packages, built from the `packages/polilinux/` directory. On an Ubuntu system:

```bash
sudo apt install build-essential devscripts debhelper git lintian
cd packages/polilinux
dpkg-buildpackage -us -uc -b
cd ..
sudo apt install ./polilinux-*.deb     # make sure old versions aren't left in the folder
```

The package `polilinux-desktop` pulls in everything else. The experimental ISO was made with [Cubic](https://github.com/PJ-Singh-001/Cubic): start from the Kubuntu 26.04 ISO, install the `.deb` files in the chroot and generate the ISO. A reproducible build pipeline is on the roadmap.

## Feedback and contributing

This project depends on testers. If you try Polilinux, please open an **issue** with:

- where you ran it (hypervisor or hardware, host OS)
- what you expected and what happened
- any error messages or screenshots

If your course needs a tool that isn't included, open an issue with the course name and the tool.

## License and trademarks

- Project code and packaging: GNU GPL-3.0
- Polilinux is based on Ubuntu and Kubuntu. It is **not** an official Canonical, Ubuntu, Kubuntu or KDE product and is not endorsed by them. "Ubuntu" and "Kubuntu" are trademarks of Canonical Ltd.
- Included software is distributed under its own licenses. Proprietary software (such as Vivado) is not redistributed.
- Use of the Politecnico di Milano name and logo is coordinated with Polinetwork.
