#!/bin/bash
#
# ImmortalWrt Docker Entrypoint Script
# Supports various build actions and copies results to output volume
#

set -e

IMMORTALWRT_DIR="/home/shaw/immortalwrt"
OUTPUT_DIR="/home/shaw/output"

cd "$IMMORTALWRT_DIR"

# Function to copy .config to output
copy_config() {
    if [[ -f ".config" ]]; then
        cp .config "$OUTPUT_DIR/.config"
        echo "==> Copied .config to $OUTPUT_DIR/"
    fi
}

# Function to copy build artifacts to output
copy_build_artifacts() {
    if [[ -d "bin" ]]; then
        cp -r bin/* "$OUTPUT_DIR/"
        echo "==> Copied build artifacts to $OUTPUT_DIR/"
    fi
}

# Show usage information
usage() {
    cat << EOF
Usage: docker run <image> <action> [options]

Actions:
    menuconfig      Run make menuconfig (interactive)
    make            Build the firmware
    shell           Start an interactive shell

Examples:
    docker run -it -v ./output:/home/shaw/output shaw-wrt menuconfig
    docker run -v ./output:/home/shaw/output shaw-wrt make
    docker run -it -v ./output:/home/shaw/output shaw-wrt shell
EOF
    exit 0
}

# Main action handler
ACTION="${1:-shell}"

case "$ACTION" in
    menuconfig)
        echo "==> Running make menuconfig..."
        make menuconfig
        copy_config
        ;;
    make|build)
        echo "==> Building firmware..."
        make -j1 V=s
        copy_config
        copy_build_artifacts
        echo "==> Build completed."
        ;;
    shell|bash)
        echo "==> Starting interactive shell..."
        exec /bin/bash
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        echo "Unknown action: $ACTION"
        usage
        ;;
esac
