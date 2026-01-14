#!/bin/bash
#
# update-ola.sh - Fetch upstream OLA formula and apply FTDI patch
#
set -e
cd "$(dirname "$0")/.."

UPSTREAM="https://raw.githubusercontent.com/Homebrew/homebrew-core/main/Formula/o/ola.rb"

case "${1:-update}" in
    --check)
        echo "Checking if patch applies to latest upstream..."
        tmp=$(mktemp)
        curl -sL "$UPSTREAM" > "$tmp"
        if patch --dry-run -f "$tmp" < patches/ola-ftdi-support.patch > /dev/null 2>&1; then
            echo "Patch applies cleanly."
        else
            echo "Patch has conflicts!"
            patch --dry-run -f "$tmp" < patches/ola-ftdi-support.patch || true
            rm "$tmp"
            exit 1
        fi
        rm "$tmp"
        ;;
    --regenerate)
        echo "Regenerating patch..."
        tmp=$(mktemp)
        curl -sL "$UPSTREAM" > "$tmp"
        (diff -u "$tmp" Formula/ola.rb | sed "1s|$tmp|a/Formula/ola.rb|") > patches/ola-ftdi-support.patch || true
        rm "$tmp"
        echo "Done."
        ;;
    update|"")
        echo "Fetching upstream..."
        curl -sL "$UPSTREAM" > Formula/ola.rb
        echo "Applying patch..."
        patch -f Formula/ola.rb < patches/ola-ftdi-support.patch
        echo "Done."
        ;;
    *)
        echo "Usage: $0 [--check|--regenerate]"
        ;;
esac
