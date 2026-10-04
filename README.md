# VCode Userland Bootstrap Repository

[![Build VCode Bootstrap Archives](https://github.com/cocodestudio/vcode-userland-bootstrap/actions/workflows/build-bootstrap.yml/badge.svg)](https://github.com/cocodestudio/vcode-userland-bootstrap/actions/workflows/build-bootstrap.yml)

Official rootless Linux userland bootstrap builder and distribution repository for [VCode IDE](https://github.com/cocodestudio/VCode) (`com.cocode.vcode.ide`) on Android.

---

## Architecture Overview

VCode's Desktop Terminal environment runs a rootless Bionic Linux userland directly inside the application's private internal storage directory:

```
/data/data/com.cocode.vcode.ide/files/
└── usr/                               <-- $PREFIX
    ├── bin/                           <-- Executables (bash, pkg, python, git, node, curl)
    ├── lib/                           <-- Shared Libraries
    ├── etc/                           <-- bash.bashrc, apt, ssl certs
    ├── tmp/                           <-- $TMPDIR
    └── var/
        └── lib/dpkg/                  <-- Package status database
```

Because Android Bionic executables require the target internal storage path to be compiled into dynamic linker paths and shebangs, standard Termux packages (`/data/data/com.termux/`) cannot run directly without slow and fragile PRoot emulation. 

This repository compiles and packages native archives targeting `com.cocode.vcode.ide` with **100% native Bionic execution speed** and **zero APK bloat**.

---

## Supported Architectures

| Android ABI (`Build.SUPPORTED_ABIS`) | Architecture Name | Archive Name | Target Devices |
| :--- | :--- | :--- | :--- |
| `arm64-v8a` | **`aarch64`** | `bootstrap-aarch64.tar.gz` | Modern Android phones & tablets (~92%) |
| `armeabi-v7a` | **`arm`** | `bootstrap-arm.tar.gz` | 32-bit ARM phones & budget chipsets |
| `x86_64` | **`x86_64`** | `bootstrap-x86_64.tar.gz` | Android emulators, ChromeOS, Intel tablets |
| `x86` | **`i686`** | `bootstrap-i686.tar.gz` | 32-bit x86 Android emulators |

---

## Releases & Downloads

Pre-built bootstrap packages are available under [Releases](https://github.com/cocodestudio/vcode-userland-bootstrap/releases).

Every release includes:
- `bootstrap-<arch>.tar.gz`
- `bootstrap-<arch>.tar.gz.sha256`
- `SHA256SUMS.txt`

The VCode client automatically downloads the appropriate archive on-demand when the desktop terminal environment is activated.

---

## Triggering a New Build

To build new bootstrap archives:
1. Navigate to **Actions** -> **Build VCode Bootstrap Archives**.
2. Click **Run workflow**, specify the version tag (e.g. `v1.0.0`), and run.
3. Or push a Git tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. The workflow will automatically compile all 4 architectures, verify SHA-256 hashes, and publish the release.

---

## License

Licensed under Apache 2.0. Base Linux components are licensed under their respective open-source licenses (GPL, LGPL, MIT, BSD).
