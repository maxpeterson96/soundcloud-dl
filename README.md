# 🎵 SoundCloud Downloader

Easy one-line installation tool for downloading music from SoundCloud in highest quality.

## 🚀 Quick Install (macOS only)

Copy and paste this single line into Terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh)
```

That's it! The installer will:
- ✅ Set up your shell (if needed)
- ✅ Install Homebrew (if needed)
- ✅ Install the download engine
- ✅ Create the `soundcloud` command
- ✅ Set everything up automatically

## 📖 How to Use

After installation, close Terminal and open it again. Then:

### Basic Examples
```bash
# Download any song
soundcloud https://soundcloud.com/artist/song-name

# Download a playlist or album
soundcloud https://soundcloud.com/artist/sets/playlist-name

# Get help and see all options
soundcloud help
```

### Save to Different Locations
```bash
# Save to Desktop
soundcloud -d ~/Desktop https://soundcloud.com/artist/song

# Save to a specific folder
soundcloud -d ~/Music/MyMusic https://soundcloud.com/artist/song
```

### Preview Before Downloading
```bash
# See what would be downloaded (no actual download)
soundcloud --dry-run https://soundcloud.com/artist/song

# Get detailed information
soundcloud -v https://soundcloud.com/artist/song
```

## 📁 Where Your Music Goes

By default, music is saved to:
```
~/Music/Soundcloud/Artist/Album/Song.m4a
```

## 🔧 Troubleshooting

If something doesn't work:

1. **Command not found?**
   - Close Terminal and open it again
   - Run the installer again

2. **Download failed?**
   - Make sure the SoundCloud link is public
   - Try: `soundcloud -v <link>` for details
   - Try: `soundcloud --dry-run <link>` to preview

3. **Still having issues?**
   - Run the installer again (it's safe to run multiple times)

## 🎯 Features

- ✅ **One-line install** - No technical knowledge needed
- ✅ **Best quality** - Downloads in highest available quality
- ✅ **Auto-detects** - Works with songs, playlists, and albums
- ✅ **Smart organization** - Files organized by Artist/Album
- ✅ **Resume downloads** - Won't re-download existing files
- ✅ **Preview mode** - See what's available before downloading
- ✅ **Detailed help** - Clear examples and troubleshooting

## 💡 Pro Tips

- Use `soundcloud help` to see all available options
- The `--dry-run` option is great for checking large playlists first
- You can run the same command multiple times to get new tracks
- The installer can be run multiple times safely if something breaks

---

Made with ❤️ for easy music downloading