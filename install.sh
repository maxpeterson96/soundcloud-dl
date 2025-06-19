#!/usr/bin/env bash
# SoundCloud Downloader - Easy One-Line Installer
# Run with: bash <(curl -fsSL https://raw.githubusercontent.com/your-username/soundcloud-dl/main/install.sh)

set -e

# Simple output without colors
echo "🎵 SoundCloud Downloader Installer"
echo "=================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This installer is designed for macOS"
    echo "💡 You're running: $OSTYPE"
    exit 1
fi

echo "✅ Running on macOS"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Set bash as default shell
echo ""
echo "🔧 Setting up bash shell..."
CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" != "bash" ]]; then
    echo "📝 Changing default shell from $CURRENT_SHELL to bash..."
    echo "🔐 You may be asked for your password:"
    if chsh -s /bin/bash; then
        echo "✅ Default shell changed to bash"
        echo "💡 Note: Close and reopen Terminal after installation"
    else
        echo "⚠️  Could not change shell automatically"
        echo "💡 You can change it later in System Preferences > Users & Groups"
    fi
else
    echo "✅ Bash is already your default shell"
fi

# 2. Install Homebrew
echo ""
echo "🍺 Checking for Homebrew..."
if ! command_exists brew; then
    echo "📦 Installing Homebrew..."
    echo "💡 This may take a few minutes and will ask for your password"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH (for both Intel and Apple Silicon Macs)
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.bash_profile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo "✅ Homebrew installed (Apple Silicon)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.bash_profile"
        eval "$(/usr/local/bin/brew shellenv)"
        echo "✅ Homebrew installed (Intel)"
    fi
else
    echo "✅ Homebrew is already installed"
fi

# 3. Install yt-dlp
echo ""
echo "⬇️  Installing yt-dlp (the download engine)..."
if ! command_exists yt-dlp; then
    brew install yt-dlp
    echo "✅ yt-dlp installed"
else
    echo "✅ yt-dlp is already installed"
    echo "🔄 Updating to latest version..."
    brew upgrade yt-dlp 2>/dev/null || echo "💡 Already up to date"
fi

# 4. Create Scripts directory and download the script
SCRIPT_DIR="$HOME/Scripts"
SCRIPT_NAME="download-soundcloud.sh"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
REPO_URL="https://raw.githubusercontent.com/your-username/soundcloud-dl/main"

echo ""
echo "📁 Setting up SoundCloud downloader..."
mkdir -p "$SCRIPT_DIR"

echo "⬇️  Downloading latest script..."
if curl -fsSL "$REPO_URL/Scripts/$SCRIPT_NAME" -o "$SCRIPT_PATH"; then
    chmod +x "$SCRIPT_PATH"
    echo "✅ Script downloaded and ready"
else
    echo "❌ Failed to download script"
    echo "💡 Check your internet connection and try again"
    exit 1
fi

# 5. Set up the alias
echo ""
echo "⚙️  Setting up 'soundcloud' command..."
BASH_PROFILE="$HOME/.bash_profile"
ALIAS_LINE="alias soundcloud=\"$SCRIPT_PATH\""

# Create .bash_profile if it doesn't exist
touch "$BASH_PROFILE"

# Add alias if not already present
if ! grep -q "alias soundcloud=" "$BASH_PROFILE" 2>/dev/null; then
    echo "" >> "$BASH_PROFILE"
    echo "# SoundCloud Downloader" >> "$BASH_PROFILE"
    echo "$ALIAS_LINE" >> "$BASH_PROFILE"
    echo "✅ Added 'soundcloud' command"
else
    # Update existing alias
    sed -i.bak "s|alias soundcloud=.*|$ALIAS_LINE|" "$BASH_PROFILE"
    echo "✅ Updated 'soundcloud' command"
fi

# 6. Test the installation
echo ""
echo "🧪 Testing installation..."
source "$BASH_PROFILE"

if command_exists yt-dlp && [[ -x "$SCRIPT_PATH" ]]; then
    echo "✅ Everything installed successfully!"
else
    echo "⚠️  Installation completed but testing failed"
    echo "💡 Try closing and reopening Terminal"
fi

# Success message
echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "📖 How to use:"
echo "1. Close this Terminal window"
echo "2. Open a new Terminal window"  
echo "3. Type: soundcloud help"
echo "4. Or try: soundcloud https://soundcloud.com/artist/song-name"
echo ""
echo "📁 Your music will be saved to:"
echo "   ~/Music/Soundcloud/"
echo ""
echo "💡 Examples:"
echo "   soundcloud https://soundcloud.com/artist/song"
echo "   soundcloud https://soundcloud.com/artist/sets/playlist"
echo "   soundcloud help"
