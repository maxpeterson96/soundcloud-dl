#!/usr/bin/env bash
# SoundCloud Downloader - Simple music downloading tool

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    cat <<-EOF
${BLUE}SoundCloud Downloader${NC}
${BLUE}=====================${NC}

${GREEN}Download music from SoundCloud in highest quality${NC}

${CYAN}BASIC USAGE:${NC}
  ${GREEN}soundcloud <link>${NC}

${CYAN}QUICK EXAMPLES:${NC}
  ${YELLOW}# Download any song (saves to ~/Music/Soundcloud)${NC}
  soundcloud https://soundcloud.com/skrillex/bangarang

  ${YELLOW}# Download a full playlist or album${NC}
  soundcloud https://soundcloud.com/user/sets/playlist-name

  ${YELLOW}# Download all tracks from an artist${NC}
  soundcloud https://soundcloud.com/artist-name

${CYAN}SAVE TO DIFFERENT LOCATIONS:${NC}
  ${YELLOW}# Save to Desktop${NC}
  soundcloud -d ~/Desktop https://soundcloud.com/artist/song

  ${YELLOW}# Save to a specific music folder${NC}
  soundcloud -d ~/Music/Electronic https://soundcloud.com/artist/song

${CYAN}QUALITY OPTIONS:${NC}
  ${YELLOW}# Best quality (default - recommended)${NC}
  soundcloud https://soundcloud.com/artist/song

  ${YELLOW}# Good quality (smaller files)${NC}
  soundcloud -q good https://soundcloud.com/artist/song

  ${YELLOW}# Small files (lowest quality)${NC}
  soundcloud -q small https://soundcloud.com/artist/song

${CYAN}PREVIEW & TROUBLESHOOTING:${NC}
  ${YELLOW}# See what would be downloaded (no actual download)${NC}
  soundcloud --dry-run https://soundcloud.com/artist/song

  ${YELLOW}# Get detailed information during download${NC}
  soundcloud -v https://soundcloud.com/artist/song

  ${YELLOW}# Combine preview with details${NC}
  soundcloud -v --dry-run https://soundcloud.com/artist/sets/playlist

${CYAN}ADVANCED OPTIONS:${NC}
  ${YELLOW}# Skip album art (faster downloads)${NC}
  soundcloud --no-thumb https://soundcloud.com/artist/song

  ${YELLOW}# Skip metadata (artist, title info)${NC}
  soundcloud --no-meta https://soundcloud.com/artist/song

  ${YELLOW}# Combine options${NC}
  soundcloud -d ~/Desktop -q good --no-thumb https://soundcloud.com/artist/song

${CYAN}YOUR MUSIC:${NC}
  ${GREEN}Default location: ~/Music/Soundcloud${NC}
  ${GREEN}Organized as: Artist/Album/Song.m4a${NC}

${CYAN}TROUBLESHOOTING:${NC}
  ${RED}•${NC} ${YELLOW}Make sure the SoundCloud link is public${NC}
  ${RED}•${NC} ${YELLOW}Check your internet connection${NC}
  ${RED}•${NC} ${YELLOW}Some tracks may not be downloadable due to artist settings${NC}
  ${RED}•${NC} ${YELLOW}Use ${GREEN}-v${NC} flag for detailed error information${NC}
  ${RED}•${NC} ${YELLOW}Try ${GREEN}--dry-run${NC} first to see what's available${NC}

${CYAN}UNINSTALL:${NC}
  ${YELLOW}# Easy uninstall command${NC}
  bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh) uninstall

  ${YELLOW}# Or manual removal:${NC}
  ${YELLOW}# 1. Remove the script${NC}
  rm ~/Scripts/download-soundcloud.sh

  ${YELLOW}# 2. Remove aliases from both shell profiles${NC}
  sed -i.bak '/alias soundcloud=/d' ~/.zshrc ~/.bash_profile 2>/dev/null || true
  sed -i.bak '/# SoundCloud Downloader/d' ~/.zshrc ~/.bash_profile 2>/dev/null || true

  ${YELLOW}# 3. Remove downloaded music (optional)${NC}
  rm -rf ~/Music/Soundcloud

  ${YELLOW}# 4. Restart Terminal${NC}

${CYAN}EXAMPLES FOR YOUR FRIEND:${NC}
  ${GREEN}soundcloud help${NC}                              ${BLUE}# Show this help${NC}
  ${GREEN}soundcloud https://soundcloud.com/artist/song${NC}  ${BLUE}# Download one song${NC}
  ${GREEN}soundcloud https://soundcloud.com/user/sets/mix${NC} ${BLUE}# Download playlist${NC}
  ${GREEN}soundcloud -d ~/Desktop <link>${NC}              ${BLUE}# Save to Desktop${NC}
  ${GREEN}soundcloud --dry-run <link>${NC}                 ${BLUE}# Preview first${NC}

EOF
}

# Check if yt-dlp is installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YTDLP_PATH="$SCRIPT_DIR/yt-dlp"

if [[ ! -x "$YTDLP_PATH" ]]; then
    echo -e "${RED}ERROR: yt-dlp binary not found${NC}"
    echo -e "${BLUE}INFO: Expected location: $YTDLP_PATH${NC}"
    echo ""
    echo -e "${YELLOW}Quick fixes:${NC}"
    echo -e "${BLUE}1. Reinstall: ${GREEN}bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh)${NC}"
    echo -e "${BLUE}2. Or download manually from: ${GREEN}https://github.com/yt-dlp/yt-dlp/releases/latest${NC}"
    echo -e "${BLUE}3. Make sure the binary is executable: ${GREEN}chmod +x $YTDLP_PATH${NC}"
    exit 1
fi

# Defaults - highest quality with thumbnails and metadata
DEST="$HOME/Music/Soundcloud"
FORMAT='bestaudio[ext=m4a]/bestaudio'  # Best quality by default
EMBED_THUMB="--embed-thumbnail"
ADD_META="--add-metadata"
OUTPUT_TPL='%(uploader)s/%(playlist_title)s/%(title)s.%(ext)s'
VERBOSE=""

# No arguments
if [[ $# -eq 0 ]]; then
    echo -e "${BLUE}SoundCloud Downloader${NC}"
    echo -e "${YELLOW}Usage: ${GREEN}soundcloud <SoundCloud-link>${NC}"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  ${GREEN}soundcloud https://soundcloud.com/artist/song${NC}"
    echo -e "  ${GREEN}soundcloud https://soundcloud.com/user/sets/playlist${NC}"
    echo ""
    echo -e "${BLUE}For detailed help: ${GREEN}soundcloud help${NC}"
    exit 1
fi

# Handle help command
if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dest)
            if [[ -z "$2" ]]; then
                echo -e "${RED}ERROR: --dest needs a folder path${NC}"
                echo -e "${BLUE}INFO: Example: ${GREEN}soundcloud -d ~/Desktop <link>${NC}"
                exit 1
            fi
            DEST="$2"
            shift 2
            ;;
        -q|--quality)
            if [[ -z "$2" ]]; then
                echo -e "${RED}ERROR: --quality needs a level${NC}"
                echo -e "${BLUE}INFO: Options: ${GREEN}best${NC}, ${GREEN}good${NC}, or ${GREEN}small${NC}"
                exit 1
            fi
            case "$2" in
                best|high)
                    FORMAT='bestaudio[ext=m4a]/bestaudio'
                    ;;
                good|medium)
                    FORMAT='bestaudio[ext=mp3]/bestaudio[abr<=192]/bestaudio'
                    ;;
                small|low)
                    FORMAT='bestaudio[ext=mp3]/bestaudio[abr<=128]/bestaudio'
                    ;;
                *)
                    echo -e "${RED}ERROR: Invalid quality: $2${NC}"
                    echo -e "${BLUE}INFO: Valid options: ${GREEN}best${NC}, ${GREEN}good${NC}, or ${GREEN}small${NC}"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --no-thumb)
            EMBED_THUMB=""
            shift
            ;;
        --no-meta)
            ADD_META=""
            shift
            ;;
        -v|--verbose)
            VERBOSE="--verbose"
            shift
            ;;
        --dry-run)
            DRY_RUN="--simulate"
            shift
            ;;
        -*)
            echo -e "${RED}ERROR: Unknown option: $1${NC}"
            echo -e "${BLUE}INFO: Type ${GREEN}'soundcloud help'${NC} for available options"
            exit 1
            ;;
        *)
            URL="$1"
            shift
            break
            ;;
    esac
done

# Check for URL
if [[ -z "$URL" ]]; then
    echo -e "${RED}ERROR: No SoundCloud link provided${NC}"
    echo -e "${BLUE}INFO: Usage: ${GREEN}soundcloud <SoundCloud-link>${NC}"
    echo -e "${BLUE}INFO: Example: ${GREEN}soundcloud https://soundcloud.com/artist/song${NC}"
    exit 1
fi

# Validate it's a SoundCloud URL
if [[ ! "$URL" =~ soundcloud\.com ]]; then
    echo -e "${RED}ERROR: That doesn't look like a SoundCloud link${NC}"
    echo -e "${BLUE}INFO: Make sure it looks like: ${GREEN}https://soundcloud.com/artist/track${NC}"
    echo -e "${BLUE}INFO: Links should start with: ${GREEN}https://soundcloud.com/${NC}"
    exit 1
fi

# Expand home directory if needed
DEST="${DEST/#\~/$HOME}"

# Create destination folder
if ! mkdir -p "$DEST"; then
    echo -e "${RED}ERROR: Can't create folder: $DEST${NC}"
    echo -e "${BLUE}INFO: Check folder permissions or try a different location${NC}"
    exit 1
fi

echo -e "${BLUE}SoundCloud Downloader${NC}"
echo -e "${BLUE}=====================${NC}"
echo -e "${CYAN}Source: ${GREEN}$URL${NC}"
echo -e "${CYAN}Destination: ${GREEN}$DEST${NC}"

# Show what we're about to do
if [[ -n "$DRY_RUN" ]]; then
    echo -e "${YELLOW}Preview mode - no files will be downloaded${NC}"
else
    echo -e "${GREEN}Starting download...${NC}"
fi

# Build command - auto-detect playlist vs single with --yes-playlist
cmd=("$YTDLP_PATH")
cmd+=(--yes-playlist)  # Auto-detects and handles both single tracks and playlists
[[ -n "$DRY_RUN" ]] && cmd+=("$DRY_RUN")
cmd+=(-f "$FORMAT")
[[ -n "$EMBED_THUMB" ]] && cmd+=("$EMBED_THUMB")
[[ -n "$ADD_META" ]] && cmd+=("$ADD_META")
cmd+=(--ignore-errors)      # Continue if some tracks fail
cmd+=(--no-overwrites)      # Don't re-download existing files
[[ -n "$VERBOSE" ]] && cmd+=("$VERBOSE")
cmd+=(-o "$DEST/$OUTPUT_TPL")
cmd+=("$URL")

# Show command in verbose mode
if [[ -n "$VERBOSE" ]]; then
    echo -e "${BLUE}INFO: Running command: ${CYAN}${cmd[*]}${NC}"
    echo ""
fi

# Download
if "${cmd[@]}"; then
    if [[ -n "$DRY_RUN" ]]; then
        echo ""
        echo -e "${GREEN}SUCCESS: Preview complete!${NC}"
        echo -e "${BLUE}INFO: Run without ${GREEN}--dry-run${NC} to actually download${NC}"
    else
        echo ""
        echo -e "${GREEN}SUCCESS: Download complete!${NC}"
        echo -e "${CYAN}Your music is in: ${GREEN}$DEST${NC}"
        echo -e "${BLUE}INFO: Run the same command again to get any new tracks${NC}"
    fi
else
    echo ""
    echo -e "${RED}ERROR: Download failed${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo -e "${BLUE}• Make sure the SoundCloud link is public${NC}"
    echo -e "${BLUE}• Check your internet connection${NC}"
    echo -e "${BLUE}• Some tracks may not be downloadable${NC}"
    echo -e "${BLUE}• Try: ${GREEN}soundcloud -v <your-link>${NC} for detailed output${NC}"
    echo -e "${BLUE}• Try: ${GREEN}soundcloud --dry-run <your-link>${NC} to preview first${NC}"
    exit 1
fi