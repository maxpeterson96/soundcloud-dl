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
    echo -e "${BLUE}🎵 SoundCloud Downloader Installer${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}💡 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step() {
    echo ""
    echo -e "${PURPLE}🔧 $1${NC}"
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

    # Check for zsh
    if [[ -f "$HOME/.zshrc" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        profiles+=("$HOME/.zshrc")
    fi

    # Check for bash
    if [[ -f "$HOME/.bash_profile" ]] || [[ "$SHELL" == *"bash"* ]]; then
        profiles+=("$HOME/.bash_profile")
    fi

    # If no profiles found, create based on current shell
    if [[ ${#profiles[@]} -eq 0 ]]; then
        if [[ "$SHELL" == *"zsh"* ]]; then
            profiles+=("$HOME/.zshrc")
        else
            profiles+=("$HOME/.bash_profile")
        fi
    fi

    printf '%s\n' "${profiles[@]}"
}

# Function to add line to shell profile if not present
add_to_profile() {
    local profile="$1"
    local line="$2"
    local comment="$3"

    # Create profile if it doesn't exist, handle permission issues
    if ! touch "$profile" 2>/dev/null; then
        print_warning "Cannot write to $profile (permission issue)"
        print_info "You may need to run: sudo chown $USER $profile"
        return 1
    fi

    # Check if line already exists
    if ! grep -Fq "$line" "$profile" 2>/dev/null; then
        if {
            echo "" >> "$profile"
            [[ -n "$comment" ]] && echo "# $comment" >> "$profile"
            echo "$line" >> "$profile"
        } 2>/dev/null; then
            return 0
        else
            print_warning "Cannot write to $profile (permission denied)"
            return 1
        fi
    fi
    return 1
}

# Function to remove lines from shell profile
remove_from_profile() {
    local profile="$1"
    local pattern="$2"

    if [[ -f "$profile" ]]; then
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
    echo -e "${YELLOW}🗑️  Uninstalling SoundCloud Downloader...${NC}"
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

for profile in "${SHELL_PROFILES[@]}"; do
    # Remove old aliases first
    remove_from_profile "$profile" "alias soundcloud="
    remove_from_profile "$profile" "# SoundCloud Downloader"

    # Add new alias
    if add_to_profile "$profile" "$ALIAS_LINE" "SoundCloud Downloader"; then
        print_success "Added 'soundcloud' command to $(basename "$profile")"
    else
        print_info "Updated 'soundcloud' command in $(basename "$profile")"
    fi
done

# 6. Create Music directory
MUSIC_DIR="$HOME/Music/Soundcloud"
mkdir -p "$MUSIC_DIR"
print_success "Created music directory: $MUSIC_DIR"

# 7. Test the installation
print_step "Testing installation..."

if command_exists yt-dlp && [[ -x "$SCRIPT_PATH" ]]; then
    print_success "All components installed successfully!"

    # Test if alias works by checking if it can be found in a profile
    alias_found=false
    for profile in "${SHELL_PROFILES[@]}"; do
        if [[ -f "$profile" ]] && grep -q "alias soundcloud=" "$profile" 2>/dev/null; then
            alias_found=true
            break
        fi
    done

    if [[ "$alias_found" == true ]]; then
        print_success "Command 'soundcloud' is configured"
    else
        print_warning "Command setup may need verification"
    fi
else
    print_warning "Installation completed but some components need verification"
    print_info "Close and reopen Terminal, then try: soundcloud help"
fi

# Final success message
echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo -e "${GREEN}=========================${NC}"
echo ""
echo -e "${BLUE}📖 Quick Start Guide:${NC}"
echo -e "${YELLOW}1.${NC} ${RED}Close this Terminal window and open a new one${NC}"
echo -e "${YELLOW}2.${NC} Type: ${GREEN}soundcloud help${NC}"
echo -e "${YELLOW}3.${NC} Try downloading: ${GREEN}soundcloud https://soundcloud.com/artist/song${NC}"
echo ""
echo -e "${BLUE}📁 Your music will be saved to:${NC}"
echo -e "   ${GREEN}$MUSIC_DIR${NC}"
echo ""
echo -e "${BLUE}💡 Example commands:${NC}"
echo -e "   ${GREEN}soundcloud help${NC}                              ${BLUE}# Show detailed help${NC}"
echo -e "   ${GREEN}soundcloud https://soundcloud.com/artist/song${NC}  ${BLUE}# Download a song${NC}"
echo -e "   ${GREEN}soundcloud https://soundcloud.com/user/sets/mix${NC} ${BLUE}# Download a playlist${NC}"
echo ""
echo -e "${BLUE}🗑️  To uninstall later:${NC}"
echo -e "   ${GREEN}bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh) uninstall${NC}"
echo ""
echo -e "${BLUE}🔧 Need help?${NC}"
echo -e "   • Make sure SoundCloud links are public"
echo -e "   • Use ${GREEN}soundcloud -v <link>${NC} for detailed output"
echo -e "   • Run ${GREEN}soundcloud --dry-run <link>${NC} to preview downloads"
echo ""
echo -e "${GREEN}Happy downloading! 🎵${NC}"
