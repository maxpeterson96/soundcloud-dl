# SoundCloud Downloader

Easy one-line installation tool for downloading music from SoundCloud in highest quality. Designed for non-technical users with automatic setup and uninstall.

## Quick Install (macOS only)

Copy and paste this single line into Terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh)
```

That's it! The installer will:
- Automatically detect your shell (bash or zsh)
- Install Homebrew (if needed)
- Install the download engine (yt-dlp)
- Create the `soundcloud` command
- Set everything up for both bash and zsh
- Work on both Intel and Apple Silicon Macs

## How to Use

After installation, **close Terminal and open it again**. Then:

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

## Where Your Music Goes

By default, music is saved to:
```
~/Music/Soundcloud/Artist/Album/Song.m4a
```

## Easy Uninstall

To completely remove SoundCloud Downloader:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/maxpeterson96/soundcloud-dl/main/install.sh) uninstall
```

This will:
- Remove the download script
- Clean both bash and zsh profiles
- Ask about removing downloaded music
- Leave no traces behind

## Troubleshooting

If something doesn't work:

1. **Command not found after installation?**
   - **Close Terminal completely and open it again** (this is crucial!)
   - Make sure you saw "Installation Complete!" message
   - Run the installer again (it's safe to run multiple times)

2. **Still not working?**
   - Try: `which soundcloud` to see if it's installed
   - Check: `echo $SHELL` to see your current shell
   - Run: `source ~/.zshrc` or `source ~/.bash_profile`

3. **Download failed?**
   - Make sure the SoundCloud link is public
   - Try: `soundcloud -v <link>` for details
   - Try: `soundcloud --dry-run <link>` to preview

4. **Still having issues?**
   - Run the installer again (it's safe to run multiple times)
   - Make sure you're using the latest version

## Features

- **One-line install** - No technical knowledge needed
- **Universal shell support** - Works with both bash and zsh
- **Best quality** - Downloads in highest available quality
- **Auto-detects** - Works with songs, playlists, and albums
- **Smart organization** - Files organized by Artist/Album
- **Resume downloads** - Won't re-download existing files
- **Preview mode** - See what's available before downloading
- **Easy uninstall** - One command removes everything
- **Detailed help** - Clear examples and troubleshooting

## Pro Tips

- **Always close and reopen Terminal after installation** - This is the most common fix
- Use `soundcloud help` to see all available options
- The `--dry-run` option is great for checking large playlists first
- You can run the same command multiple times to get new tracks
- The installer can be run multiple times safely if something breaks
- Both Intel and Apple Silicon Macs are fully supported

## For Non-Technical Users

This tool is designed to be as simple as possible:

1. **Installation**: Copy one line, paste in Terminal, press Enter
2. **Usage**: `soundcloud <link>` - that's it!
3. **Help**: `soundcloud help` shows everything you need
4. **Uninstall**: One command removes everything

No need to understand shells, package managers, or command line tools. Everything is automated!

---

Made with love for easy music downloading