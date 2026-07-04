#!/bin/bash
# =============================================================================
# LAUNCHER SETUP MODULE
# =============================================================================
# Prism Launcher setup functions
# Prism Launcher is used as the primary launcher for splitscreen gameplay
# Supports both AppImage and Flatpak installations

# download_prism_launcher: Download the latest Prism Launcher AppImage
# Only used for AppImage installations
download_prism_launcher() {
    # Skip download if AppImage already exists
    if [[ -f "$TARGET_DIR/PrismLauncher.AppImage" ]]; then
        print_success "Prism Launcher AppImage already present"
        return 0
    fi
    
    print_progress "Downloading latest Prism Launcher AppImage..."
    
    # Query GitHub API to get the latest release download URL
    # We specifically look for AppImage files in the release assets
    local prism_url
    prism_url=$(curl -s https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest | \
        jq -r '.assets[]
            | select(
                (.name | ascii_downcase | endswith("appimage"))
                and (
                    (.name | ascii_downcase | contains("x86_64"))
                    or (.name | ascii_downcase | contains("amd64"))
                )
            )
            | .browser_download_url' | \
        head -n1)
    
    # Validate that we got a valid download URL
    if [[ -z "$prism_url" || "$prism_url" == "null" ]]; then
        print_error "Could not find latest Prism Launcher AppImage URL."
        print_error "Please check https://github.com/PrismLauncher/PrismLauncher/releases manually."
        exit 1
    fi
    
    # Download and make executable
    if command -v wget >/dev/null 2>&1; then
        wget -O "$TARGET_DIR/PrismLauncher.AppImage" "$prism_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$TARGET_DIR/PrismLauncher.AppImage" "$prism_url"
    else
        print_error "Neither wget nor curl is available to download Prism Launcher."
        exit 1
    fi
    chmod +x "$TARGET_DIR/PrismLauncher.AppImage"
    print_success "Prism Launcher AppImage downloaded successfully"
}

# configure_prism_defaults: Write a baseline Prism Launcher config to avoid first-run setup prompts.
# Works for both AppImage and Flatpak installations
configure_prism_defaults() {
    print_progress "Configuring Prism Launcher defaults (Java + memory)..."

    local cfg_path="$TARGET_DIR/prismlauncher.cfg"
    local current_hostname
    if command -v hostname >/dev/null 2>&1; then
        current_hostname=$(hostname)
    elif [[ -n "${HOSTNAME:-}" ]]; then
        current_hostname="$HOSTNAME"
    else
        current_hostname="localhost"
    fi

    local java_cfg_path="${JAVA_PATH:-java}"
    
    # For Flatpak, we need to use the full path as Flatpak has its own Java
    if [[ "$LAUNCHER_TYPE" == "prism-flatpak" ]]; then
        # In Flatpak, Java is typically available in the sandbox
        java_cfg_path="java"
    fi
    
    cat > "$cfg_path" <<EOF
[General]
ApplicationTheme=system
ConfigVersion=1.2
IconTheme=pe_colored
JavaPath=${java_cfg_path}
Language=en_US
LastHostname=${current_hostname}
MaxMemAlloc=4096
MinMemAlloc=512
ToolbarsLocked=false
EOF

    print_success "Prism Launcher defaults written: $cfg_path"
    return 0
}

# setup_splitscreen_launcher_script: Install minecraftSplitscreen.sh into TARGET_DIR
# Prefer local repository copy when available, fall back to GitHub download.
# For Flatpak, the script needs to be placed in the Flatpak config directory
setup_splitscreen_launcher_script() {
    print_progress "Installing splitscreen launcher script..."

    local launcher_script="$TARGET_DIR/minecraftSplitscreen.sh"
    local local_script="${SCRIPT_DIR:-}/minecraftSplitscreen.sh"
    local remote_script="https://raw.githubusercontent.com/LukeDlbrg/MinecraftSplitscreenBazzite/main/minecraftSplitscreen.sh"

    # For Flatpak, ensure the target directory exists
    if [[ "$LAUNCHER_TYPE" == "prism-flatpak" ]]; then
        mkdir -p "$TARGET_DIR"
    fi

    if [[ -f "$local_script" ]]; then
        cp "$local_script" "$launcher_script"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL "$remote_script" -o "$launcher_script"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$launcher_script" "$remote_script"
    else
        print_error "Neither curl nor wget is available to fetch minecraftSplitscreen.sh"
        return 1
    fi

    chmod +x "$launcher_script"
    print_success "Splitscreen launcher script installed: $launcher_script"
    return 0
}
