#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/properties.sh"

ARCH="$1"
if [ -z "$ARCH" ]; then
    echo "Usage: $0 <aarch64|arm|x86_64|i686>"
    exit 1
fi

echo "=========================================================="
echo " Building VCode Bootstrap Archive"
echo " Architecture: $ARCH"
echo " Target Prefix: $TERMUX_PREFIX"
echo " Package ID:    $TERMUX_APP_PACKAGE"
echo "=========================================================="

OUTPUT_DIR="$REPO_ROOT/output"
BUILD_DIR="$REPO_ROOT/build/$ARCH"
PREFIX_DIR="$BUILD_DIR/usr"

mkdir -p "$OUTPUT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$PREFIX_DIR"/{bin,lib,etc/apt/sources.list.d,etc/profile.d,tmp,var/lib/dpkg/updates,var/lib/dpkg/info,var/log}

# 1. Setup base directory layout permissions
chmod 755 "$PREFIX_DIR"
chmod 755 "$PREFIX_DIR"/bin
chmod 755 "$PREFIX_DIR"/lib
chmod 755 "$PREFIX_DIR"/etc
chmod 1777 "$PREFIX_DIR"/tmp

# 2. Deploy default bash.bashrc
cat << 'EOF' > "$PREFIX_DIR/etc/bash.bashrc"
# VCode Rootless Linux Environment - System-wide configuration
if [ -z "$VCODE_SHELL_INIT" ]; then
    export VCODE_SHELL_INIT=1
    export PREFIX="/data/data/com.cocode.vcode.ide/files/usr"
    export PATH="$PREFIX/bin:/system/bin:/system/xbin"
    export LD_LIBRARY_PATH="$PREFIX/lib"
    export TMPDIR="$PREFIX/tmp"
    export TERM="xterm-256color"
    export LANG="en_US.UTF-8"
fi

# PS1 Prompt
if [ -n "$VCODE_PROJECT_NAME" ]; then
    PS1='\[\033[01;32m\]vcode@mobile\[\033[00m\]:\[\033[01;34m\][$VCODE_PROJECT_NAME \W]\[\033[00m\]\$ '
else
    PS1='\[\033[01;32m\]vcode@mobile\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'
EOF

# 3. Deploy pkg CLI helper script
cat << 'EOF' > "$PREFIX_DIR/bin/pkg"
#!/system/bin/sh
PREFIX="/data/data/com.cocode.vcode.ide/files/usr"
export PATH="$PREFIX/bin:/system/bin:/system/xbin"
export LD_LIBRARY_PATH="$PREFIX/lib"

ACTION="$1"
shift

case "$ACTION" in
    install|i)
        echo "VCode Package Manager (pkg): Installing $*..."
        ;;
    uninstall|remove|rm)
        echo "VCode Package Manager (pkg): Removing $*..."
        ;;
    list|ls)
        echo "Listing installed userland packages..."
        cat "$PREFIX/var/lib/dpkg/status" 2>/dev/null || echo "No packages installed."
        ;;
    search)
        echo "Searching package catalog for '$*'..."
        ;;
    help|--help|-h|*)
        echo "VCode Desktop Package Manager"
        echo "Usage: pkg <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  install <package>    Install a package (python, git, node, curl, clang, etc.)"
        echo "  uninstall <package>  Uninstall a package"
        echo "  list                 List installed packages"
        echo "  search <query>       Search for packages in repository"
        echo "  help                 Show this help message"
        ;;
esac
EOF
chmod 755 "$PREFIX_DIR/bin/pkg"

# 4. Initialize dpkg status file
cat << 'EOF' > "$PREFIX_DIR/var/lib/dpkg/status"
Package: base-files
Status: install ok installed
Priority: required
Section: admin
Installed-Size: 120
Maintainer: CoCode Studio <support@cocode.studio>
Architecture: all
Version: 1.0.0
Description: VCode rootless Linux userland base filesystem hierarchy

Package: bash
Status: install ok installed
Priority: required
Section: shells
Installed-Size: 3200
Maintainer: CoCode Studio <support@cocode.studio>
Architecture: all
Version: 5.2.21
Description: GNU Bourne Again SHell for VCode IDE
EOF

# 5. Pack into tar.gz
ARCHIVE_NAME="bootstrap-$ARCH.tar.gz"
echo "Creating $OUTPUT_DIR/$ARCHIVE_NAME..."
cd "$BUILD_DIR"
tar -czf "$OUTPUT_DIR/$ARCHIVE_NAME" usr/

# 6. Generate SHA-256
cd "$OUTPUT_DIR"
sha256sum "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"

echo "Build complete: $OUTPUT_DIR/$ARCHIVE_NAME"
cat "$ARCHIVE_NAME.sha256"
