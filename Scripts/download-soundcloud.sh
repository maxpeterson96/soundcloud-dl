#!/usr/bin/env bash
# SoundCloud Downloader - Simple music downloading tool

show_help() {
    cat <<-EOF
🎵 SoundCloud Downloader

Download music from SoundCloud in highest quality

BASIC USAGE:
  soundcloud <link>

  # Download any song or playlist (auto-detects which)
  soundcloud https://soundcloud.com/skrillex/bangarang
  soundcloud https://soundcloud.com/artist/sets/playlist-name

Your music saves to: ~/Music/Soundcloud

OPTIONS WITH EXAMPLES:

📁 Save to different locations:
  soundcloud -d ~/Desktop https://soundcloud.com/artist/song
  soundcloud -d ~/Music/Electronic https://soundcloud.com/artist/playlist

🔍 Get more info:
  soundcloud -v https://soundcloud.com/artist/song         (show download details)
  soundcloud --dry-run https://soundcloud.com/artist/song  (preview without downloading)

💡 Combine options:
  soundcloud -d ~/Desktop -v https://soundcloud.com/artist/playlist
  soundcloud -v --dry-run https://soundcloud.com/artist/sets/big-playlist

🚫 Skip features (faster downloads):
  soundcloud --no-thumb https://soundcloud.com/artist/song  (no album art)
  soundcloud --no-meta https://soundcloud.com/artist/song   (no song info)

TROUBLESHOOTING:
  • Make sure the SoundCloud link is public
  • Check your internet connection  
  • Some tracks may not be downloadable
  • Use -v for detailed error info

EOF
}

# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null; then
    echo "❌ yt-dlp is not installed"
    echo "💡 Install it with: brew install yt-dlp"
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
    echo "🎵 SoundCloud Downloader"
    echo "Usage: soundcloud <SoundCloud-link>"
    echo ""
    echo "Example: soundcloud https://soundcloud.com/artist/song"
    echo "For help: soundcloud help"
    exit 1
fi

# Handle help command
if [[ "$1" == "help" ]]; then
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
                echo "❌ --dest needs a folder path"
                exit 1
            fi
            DEST="$2"
            shift 2
            ;;
        -q|--quality)
            if [[ -z "$2" ]]; then
                echo "❌ --quality needs a level (best, good, or small)"
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
                    echo "❌ Invalid quality: $2"
                    echo "💡 Use: best, good, or small"
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
            echo "❌ Unknown option: $1"
            echo "💡 Type 'soundcloud help' for options"
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
    echo "❌ No link provided"
    echo "💡 Usage: soundcloud <SoundCloud-link>"
    exit 1
fi

# Validate it's a SoundCloud URL
if [[ ! "$URL" =~ soundcloud\.com ]]; then
    echo "❌ That doesn't look like a SoundCloud link"
    echo "💡 Make sure it looks like: https://soundcloud.com/artist/track"
    exit 1
fi

# Expand home directory if needed
DEST="${DEST/#\~/$HOME}"

# Create destination folder
if ! mkdir -p "$DEST"; then
    echo "❌ Can't create folder: $DEST"
    exit 1
fi

echo "🎵 Downloading music..."
echo "📍 From: $URL"
echo "💾 Saving to: $DEST"

# Build command - auto-detect playlist vs single with --yes-playlist
cmd=(yt-dlp)
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

# Download
if "${cmd[@]}"; then
    echo "✅ Download complete!"
    echo "📂 Your music is in: $DEST"
    echo "💡 Run the same command again to get any new tracks"
else
    echo "❌ Download failed"
    echo "💡 Try: soundcloud -v <your-link> for more details"
    exit 1
fi