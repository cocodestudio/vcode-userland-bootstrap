# VCode PRoot Userland Bootstrap Repository

[![Build VCode Bootstrap Archives](https://github.com/cocodestudio/vcode-userland-bootstrap/actions/workflows/build-bootstrap.yml/badge.svg)](https://github.com/cocodestudio/vcode-userland-bootstrap/actions/workflows/build-bootstrap.yml)

Official rootless Linux userland bootstrap builder and distribution repository for [VCode IDE](https://github.com/cocodestudio/VCode) (`com.cocode.vcode.ide`) on Android.

---

## Architecture Overview

VCode's Desktop Terminal environment runs a rootless Linux container powered by **PRoot** (`libproot.so`) directly on Android (minSdk 24 through targetSdk 36+), fully compliant with Android 10+ W^X SELinux security policies:

```
/data/data/com.cocode.vcode.ide/files/
└── usr/                               <-- Container Rootfs ($PREFIX)
    ├── bin/                           <-- Shell & System Tools (sh, bash, pkg)
    ├── sbin/                          <-- Package manager (apk)
    ├── lib/                           <-- System musl/libc libraries
    ├── etc/                           <-- resolv.conf, hosts, apk repositories, profile
    ├── tmp/                           <-- /tmp
    └── workspace/                     <-- Bound to active project workspace
```

### Why PRoot + Alpine Linux?
1. **SELinux & W^X Compliance:** PRoot's native binary lives in `nativeLibraryDir` (`app_lib_file`), satisfying Android kernel execution policies. PRoot intercepts system calls via `ptrace`, running guest Linux binaries safely in user-space.
2. **Ultra-Lightweight Downloads:** Standard Alpine Linux minirootfs is only **~3.5 MB** compressed, saving bandwidth and installing in seconds.
3. **Authentic Global Packages:** Full access to Alpine's vast official package repositories via `pkg` / `apk` (`git`, `nodejs`, `npm`, `python3`, `gcc`, `curl`, `clang`, `rust`, etc.).
4. **No Custom Compilation Needed:** No need to maintain 50,000 custom build recipes; packages are pre-compiled and cryptographically signed upstream.

---

## Supported Architectures

| Architecture | Android ABI | Rootfs Base | Archive Name |
| :--- | :--- | :--- | :--- |
| **ARM 64-bit** | `arm64-v8a` (`aarch64`) | Alpine Linux `aarch64` | `bootstrap-aarch64.tar.gz` |
| **ARM 32-bit** | `armeabi-v7a` (`arm`) | Alpine Linux `armv7` | `bootstrap-arm.tar.gz` |
| **x86 64-bit** | `x86_64` | Alpine Linux `x86_64` | `bootstrap-x86_64.tar.gz` |
| **x86 32-bit** | `x86` (`i686`) | Alpine Linux `x86` | `bootstrap-i686.tar.gz` |

---

## Building Archives Locally

Run `scripts/build-bootstrap.sh` with the target architecture:

```bash
# Build for ARM 64-bit (most modern Android phones)
./scripts/build-bootstrap.sh aarch64

# Build for x86_64 (Android Studio emulators)
./scripts/build-bootstrap.sh x86_64
```

Generated tarballs and checksums will be saved in `output/`:
- `output/bootstrap-<arch>.tar.gz`
- `output/bootstrap-<arch>.tar.gz.sha256`
- `output/bootstrap-<arch>.zip`

---

## CI / CD & Releases

Archives are automatically built, validated with SHA-256 checksums, and attached to GitHub Releases via `.github/workflows/build-bootstrap.yml` on every version tag (`v*`) or manual `workflow_dispatch`.

---

## License

Licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
