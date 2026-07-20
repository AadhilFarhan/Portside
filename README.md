<div align="center">

  <img src="Assets/icon-256.png" width="128" alt="Portside app icon" />

  <h1>Portside</h1>

  <p><b>Your localhost, in the menu bar.</b></p>

  <p>
    See every dev server running on your Mac, kill the one squatting on a port —<br/>
    then open any of them on your phone with a QR code.
  </p>

<p>
  <a href="https://github.com/AadhilFarhan/Portside/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/AadhilFarhan/Portside/build.yml?branch=main&label=build" alt="Build status" /></a>
  <a href="https://github.com/AadhilFarhan/Portside/blob/main/LICENSE"><img src="https://img.shields.io/github/license/AadhilFarhan/Portside?color=blue" alt="License: MIT" /></a>
  <a href="https://github.com/AadhilFarhan/Portside/releases/latest"><img src="https://img.shields.io/github/v/release/AadhilFarhan/Portside?label=latest&color=red" alt="Latest release" /></a>
  <a href="https://github.com/AadhilFarhan/Portside/releases"><img src="https://img.shields.io/github/downloads/AadhilFarhan/Portside/total?label=downloads&color=brightgreen" alt="Total downloads" /></a>
  <a href="https://github.com/AadhilFarhan/Portside/stargazers"><img src="https://img.shields.io/github/stars/AadhilFarhan/Portside?color=yellow" alt="GitHub stars" /></a>
</p>

  <p>
    <a href="https://github.com/AadhilFarhan/Portside/releases/latest/download/Portside.dmg"><b>Download</b></a>
    &nbsp;·&nbsp;
    <a href="https://aadhilfarhan.github.io/Portside/">Website</a>
    &nbsp;·&nbsp;
    <a href="#installation">Install guide</a>
    &nbsp;·&nbsp;
    <a href="#build-from-source">Build from source</a>
  </p>

</div>

---

Three rituals every web developer knows: `Error: listen EADDRINUSE :3000` followed by `lsof -i :3000` and `kill -9`; "I need to test this on my phone" followed by fighting local IPs or paying for a tunnel; and "what do I even have running right now?" Portside owns all three from one menu-bar app.

---

## Features

### See everything running

Every listening TCP port, with the project behind it — read straight from `package.json` and other manifests — plus framework, uptime, memory, and bind address. Dev servers sort to the top; system daemons collapse into their own section.

### Kill it in one click

Graceful `SIGTERM` first, escalating to `SIGKILL` only if the process won't go. No more copy-pasting a PID out of `lsof`.

### Open it on your phone

One click shows a QR code that opens the server from any device on your Wi-Fi — **including servers bound to `127.0.0.1` only**, the common case for `vite`, `next dev`, and friends. Portside bridges these with a built-in TCP relay: it listens on your LAN address and pipes bytes straight to the loopback port, so HTTP, WebSockets, and hot-reload all just work. Stop sharing and the relay is gone; nothing about your dev setup has to change.

### A full dashboard, not just a popover

Click the window icon in the menu-bar popover (or use the ⋯ menu) for a resizable dashboard: a filter field, richer rows with the server's working directory, and always-visible actions instead of hover-to-reveal.

### Boring, safe permissions

Everything is `lsof`, `ps`, Unix signals, and a plain TCP listener. No kernel extensions, no Accessibility access, no accounts. macOS may prompt once for **Local Network** access the first time you share a server to your phone — that's the relay's listening socket, nothing more.

---

## Installation

> [!IMPORTANT]
> Portside is not yet notarized by Apple (that requires a paid developer account), so macOS will warn you on first open. The steps below get you through it — or skip the download entirely and [build from source](#build-from-source) in under a minute.

### Install with Homebrew

```bash
brew install --cask aadhilfarhan/tap/portside
```

One command, and Homebrew verifies the download's checksum for you automatically. Step 3 below (allowing the app to open) still applies on first open. Updating later is `brew upgrade --cask portside`.

The steps below cover the direct download instead.

### Step 1: Download

[Download Portside.dmg](https://github.com/AadhilFarhan/Portside/releases/latest/download/Portside.dmg) — this link always fetches the newest release. Release notes live on the [releases page](https://github.com/AadhilFarhan/Portside/releases).

### Step 2: Verify your download (optional but recommended)

Each release includes a `.dmg.sha256` checksum file ([download it here](https://github.com/AadhilFarhan/Portside/releases/latest/download/Portside.dmg.sha256)). With both files in the same folder:

```bash
cd ~/Downloads
shasum -a 256 -c Portside.dmg.sha256
```

A result ending in `OK` means your download is byte-for-byte the published release.

### Step 3: Install and open

Open the `.dmg` and drag Portside to your Applications folder. Because the app isn't notarized, double-clicking will show a warning:

1. Double-click Portside, and dismiss the warning
2. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the Portside message
3. Confirm in the dialog that appears

You only do this once. The Portside icon appears in your menu bar — click it to see your first dev server.

---

## Updating

Portside checks nothing and phones home to nothing, so updates are manual: download the new `.dmg` from the [releases page](https://github.com/AadhilFarhan/Portside/releases) and drag-replace the app, or `brew upgrade --cask portside`.

---

## Build from source

No Xcode required — just the Command Line Tools.

```bash
git clone https://github.com/AadhilFarhan/Portside.git
cd Portside
./scripts/build-app.sh
open dist/Portside.app
```

The script builds the SwiftPM package in release mode and assembles `dist/Portside.app`. Building locally also skips the Gatekeeper "Open Anyway" dance, since the binary is built on your own machine.

To regenerate the app icon:

```bash
swift scripts/generate-icon.swift
```

Running the test suite needs the full Xcode toolchain (XCTest isn't in the bare Command Line Tools):

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

---

## Headless mode

The same binary doubles as a CLI, useful for scripting or for checking the engine without the UI:

```bash
Portside.app/Contents/MacOS/Portside --scan       # print the server table
Portside.app/Contents/MacOS/Portside --share 3000 # relay a port to your LAN, print the URL
```

---

## How sharing works

Your phone can't reach `127.0.0.1:3000` on your Mac, and most dev servers bind only to loopback. Portside starts a tiny relay that listens on your LAN address and pipes bytes to the loopback port — a dumb, fast TCP pipe, so HTTP, WebSockets, and streaming all just work.

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple silicon (the released build is arm64-only)

---

## Privacy

Portside has no networking code beyond the local relay it starts on request, and it contains no analytics, telemetry, or update pings. Port and process information comes from standard Unix tools (`lsof`, `ps`) running locally; nothing leaves your Mac except the traffic you explicitly choose to share to your own phone over your own Wi-Fi.

---

## Roadmap

- **Trusted HTTPS to your phone** — a locally-generated CA (the mkcert approach) with a guided install-profile flow for iOS/Android, so camera, clipboard, and PWA APIs that require a secure context work on device.
- New-server notifications, port history, favorites.

---

## License

Portside is released under the [MIT License](LICENSE). You are free to use, read, modify, and distribute it.

---

<div align="center">

**Aadhil Farhan**

<a href="https://github.com/AadhilFarhan"><img src="https://img.shields.io/badge/GitHub-AadhilFarhan-black?style=flat&logo=github&logoColor=white" alt="GitHub" /></a>

</div>
