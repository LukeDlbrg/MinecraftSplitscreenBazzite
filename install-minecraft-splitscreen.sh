#!/bin/bash
# =============================================================================
# Minecraft Splitscreen Bazzite & Handheld Installer - MODULAR VERSION
# =============================================================================
# 
# This is the modular entry point for the Minecraft Splitscreen installer.
# All functionality has been moved to organized modules for better maintainability.
# Required modules are automatically downloaded as temporary files when the script runs.
#
# Features:
# - Automatic temporary module downloading (modules are cleaned up after completion)
# - Automatic Java detection and installation
# - Complete Fabric dependency chain implementation
# - API filtering for Fabric-compatible mods (Modrinth + CurseForge)
# - Enhanced error handling with multiple fallback mechanisms
# - User-friendly mod selection interface
# - Bazzite and handheld optimized installation
# - Prism Launcher support (AppImage or Flatpak)
# - Comprehensive Steam and desktop integration (optional)
#
# No additional setup, Java installation, token files, or module downloads required - just run this script.
# Modules are downloaded temporarily and automatically cleaned up when the script completes.
#
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Runtime flags
DEBUG_MODE=false
LAUNCHER_TYPE="auto"

# Parse installer flags early so startup/module logs can respect debug mode.
declare -a FORWARDED_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --debug)
            DEBUG_MODE=true
            ;;
        --launcher)
            # Next argument should be the launcher type
            ;;
        flatpak|appimage|auto)
            LAUNCHER_TYPE="$arg"
            ;;
        *)
            FORWARDED_ARGS+=("$arg")
            ;;
    esac
done
set -- "${FORWARDED_ARGS[@]}"

# =============================================================================
# CLEANUP AND SIGNAL HANDLING
# =============================================================================

# Global variable for modules directory (will be set later)
MODULES_DIR=""

# Cleanup function to remove temporary modules directory
cleanup() {
    if [[ -n "$MODULES_DIR" ]] && [[ -d "$MODULES_DIR" ]]; then
        echo "🧹 Cleaning up temporary modules..."
        rm -rf "$MODULES_DIR"
    fi
}

# Set up trap to cleanup on script exit (normal or error)
trap cleanup EXIT INT TERM

# =============================================================================
# MODULE DOWNLOADING AND LOADING
# =============================================================================

# Get the directory where this script is located
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Create a temporary directory for modules that will be cleaned up automatically
MODULES_DIR="$(mktemp -d -t minecraft-modules-XXXXXX)"

# GitHub repository information (modify these URLs to match your actual repository)
readonly REPO_BASE_URL="https://raw.githubusercontent.com/LukeDlbrg/MinecraftSplitscreenBazzite/main/modules"

# =============================================================================
# LAUNCHER TYPE DETECTION AND CONFIGURATION
# =============================================================================

# detect_prism_launcher: Detects if Prism Launcher is installed (Flatpak or AppImage)
# Sets global variables: LAUNCHER_TYPE, LAUNCHER_EXEC, TARGET_DIR
detect_prism_launcher() {
    # Check for Flatpak installation
    if command -v flatpak >/dev/null 2>&1; then
        if flatpak list | grep -q "org.prismlauncher.PrismLauncher"; then
            LAUNCHER_TYPE="prism-flatpak"
            LAUNCHER_EXEC="flatpak run org.prismlauncher.PrismLauncher"
            TARGET_DIR="$HOME/.var/app/org.prismlauncher.PrismLauncher/config/prismlauncher"
            print_success "Detected Prism Launcher (Flatpak) at $TARGET_DIR"
            return 0
        fi
    fi

    # Check for AppImage installation
    local appimage_path="$HOME/.local/share/PrismLauncher/PrismLauncher.AppImage"
    if [[ -f "$appimage_path" ]] && [[ -x "$appimage_path" ]]; then
        LAUNCHER_TYPE="prism-appimage"
        LAUNCHER_EXEC="$appimage_path"
        TARGET_DIR="$HOME/.local/share/PrismLauncher"
        print_success "Detected Prism Launcher (AppImage) at $TARGET_DIR"
        return 0
    fi

    # Not found
    return 1
}

# select_launcher_type: Allows user to select launcher installation type
select_launcher_type() {
    echo ""
    print_header "🎮 PRISM LAUNCHER SELECTION"
    print_info "Prism Launcher is required for Minecraft Splitscreen."
    print_info "You can use an existing installation or have the installer set one up."
    echo ""

    if detect_prism_launcher; then
        print_info "Using detected Prism Launcher installation (type: $LAUNCHER_TYPE)"
        echo ""
        read -p "Use detected installation? [Y/n]: " use_detected
        if [[ "$use_detected" =~ ^[Nn]$ ]]; then
            # User wants to choose differently
            LAUNCHER_TYPE=""
        else
            return 0
        fi
    fi

    echo ""
    print_info "Select Prism Launcher installation type:"
    echo "  1) Flatpak (recommended for Bazzite) - will be installed automatically if missing"
    echo "  2) AppImage - will be downloaded and installed locally"
    echo ""

    local choice=""
    while [[ -z "$choice" ]]; do
        read -p "Select option [1-2, default=1]: " choice
        case "$choice" in
            1|""|flatpak)
                LAUNCHER_TYPE="prism-flatpak"
                ;;
            2|appimage)
                LAUNCHER_TYPE="prism-appimage"
                ;;
            *)
                echo "Invalid option. Please select 1 or 2."
                choice=""
                ;;
        esac
    done

    return 0
}

# setup_prism_launcher: Ensures Prism Launcher is installed based on LAUNCHER_TYPE
setup_prism_launcher() {
    case "$LAUNCHER_TYPE" in
        prism-flatpak)
            setup_prism_flatpak
            ;;
        prism-appimage)
            setup_prism_appimage
            ;;
        auto)
            if ! detect_prism_launcher; then
                print_info "No Prism Launcher detected. Selecting installation type..."
                select_launcher_type
                setup_prism_launcher
            fi
            ;;
    esac
}

# setup_prism_flatpak: Install Prism Launcher via Flatpak
setup_prism_flatpak() {
    print_progress "Setting up Prism Launcher via Flatpak..."

    # Check if flatpak is available
    if ! command -v flatpak >/dev/null 2>&1; then
        print_error "Flatpak is not installed. Cannot install Prism Launcher via Flatpak."
        print_info "Please install flatpak first or choose AppImage installation."
        exit 1
    fi

    # Add Flathub repository if not already added
    if ! flatpak remotes | grep -q "flathub"; then
        print_progress "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    # Install Prism Launcher if not already installed
    if ! flatpak list | grep -q "org.prismlauncher.PrismLauncher"; then
        print_progress "Installing Prism Launcher from Flathub..."
        flatpak install flathub org.prismlauncher.PrismLauncher -y --noninteractive
    fi

    # Set paths for Flatpak installation
    LAUNCHER_EXEC="flatpak run org.prismlauncher.PrismLauncher"
    TARGET_DIR="$HOME/.var/app/org.prismlauncher.PrismLauncher/config/prismlauncher"
    print_success "Prism Launcher (Flatpak) is ready at $TARGET_DIR"
}

# setup_prism_appimage: Download and setup Prism Launcher AppImage
setup_prism_appimage() {
    print_progress "Setting up Prism Launcher via AppImage..."

    # Create target directory
    mkdir -p "$HOME/.local/share/PrismLauncher"
    TARGET_DIR="$HOME/.local/share/PrismLauncher"

    # Download latest Prism Launcher AppImage
    local prism_url
    prism_url=$(curl -s https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest | \
        jq -r '.assets[] | select(.name | ascii_downcase | (contains("appimage") and (contains("x86_64") or contains("amd64")))) | .browser_download_url' | \
        head -n1)

    if [[ -z "$prism_url" || "$prism_url" == "null" ]]; then
        print_error "Could not find latest Prism Launcher AppImage URL."
        print_error "Please check https://github.com/PrismLauncher/PrismLauncher/releases manually."
        exit 1
    fi

    print_progress "Downloading Prism Launcher AppImage..."
    local appimage_path="$TARGET_DIR/PrismLauncher.AppImage"
    if command -v wget >/dev/null 2>&1; then
        wget -O "$appimage_path" "$prism_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$appimage_path" "$prism_url"
    else
        print_error "Neither wget nor curl is available to download Prism Launcher."
        exit 1
    fi

    chmod +x "$appimage_path"
    LAUNCHER_EXEC="$appimage_path"
    print_success "Prism Launcher (AppImage) downloaded to $appimage_path"
}

# List of required module files
readonly MODULE_FILES=(
    "utilities.sh"
    "java_management.sh"
    "launcher_setup.sh"
    "version_management.sh"
    "lwjgl_management.sh"
    "mod_management.sh"
    "instance_creation.sh"
    "steam_integration.sh"
    "desktop_launcher.sh"
    "main_workflow.sh"
)

# Function to download modules if they don't exist
download_modules() {
    echo "🔄 Downloading required modules to temporary directory..."
    if [[ "$DEBUG_MODE" == true ]]; then
        echo "📁 Temporary modules directory: $MODULES_DIR"
        echo "🌐 Repository URL: $REPO_BASE_URL"
    fi
    
    # Temporarily disable strict error handling for downloads
    set +e
    
    # The temporary directory is already created by mktemp
    local downloaded_count=0
    local failed_count=0
    
    # Download each required module
    for module in "${MODULE_FILES[@]}"; do
        local module_path="$MODULES_DIR/$module"
        local module_url="$REPO_BASE_URL/$module"
        
        if [[ "$DEBUG_MODE" == true ]]; then
            echo "⬇️  Downloading module: $module"
            echo "    URL: $module_url"
        fi
        
        # Download the module file
        if command -v curl >/dev/null 2>&1; then
            curl_output=$(curl -fsSL "$module_url" -o "$module_path" 2>&1)
            curl_exit_code=$?
            if [[ $curl_exit_code -eq 0 ]]; then
                chmod +x "$module_path"
                ((downloaded_count++))
                if [[ "$DEBUG_MODE" == true ]]; then
                    echo "✅ Downloaded: $module"
                fi
            else
                echo "❌ Failed to download: $module"
                echo "    Curl exit code: $curl_exit_code"
                echo "    Error: $curl_output"
                ((failed_count++))
            fi
        elif command -v wget >/dev/null 2>&1; then
            wget_output=$(wget -q "$module_url" -O "$module_path" 2>&1)
            wget_exit_code=$?
            if [[ $wget_exit_code -eq 0 ]]; then
                chmod +x "$module_path"
                ((downloaded_count++))
                if [[ "$DEBUG_MODE" == true ]]; then
                    echo "✅ Downloaded: $module"
                fi
            else
                echo "❌ Failed to download: $module"
                echo "    Wget exit code: $wget_exit_code"
                echo "    Error: $wget_output"
                ((failed_count++))
            fi
        else
            echo "❌ Error: Neither curl nor wget is available"
            echo "Please install curl or wget to download modules automatically"
            echo "Or manually download all modules from: $REPO_BASE_URL"
            # Re-enable strict error handling before exiting
            set -euo pipefail
            exit 1
        fi
    done
    
    # Re-enable strict error handling
    set -euo pipefail
    
    if [[ $failed_count -gt 0 ]]; then
        echo "❌ Failed to download $failed_count module(s)"
        echo "ℹ️  This might be because:"
        echo "    - The repository doesn't exist or is private"
        echo "    - The modules haven't been uploaded to the repository yet"
        echo "    - Network connectivity issues"
        echo ""
        echo "🔧 For now, you can place the modules manually in the same directory as this script:"
        echo "    mkdir -p '$SCRIPT_DIR/modules'"
        echo "    # Then copy all .sh module files to that directory"
        echo ""
        echo "🌐 Or check if the repository exists at: https://github.com/LukeDlbrg/MinecraftSplitscreenBazzite"
        exit 1
    fi
    
    echo "✅ Downloaded $downloaded_count module(s) to temporary directory"
    echo "ℹ️  Modules will be automatically cleaned up when script completes"
}

# Download modules if needed
# First check if modules exist locally, if not try to download them
if [[ -d "$SCRIPT_DIR/modules" ]]; then
    if [[ "$DEBUG_MODE" == true ]]; then
        echo "📁 Found local modules directory, copying to temporary location..."
    fi
    cp -r "$SCRIPT_DIR/modules/"* "$MODULES_DIR/"
    chmod +x "$MODULES_DIR"/*.sh
    if [[ "$DEBUG_MODE" == true ]]; then
        echo "✅ Copied local modules to temporary directory"
    fi
else
    download_modules
fi

# Verify all modules are now present
for module in "${MODULE_FILES[@]}"; do
    if [[ ! -f "$MODULES_DIR/$module" ]]; then
        echo "❌ Error: Required module missing: $module"
        echo "Please check your internet connection or download manually from:"
        echo "$REPO_BASE_URL/$module"
        exit 1
    fi
done

# Source all module files to load their functions
# Load modules in dependency order
source "$MODULES_DIR/utilities.sh"
source "$MODULES_DIR/java_management.sh"
source "$MODULES_DIR/launcher_setup.sh"
source "$MODULES_DIR/version_management.sh"
source "$MODULES_DIR/lwjgl_management.sh"
source "$MODULES_DIR/mod_management.sh"
source "$MODULES_DIR/instance_creation.sh"
source "$MODULES_DIR/steam_integration.sh"
source "$MODULES_DIR/desktop_launcher.sh"
source "$MODULES_DIR/main_workflow.sh"

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================

# Script configuration paths
# TARGET_DIR will be set by launcher detection/setup
TARGET_DIR=""

# Runtime variables (set during execution)
JAVA_PATH=""
MC_VERSION=""
FABRIC_VERSION=""
LWJGL_VERSION=""

# Mod configuration arrays
declare -a REQUIRED_SPLITSCREEN_MODS=("Controllable (Fabric)" "Splitscreen Support")
declare -a REQUIRED_SPLITSCREEN_IDS=("317269" "yJgqfSDR")

# Master list of all available mods with their metadata
# Format: "Mod Name|platform|mod_id"
declare -a MODS=(
    "Better Name Visibility|modrinth|pSfNeCCY"
    "Controllable (Fabric)|curseforge|317269"
    "Full Brightness Toggle|modrinth|aEK1KhsC"
    "In-Game Account Switcher|modrinth|cudtvDnd"
    "Just Zoom|modrinth|iAiqcykM"
    "Mod Menu|modrinth|mOgUt4GM"
    "Old Combat Mod|modrinth|dZ1APLkO"
    "Reese's Sodium Options|modrinth|Bh37bMuy"
    "Sodium|modrinth|AANobbMI"
    "Sodium Dynamic Lights|modrinth|PxQSWIcD"
    "Sodium Extra|modrinth|PtjYWJkn"
    "Sodium Extras|modrinth|vqqx0QiE"
    "Sodium Options API|modrinth|Es5v4eyq"
    "Splitscreen Support|modrinth|yJgqfSDR"
)

# Runtime mod tracking arrays (populated during execution)
declare -a SUPPORTED_MODS=()
declare -a MOD_DESCRIPTIONS=()
declare -a MOD_URLS=()
declare -a MOD_IDS=()
declare -a MOD_TYPES=()
declare -a MOD_DEPENDENCIES=()
declare -a FINAL_MOD_INDEXES=()
declare -a MISSING_MODS=()

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Setup Prism Launcher before running main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ -z "${TESTING_MODE:-}" ]]; then
    # Handle launcher type selection
    if [[ "$LAUNCHER_TYPE" == "auto" ]]; then
        if ! detect_prism_launcher; then
            select_launcher_type
        fi
    fi
    
    setup_prism_launcher
    
    # Ensure TARGET_DIR is set
    if [[ -z "$TARGET_DIR" ]]; then
        print_error "TARGET_DIR not set. Prism Launcher setup failed."
        exit 1
    fi
    
    # Execute main function
    main "$@"
fi

# =============================================================================
# END OF MODULAR MINECRAFT SPLITSCREEN INSTALLER
# =============================================================================
