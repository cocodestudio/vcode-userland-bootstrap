#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ARCH="$1"
if [ -z "$ARCH" ]; then
    echo "Usage: $0 <aarch64|arm|x86_64|i686>"
    exit 1
fi

case "$ARCH" in
    aarch64)
        ALPINE_ARCH="aarch64"
        ;;
    arm)
        ALPINE_ARCH="armv7"
        ;;
    x86_64)
        ALPINE_ARCH="x86_64"
        ;;
    i686)
        ALPINE_ARCH="x86"
        ;;
    *)
        echo "Error: Unknown architecture '$ARCH'. Supported: aarch64, arm, x86_64, i686"
        exit 1
        ;;
esac

ALPINE_VERSION="3.20"
ALPINE_RELEASE="3.20.3"
TARBALL_NAME="alpine-minirootfs-${ALPINE_RELEASE}-${ALPINE_ARCH}.tar.gz"
DOWNLOAD_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${TARBALL_NAME}"

echo "=========================================================="
echo " Building VCode PRoot Linux Userland Bootstrap Archive"
echo " Architecture:      $ARCH (Alpine: $ALPINE_ARCH)"
echo " Base Distribution: Alpine Linux v${ALPINE_RELEASE} (musl)"
echo " Target Package ID: com.cocode.vcode.ide"
echo "=========================================================="

BUILD_DIR=$(mktemp -d "/tmp/vcode-bootstrap-${ARCH}-XXXXXX")
ROOTFS_DIR="$BUILD_DIR/rootfs"
OUTPUT_DIR="$REPO_ROOT/output"

mkdir -p "$ROOTFS_DIR"
mkdir -p "$OUTPUT_DIR"

# Download official Alpine Linux minirootfs
echo "[*] Downloading official Alpine minirootfs..."
curl -fsSL "$DOWNLOAD_URL" -o "$BUILD_DIR/$TARBALL_NAME"

echo "[*] Extracting minirootfs..."
tar -xzf "$BUILD_DIR/$TARBALL_NAME" -C "$ROOTFS_DIR"

echo "[*] Configuring rootless container environment..."

# 1. DNS Resolution (/etc/resolv.conf & /etc/hosts)
cat << 'EOF' > "$ROOTFS_DIR/etc/resolv.conf"
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

cat << 'EOF' > "$ROOTFS_DIR/etc/hosts"
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
EOF

# 2. Package Repositories (/etc/apk/repositories)
cat << EOF > "$ROOTFS_DIR/etc/apk/repositories"
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community
EOF

# 3. Environment Profile (/etc/profile & /etc/profile.d/vcode.sh)
mkdir -p "$ROOTFS_DIR/etc/profile.d"
cat << 'EOF' > "$ROOTFS_DIR/etc/profile.d/vcode.sh"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export TERM="xterm-256color"
export LANG="en_US.UTF-8"
export HOME="/root"
export TMPDIR="/tmp"

# Terminal Prompt
PS1='\[\033[01;32m\]${VCODE_PROJECT_NAME:-vcode}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

alias ls='ls --color=auto 2>/dev/null || ls'
alias ll='ls -lah 2>/dev/null || ls -l'
alias grep='grep --color=auto 2>/dev/null || grep'
EOF

# 4. Standard VCode Package Manager wrapper (/bin/pkg)
cat << 'EOF' > "$ROOTFS_DIR/bin/pkg"
#!/bin/sh
# VCode Desktop Package Manager (pkg) - Delegator to apk

case "$1" in
  bootstrap)
    echo "Desktop terminal environment is already installed and active."
    exit 0
    ;;
  install|add|i)
    shift
    exec apk add "$@"
    ;;
  uninstall|remove|rm|del)
    shift
    exec apk del "$@"
    ;;
  update|up)
    shift
    exec apk update "$@"
    ;;
  upgrade)
    shift
    exec apk upgrade "$@"
    ;;
  list|list-installed|ls)
    exec apk list -I
    ;;
  search|s)
    shift
    exec apk search "$@"
    ;;
  help|--help|-h|*)
    echo "VCode Desktop Package Manager (pkg)"
    echo "Usage: pkg <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  install <pkg>     Install one or more packages (e.g. pkg install git nodejs python3)"
    echo "  uninstall <pkg>   Remove one or more packages"
    echo "  update            Update package index mirrors"
    echo "  upgrade           Upgrade installed packages"
    echo "  list              List installed packages"
    echo "  search <query>    Search available packages"
    echo "  help              Show this help message"
    echo ""
    echo "Note: You can also use 'apk add <pkg>' or 'apk search <query>' directly."
    exit 0
    ;;
esac
EOF
chmod 755 "$ROOTFS_DIR/bin/pkg"

# 5. Required standard mount points and directories
mkdir -p "$ROOTFS_DIR/workspace"
mkdir -p "$ROOTFS_DIR/root"
mkdir -p "$ROOTFS_DIR/dev"
mkdir -p "$ROOTFS_DIR/proc"
mkdir -p "$ROOTFS_DIR/sys"
mkdir -p "$ROOTFS_DIR/tmp"
chmod 1777 "$ROOTFS_DIR/tmp"

# 6. Mark installation
touch "$ROOTFS_DIR/.installed"

echo "[*] Packaging bootstrap-${ARCH}.tar.gz..."
tar -czf "$OUTPUT_DIR/bootstrap-${ARCH}.tar.gz" -C "$ROOTFS_DIR" .

echo "[*] Generating SHA-256 checksum..."
cd "$OUTPUT_DIR"
sha256sum "bootstrap-${ARCH}.tar.gz" > "bootstrap-${ARCH}.tar.gz.sha256"

# Create a zip archive for compatibility
echo "[*] Generating zip archive..."
zip -q -r "bootstrap-${ARCH}.zip" "bootstrap-${ARCH}.tar.gz" "bootstrap-${ARCH}.tar.gz.sha256"

# Cleanup staging
rm -rf "$BUILD_DIR"

echo "=========================================================="
echo " Build successful for $ARCH!"
echo " Output files:"
ls -lh "$OUTPUT_DIR/bootstrap-${ARCH}"*
echo "=========================================================="
