#!/usr/bin/env bash
# SoundCloud Downloader - Easy One-Line Installer
# Run with: bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh)

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}SoundCloud Downloader Installer${NC}"
    echo -e "${BLUE}===============================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_step() {
    echo ""
    echo -e "${PURPLE}$1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect Mac architecture
detect_arch() {
    if [[ $(uname -m) == "arm64" ]]; then
        echo "arm64"
    else
        echo "x86_64"
    fi
}

# Function to get the correct Homebrew path
get_brew_path() {
    local arch=$(detect_arch)
    if [[ "$arch" == "arm64" ]]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# Function to setup Homebrew environment
setup_brew_env() {
    local brew_path=$(get_brew_path)
    local brew_bin="$brew_path/bin/brew"

    if [[ -f "$brew_bin" ]]; then
        eval "$($brew_bin shellenv)"
        return 0
    fi
    return 1
}

# Function to get shell profiles for current user
get_shell_profiles() {
    local profiles=()

    # Always try to use the profile for the current shell first
    if [[ "$SHELL" == *"zsh"* ]]; then
        profiles+=("$HOME/.zshrc")
    elif [[ "$SHELL" == *"bash"* ]]; then
        profiles+=("$HOME/.bash_profile")
    fi

    # Also add the other common profile as backup
    if [[ "$SHELL" == *"zsh"* ]]; then
        profiles+=("$HOME/.bash_profile")
    else
        profiles+=("$HOME/.zshrc")
    fi

    printf '%s\n' "${profiles[@]}"
}

# Function to check if we can write to a file
can_write_to_file() {
    local file="$1"

    # If file doesn't exist, check if we can create it
    if [[ ! -f "$file" ]]; then
        if touch "$file" 2>/dev/null; then
            rm -f "$file"
            return 0
        else
            return 1
        fi
    fi

    # If file exists, check if we can write to it
    if [[ -w "$file" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to add line to shell profile if not present
add_to_profile() {
    local profile="$1"
    local line="$2"
    local comment="$3"

    # Check if we can write to this profile
    if ! can_write_to_file "$profile"; then
        print_warning "Cannot write to $profile (permission denied)"
        if [[ -f "$profile" ]]; then
            local owner=$(ls -l "$profile" | awk '{print $3}')
            if [[ "$owner" == "root" ]]; then
                print_info "File is owned by root. Suggesting manual fix..."
                echo -e "${YELLOW}Please run: ${GREEN}sudo chown $USER $profile${NC}"
                echo -e "${YELLOW}Then run the installer again${NC}"
                return 2
            fi
        fi
        return 1
    fi

    # Create profile if it doesn't exist
    if ! touch "$profile" 2>/dev/null; then
        print_warning "Cannot create or access $profile"
        return 1
    fi

    # Check if line already exists
    if ! grep -Fq "$line" "$profile" 2>/dev/null; then
        # Try to append the alias
        if {
            echo ""
            [[ -n "$comment" ]] && echo "# $comment"
            echo "$line"
        } >> "$profile" 2>/dev/null; then
            return 0  # Success
        else
            print_warning "Failed to write alias to $profile"
            return 1  # Failed to write
        fi
    else
        return 1  # Already exists, no change needed
    fi
}

# Function to remove lines from shell profile
remove_from_profile() {
    local profile="$1"
    local pattern="$2"

    if [[ -f "$profile" ]] && can_write_to_file "$profile"; then
        # Create backup
        cp "$profile" "${profile}.backup-$(date +%s)" 2>/dev/null || true
        # Remove lines matching pattern
        sed -i.bak "/$pattern/d" "$profile" 2>/dev/null || true
        rm -f "${profile}.bak" 2>/dev/null || true
    fi
}

# Uninstall function
uninstall_soundcloud() {
    print_header
    echo -e "${YELLOW}Uninstalling SoundCloud Downloader...${NC}"
    echo ""

    # Remove script
    if [[ -f "$HOME/Scripts/download-soundcloud.sh" ]]; then
        rm -f "$HOME/Scripts/download-soundcloud.sh"
        print_success "Removed download script"
    fi

    # Remove Scripts directory if empty
    if [[ -d "$HOME/Scripts" ]] && [[ -z "$(ls -A "$HOME/Scripts" 2>/dev/null)" ]]; then
        rmdir "$HOME/Scripts" 2>/dev/null && print_success "Removed empty Scripts directory"
    fi

    # Remove aliases from all shell profiles
    local profiles=()
    while IFS= read -r profile; do
        profiles+=("$profile")
    done < <(get_shell_profiles)

    for profile in "${profiles[@]}"; do
        if [[ -f "$profile" ]]; then
            remove_from_profile "$profile" "# SoundCloud Downloader"
            remove_from_profile "$profile" "alias soundcloud="
            print_success "Cleaned $(basename "$profile")"
        fi
    done

    # Ask about music directory
    echo ""
    print_warning "Your downloaded music is still in ~/Music/Soundcloud"
    echo -e "${BLUE}To remove it, run: ${GREEN}rm -rf ~/Music/Soundcloud${NC}"
    echo ""
    print_success "Uninstall complete! Please restart your terminal."
    exit 0
}

print_header

# Check for uninstall flag
if [[ "$1" == "uninstall" ]] || [[ "$1" == "--uninstall" ]]; then
    uninstall_soundcloud
fi

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This installer is designed for macOS only"
    print_info "You're running: $OSTYPE"
    print_info "For other systems, please install yt-dlp manually and use the script directly"
    exit 1
fi

# Detect Mac type
ARCH=$(detect_arch)
BREW_PATH=$(get_brew_path)

print_success "Running on macOS ($ARCH)"
print_info "Will use Homebrew path: $BREW_PATH"

# 1. Handle shell setup
print_step "Setting up shell configuration..."
CURRENT_SHELL=$(basename "$SHELL")
print_info "Current shell: $CURRENT_SHELL"

# Get all relevant shell profiles
SHELL_PROFILES=()
while IFS= read -r profile; do
    SHELL_PROFILES+=("$profile")
done < <(get_shell_profiles)

if [[ ${#SHELL_PROFILES[@]} -gt 0 ]]; then
    profile_names=""
    for profile in "${SHELL_PROFILES[@]}"; do
        profile_names+="$(basename "$profile"), "
    done
    profile_names="${profile_names%, }"
    print_success "Will configure profiles: $profile_names"
else
    print_warning "No shell profiles detected, will create default"
fi

# 2. Install/Setup Homebrew
print_step "Setting up Homebrew..."

# First, try to setup existing Homebrew
if setup_brew_env && command_exists brew; then
    print_success "Homebrew is already installed and configured"
    BREW_VERSION=$(brew --version | head -1)
    print_info "$BREW_VERSION"
else
    print_info "Installing Homebrew (this may take several minutes)..."
    print_warning "You may be asked for your password"
    print_info "The installation may appear to hang - this is normal!"

    # Install Homebrew
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        print_success "Homebrew installed successfully"

        # Setup environment
        if setup_brew_env; then
            print_success "Homebrew environment configured"
        else
            print_error "Could not configure Homebrew environment"
            print_info "Please run: eval \"\$(${BREW_PATH}/bin/brew shellenv)\""
            exit 1
        fi

        # Add to all shell profiles
        BREW_ENV_LINE="eval \"\$(${BREW_PATH}/bin/brew shellenv)\""
        for profile in "${SHELL_PROFILES[@]}"; do
            if add_to_profile "$profile" "$BREW_ENV_LINE" "Homebrew"; then
                print_success "Added Homebrew to $(basename "$profile")"
            fi
        done
    else
        print_error "Homebrew installation failed"
        print_info "Please visit https://brew.sh for manual installation"
        exit 1
    fi
fi

# Verify Homebrew is working
if ! command_exists brew; then
    print_error "Homebrew is not working properly"
    print_info "Try closing and reopening Terminal, then run this installer again"
    exit 1
fi

# 3. Install yt-dlp
print_step "Installing yt-dlp (the download engine)..."
if command_exists yt-dlp; then
    print_success "yt-dlp is already installed"
    print_info "Updating to latest version..."
    if brew upgrade yt-dlp 2>/dev/null; then
        print_success "yt-dlp updated"
    else
        print_info "Already up to date"
    fi
else
    print_info "Installing yt-dlp..."
    if brew install yt-dlp; then
        print_success "yt-dlp installed successfully"
    else
        print_error "Failed to install yt-dlp"
        print_info "Try running: brew install yt-dlp"
        exit 1
    fi
fi

# 4. Create Scripts directory and download the script
SCRIPT_DIR="$HOME/Scripts"
SCRIPT_NAME="download-soundcloud.sh"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
REPO_URL="https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main"

print_step "Setting up SoundCloud downloader script..."
mkdir -p "$SCRIPT_DIR"
print_success "Created Scripts directory: $SCRIPT_DIR"

print_info "Downloading latest script..."
if curl -fsSL "$REPO_URL/Scripts/$SCRIPT_NAME" -o "$SCRIPT_PATH"; then
    chmod +x "$SCRIPT_PATH"
    print_success "Script downloaded and made executable"
else
    print_error "Failed to download script"
    print_info "Check your internet connection and try again"
    print_info "Or manually download from: $REPO_URL/Scripts/$SCRIPT_NAME"
    exit 1
fi

# 5. Set up the alias in all shell profiles
print_step "Setting up 'soundcloud' command..."
ALIAS_LINE="alias soundcloud=\"$SCRIPT_PATH\""

# Track if we successfully added to any profile
successful_profiles=()
failed_profiles=()
permission_issues=false
primary_shell_success=false

for i in "${!SHELL_PROFILES[@]}"; do
    profile="${SHELL_PROFILES[$i]}"
    is_primary_shell=false

    # Check if this is the primary shell profile
    if [[ $i -eq 0 ]]; then
        is_primary_shell=true
    fi

    # Remove old aliases first
    remove_from_profile "$profile" "alias soundcloud="
    remove_from_profile "$profile" "# SoundCloud Downloader"

    # Add new alias
    add_to_profile "$profile" "$ALIAS_LINE" "SoundCloud Downloader"
    result=$?

    case $result in
        0)
            print_success "Added 'soundcloud' command to $(basename "$profile")"
            successful_profiles+=("$profile")
            if [[ "$is_primary_shell" == true ]]; then
                primary_shell_success=true
            fi
            ;;
        1)
            print_warning "Could not add to $(basename "$profile") (already exists or write failed)"
            ;;
        2)
            print_error "Permission denied for $(basename "$profile")"
            failed_profiles+=("$profile")
            permission_issues=true
            if [[ "$is_primary_shell" == true ]]; then
                print_error "CRITICAL: Cannot configure your primary shell profile!"
            fi
            ;;
    esac
done

# If we have permission issues, provide guidance
if [[ "$permission_issues" == true ]]; then
    echo ""
    if [[ "$primary_shell_success" == false ]]; then
        print_error "FAILED: Cannot configure your primary shell ($CURRENT_SHELL)"
        print_error "The 'soundcloud' command will NOT work until this is fixed"
    else
        print_warning "Some secondary shell profiles have permission issues"
    fi
    print_info "This is common when .zshrc is owned by root"
    echo ""
    print_info "To fix this, run these commands and then run the installer again:"
    for profile in "${failed_profiles[@]}"; do
        echo -e "  ${GREEN}sudo chown $USER $profile${NC}"
    done
    echo ""
    print_info "Or you can manually add this line to your shell profile:"
    echo -e "  ${GREEN}$ALIAS_LINE${NC}"
    echo ""
fi

# 6. Create Music directory
MUSIC_DIR="$HOME/Music/Soundcloud"
mkdir -p "$MUSIC_DIR"
print_success "Created music directory: $MUSIC_DIR"

# 7. Test the installation
print_step "Testing installation..."

if command_exists yt-dlp && [[ -x "$SCRIPT_PATH" ]]; then
    print_success "All components installed successfully!"

    # Test if alias works by checking if it can be found in a profile
    if [[ "$primary_shell_success" == true ]]; then
        print_success "Command 'soundcloud' is configured for your primary shell"
    elif [[ ${#successful_profiles[@]} -gt 0 ]]; then
        print_warning "Command configured for some shells, but NOT your primary shell ($CURRENT_SHELL)"
        print_warning "You may need to switch shells or fix permissions"
    else
        print_error "Command setup FAILED - manual configuration required"
    fi
else
    print_warning "Installation completed but some components need verification"
    print_info "Close and reopen Terminal, then try: soundcloud help"
fi

# Final success message
echo ""
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}======================${NC}"
echo ""
echo -e "${BLUE}Quick Start Guide:${NC}"
echo -e "${YELLOW}1.${NC} ${RED}Close this Terminal window and open a new one${NC}"
echo -e "${YELLOW}2.${NC} Type: ${GREEN}soundcloud help${NC}"
echo -e "${YELLOW}3.${NC} Try downloading: ${GREEN}soundcloud https://soundcloud.com/artist/song${NC}"
echo ""
echo -e "${BLUE}Your music will be saved to:${NC}"
echo -e "   ${GREEN}$MUSIC_DIR${NC}"
echo ""
echo -e "${BLUE}Example commands:${NC}"
echo -e "   ${GREEN}soundcloud help${NC}                              ${BLUE}# Show detailed help${NC}"
echo -e "   ${GREEN}soundcloud https://soundcloud.com/artist/song${NC}  ${BLUE}# Download a song${NC}"
echo -e "   ${GREEN}soundcloud https://soundcloud.com/user/sets/mix${NC} ${BLUE}# Download a playlist${NC}"
echo ""
echo -e "${BLUE}To uninstall later:${NC}"
echo -e "   ${GREEN}bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh) uninstall${NC}"
echo ""

# Show additional help if there were permission issues
if [[ "$permission_issues" == true ]]; then
    if [[ "$primary_shell_success" == false ]]; then
        echo -e "${RED}IMPORTANT: The soundcloud command will NOT work until you fix the permission issue${NC}"
        echo -e "${YELLOW}After fixing permissions, run this installer again${NC}"
    else
        echo -e "${YELLOW}NOTE: Some shell profiles need permission fixes${NC}"
        echo -e "${YELLOW}After fixing permissions, you can run this installer again${NC}"
    fi
    echo ""
fi

echo -e "${BLUE}Need help?${NC}"
echo -e "   • Make sure SoundCloud links are public"
echo -e "   • Use ${GREEN}soundcloud -v <link>${NC} for detailed output"
echo -e "   • Run ${GREEN}soundcloud --dry-run <link>${NC} to preview downloads"
echo ""
