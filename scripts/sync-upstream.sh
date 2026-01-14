#!/bin/bash
#
# sync-upstream.sh - Sync and compare with upstream homebrew-core formulas
#
# Usage:
#   ./scripts/sync-upstream.sh [formula_name]
#   ./scripts/sync-upstream.sh ola          # Check specific formula
#   ./scripts/sync-upstream.sh              # Check all tracked formulas
#
# Options:
#   --update    Update the stored upstream reference after viewing diff
#   --apply     Show a 3-way diff to help merge changes
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAP_DIR="$(dirname "$SCRIPT_DIR")"
UPSTREAM_DIR="$TAP_DIR/.upstream"
FORMULA_DIR="$TAP_DIR/Formula"
UPSTREAM_URL="https://raw.githubusercontent.com/Homebrew/homebrew-core/main/Formula"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [options] [formula_name]"
    echo ""
    echo "Options:"
    echo "  --update    Update stored upstream reference after viewing diff"
    echo "  --apply     Interactive mode: show changes and offer to update reference"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ola              # Check ola formula for upstream changes"
    echo "  $0 --update ola     # Check and update stored upstream reference"
    echo "  $0                  # Check all tracked formulas"
}

fetch_upstream() {
    local formula_name="$1"
    local first_letter="${formula_name:0:1}"
    local url="$UPSTREAM_URL/$first_letter/$formula_name.rb"

    curl -sL "$url"
}

check_formula() {
    local formula_name="$1"
    local do_update="$2"

    local upstream_file="$UPSTREAM_DIR/$formula_name.rb"
    local local_file="$FORMULA_DIR/$formula_name.rb"

    if [[ ! -f "$local_file" ]]; then
        echo -e "${RED}Error: Local formula not found: $local_file${NC}"
        return 1
    fi

    echo -e "${BLUE}=== Checking $formula_name ===${NC}"
    echo ""

    # Fetch latest upstream
    local temp_latest=$(mktemp)
    echo "Fetching latest upstream..."
    if ! fetch_upstream "$formula_name" > "$temp_latest"; then
        echo -e "${RED}Error: Failed to fetch upstream formula${NC}"
        rm -f "$temp_latest"
        return 1
    fi

    # Check if upstream file exists
    if [[ ! -f "$upstream_file" ]]; then
        echo -e "${YELLOW}No stored upstream reference found.${NC}"
        echo "Creating initial reference..."
        cp "$temp_latest" "$upstream_file"
        echo -e "${GREEN}Stored upstream reference created.${NC}"
    fi

    # Compare stored upstream vs latest upstream
    echo ""
    echo -e "${YELLOW}--- Upstream changes (stored vs latest) ---${NC}"
    if diff -q "$upstream_file" "$temp_latest" > /dev/null 2>&1; then
        echo -e "${GREEN}No upstream changes since last sync.${NC}"
    else
        echo -e "${RED}Upstream has changed!${NC}"
        echo ""
        diff --color=auto -u "$upstream_file" "$temp_latest" || true
        echo ""

        if [[ "$do_update" == "true" ]]; then
            echo -e "${YELLOW}Updating stored upstream reference...${NC}"
            cp "$temp_latest" "$upstream_file"
            echo -e "${GREEN}Updated.${NC}"
        else
            echo -e "${YELLOW}Run with --update to update the stored reference.${NC}"
        fi
    fi

    # Compare local vs stored upstream (our modifications)
    echo ""
    echo -e "${YELLOW}--- Your modifications (upstream vs local) ---${NC}"
    if diff -q "$upstream_file" "$local_file" > /dev/null 2>&1; then
        echo -e "${GREEN}No local modifications (identical to upstream).${NC}"
    else
        diff --color=auto -u "$upstream_file" "$local_file" || true
    fi

    rm -f "$temp_latest"
    echo ""
}

# Parse arguments
DO_UPDATE=false
FORMULA_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --update)
            DO_UPDATE=true
            shift
            ;;
        --apply)
            DO_UPDATE=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            FORMULA_NAME="$1"
            shift
            ;;
    esac
done

# Ensure directories exist
mkdir -p "$UPSTREAM_DIR"

if [[ -n "$FORMULA_NAME" ]]; then
    # Check specific formula
    check_formula "$FORMULA_NAME" "$DO_UPDATE"
else
    # Check all formulas that have upstream references
    if [[ -d "$UPSTREAM_DIR" ]] && [[ -n "$(ls -A "$UPSTREAM_DIR" 2>/dev/null)" ]]; then
        for upstream_file in "$UPSTREAM_DIR"/*.rb; do
            formula_name=$(basename "$upstream_file" .rb)
            check_formula "$formula_name" "$DO_UPDATE"
        done
    else
        echo "No upstream references found in $UPSTREAM_DIR"
        echo ""
        echo "To start tracking a formula, run:"
        echo "  $0 <formula_name>"
    fi
fi
