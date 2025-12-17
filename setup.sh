#!/bin/bash
#
# ImmortalWrt Setup Script
# This script handles:
# - Cloning immortalwrt repository with optional proxy
# - Adding custom feeds from feeds.custom.conf
# - Installing uci-defaults initialization script
#

set -e

# Default values
BRANCH="openwrt-24.10"
PROXY_PREFIX=""
WORK_DIR="/home/shaw"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Configuration file paths
FEEDS_CUSTOM_CONF="${SCRIPT_DIR}/conf/feeds.custom.conf"
INITIAL_SCRIPT="${SCRIPT_DIR}/conf/initial_script.sh"

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -b, --branch <branch>       ImmortalWrt branch to clone (default: openwrt-24.10)
    -p, --proxy <prefix>        GitHub proxy prefix (e.g., https://ghfast.top)
                                If not set, direct GitHub access will be used
    -w, --workdir <path>        Working directory (default: /home/shaw)
    -h, --help                  Show this help message

Examples:
    $(basename "$0") -b openwrt-24.10 -p https://ghfast.top
    $(basename "$0") --branch openwrt-23.05
    $(basename "$0")  # Use defaults without proxy
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -p|--proxy)
            PROXY_PREFIX="$2"
            shift 2
            ;;
        -w|--workdir)
            WORK_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Function to apply proxy prefix to GitHub URLs
apply_proxy() {
    local url="$1"
    if [[ -n "$PROXY_PREFIX" ]]; then
        # Remove trailing slash from proxy prefix if present
        PROXY_PREFIX="${PROXY_PREFIX%/}"
        # Add proxy prefix to GitHub URLs
        echo "${url/https:\/\/github.com/${PROXY_PREFIX}\/https:\/\/github.com}"
    else
        echo "$url"
    fi
}

# Function to clone immortalwrt repository
clone_immortalwrt() {
    echo "==> Cloning ImmortalWrt (branch: ${BRANCH})..."
    
    local repo_url="https://github.com/immortalwrt/immortalwrt"
    repo_url=$(apply_proxy "$repo_url")
    
    cd "$WORK_DIR"
    git clone -b "$BRANCH" --single-branch --filter=blob:none "$repo_url"
    
    echo "==> Clone completed."
}

# Function to add custom feeds
add_custom_feeds() {
    echo "==> Adding custom feeds..."
    
    local immortalwrt_dir="${WORK_DIR}/immortalwrt"
    local feeds_conf="${immortalwrt_dir}/feeds.conf.default"
    
    if [[ ! -f "$FEEDS_CUSTOM_CONF" ]]; then
        echo "Warning: Custom feeds config not found: ${FEEDS_CUSTOM_CONF}"
        return 0
    fi
    
    # Read custom feeds and append to feeds.conf.default
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Apply proxy to the feed URL if needed
        if [[ -n "$PROXY_PREFIX" ]]; then
            line=$(echo "$line" | sed "s|https://github.com|${PROXY_PREFIX}/https://github.com|g")
        fi
        
        echo "$line" >> "$feeds_conf"
        echo "    Added: $line"
    done < "$FEEDS_CUSTOM_CONF"
    
    echo "==> Custom feeds added."
}

# Function to update and install feeds
update_feeds() {
    echo "==> Updating and installing feeds..."
    
    local immortalwrt_dir="${WORK_DIR}/immortalwrt"
    cd "$immortalwrt_dir"
    
    # Apply proxy to GitHub URLs that don't already have proxy prefix
    if [[ -n "$PROXY_PREFIX" ]]; then
        # Only replace URLs that don't already have the proxy prefix
        sed -i "s|https://github.com|${PROXY_PREFIX}/https://github.com|g" feeds.conf.default
        # Fix any double proxy prefix that might have been added
        sed -i "s|${PROXY_PREFIX}/${PROXY_PREFIX}/|${PROXY_PREFIX}/|g" feeds.conf.default
    fi
    
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    echo "==> Feeds updated and installed."
}

# Function to install uci-defaults script
install_uci_defaults() {
    echo "==> Installing uci-defaults initialization script..."
    
    local immortalwrt_dir="${WORK_DIR}/immortalwrt"
    local uci_defaults_dir="${immortalwrt_dir}/package/base-files/files/etc/uci-defaults"
    local target_script="${uci_defaults_dir}/99-custom"
    
    if [[ ! -f "$INITIAL_SCRIPT" ]]; then
        echo "Warning: Initial script not found: ${INITIAL_SCRIPT}"
        return 0
    fi
    
    # Create directory if not exists
    mkdir -p "$uci_defaults_dir"
    
    # Copy the initialization script
    cp "$INITIAL_SCRIPT" "$target_script"
    chmod +x "$target_script"
    
    echo "==> uci-defaults script installed to: ${target_script}"
}

# Main execution
main() {
    echo "========================================"
    echo "ImmortalWrt Setup Script"
    echo "========================================"
    echo "Branch:     ${BRANCH}"
    echo "Proxy:      ${PROXY_PREFIX:-None}"
    echo "Work Dir:   ${WORK_DIR}"
    echo "========================================"
    
    clone_immortalwrt
    add_custom_feeds
    update_feeds
    install_uci_defaults
    
    echo "========================================"
    echo "Setup completed successfully!"
    echo "========================================"
}

main
