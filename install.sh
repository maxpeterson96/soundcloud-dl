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
    echo -e "${BLUE}====================================${NC}"
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

print_header

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
print_step "🔧 Setting up shell..."
CURRENT_SHELL=$(basename "$SHELL")
print_info "Current shell: $CURRENT_SHELL"

# Determine which profile file to use
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [[ "$CURRENT_SHELL" == "bash" ]]; then
    SHELL_PROFILE="$HOME/.bash_profile"
    SHELL_NAME="bash"
else
    # Default to bash profile for unknown shells
    SHELL_PROFILE="$HOME/.bash_profile"
    SHELL_NAME="bash"
    print_warning "Unknown shell: $CURRENT_SHELL, using bash profile"
fi

print_success "Will use $SHELL_NAME profile: $SHELL_PROFILE"

# 2. Install/Setup Homebrew
print_step "🍺 Setting up Homebrew..."

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

                # Add to shell profile
        BREW_ENV_LINE="eval \"\$(${BREW_PATH}/bin/brew shellenv)\""

        touch "$SHELL_PROFILE"
        if ! grep -q "brew shellenv" "$SHELL_PROFILE" 2>/dev/null; then
            echo "" >> "$SHELL_PROFILE"
            echo "# Homebrew" >> "$SHELL_PROFILE"
            echo "$BREW_ENV_LINE" >> "$SHELL_PROFILE"
            print_success "Added Homebrew to your $SHELL_NAME profile"
        fi
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
print_step "⬇️  Installing yt-dlp (the download engine)..."
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

print_step "📁 Setting up SoundCloud downloader script..."
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

# 5. Set up the alias
print_step "⚙️  Setting up 'soundcloud' command..."
ALIAS_LINE="alias soundcloud=\"$SCRIPT_PATH\""

# Create shell profile if it doesn't exist
touch "$SHELL_PROFILE"

# Add alias if not already present
if ! grep -q "alias soundcloud=" "$SHELL_PROFILE" 2>/dev/null; then
    echo "" >> "$SHELL_PROFILE"
    echo "# SoundCloud Downloader" >> "$SHELL_PROFILE"
    echo "$ALIAS_LINE" >> "$SHELL_PROFILE"
    print_success "Added 'soundcloud' command to your $SHELL_NAME profile"
else
    # Update existing alias
    if sed -i.bak "s|alias soundcloud=.*|$ALIAS_LINE|" "$SHELL_PROFILE"; then
        print_success "Updated existing 'soundcloud' command"
        rm -f "${SHELL_PROFILE}.bak"
    else
        print_warning "Could not update existing alias"
    fi
fi

# 6. Create Music directory
MUSIC_DIR="$HOME/Music/Soundcloud"
mkdir -p "$MUSIC_DIR"
print_success "Created music directory: $MUSIC_DIR"

# 7. Test the installation
print_step "🧪 Testing installation..."
source "$SHELL_PROFILE" 2>/dev/null || true

if command_exists yt-dlp && [[ -x "$SCRIPT_PATH" ]]; then
    print_success "All components installed successfully!"

    # Test the alias in a subshell
    if $CURRENT_SHELL -c "source '$SHELL_PROFILE' && type soundcloud" >/dev/null 2>&1; then
        print_success "Command 'soundcloud' is ready to use"
    else
        print_warning "Command setup needs a Terminal restart"
    fi
else
    print_warning "Installation completed but some components need verification"
    print_info "Close and reopen Terminal, then try: soundcloud help"
fi

# Final success message
echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo -e "${GREEN}========================${NC}"
echo ""
echo -e "${BLUE}📖 Quick Start Guide:${NC}"
echo -e "${YELLOW}1.${NC} Close this Terminal window and open a new one"
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
echo -e "${BLUE}🔧 Need help?${NC}"
echo -e "   • Make sure SoundCloud links are public"
echo -e "   • Use ${GREEN}soundcloud -v <link>${NC} for detailed output"
echo -e "   • Run ${GREEN}soundcloud --dry-run <link>${NC} to preview downloads"
echo ""
echo -e "${PURPLE}Happy downloading! 🎵${NC}"
