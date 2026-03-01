<p align="center">
  <img src="ClaudeExplorer/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" height="128" alt="Claude Explorer Icon">
</p>

<h1 align="center">Claude Explorer</h1>

<p align="center">
  <em>Monitor your Claude Code API usage from the macOS menu bar</em>
</p>

<p align="center">
  <a href="https://github.com/ivantha/claude-explorer/releases/latest"><img src="https://img.shields.io/github/v/release/ivantha/claude-explorer?style=flat-square" alt="Release"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ivantha/claude-explorer?style=flat-square" alt="License"></a>
</p>

---

## Screenshots

> *Coming soon — screenshots of the menu bar and detail popover will be added here.*

## Features

- **Menu bar integration** — lives in your menu bar, always one click away
- **Real-time token tracking** — monitors input, output, and cache tokens
- **5-hour rolling windows** — matches Claude's actual rate-limit windows
- **Cost estimation** — calculates USD cost per model using official API pricing
- **Burn rate** — shows tokens/minute so you can pace your usage
- **Per-model breakdown** — separate stats for Opus, Sonnet, and Haiku
- **Plan support** — configure Pro, Max (5x), or Max (20x) token limits
- **Color-coded indicators** — green/yellow/red usage levels at a glance
- **Configurable refresh** — set your preferred auto-refresh interval
- **Launch at login** — optionally start with macOS

## Installation

### Download (Recommended)

1. Download `ClaudeExplorer.zip` from the [latest release](https://github.com/ivantha/claude-explorer/releases/latest)
2. Unzip and drag `ClaudeExplorer.app` to `/Applications`
3. Launch the app

> **Note:** The app is not notarized. On first launch, macOS Gatekeeper may block it.
> To open it: right-click the app → **Open** → **Open** in the dialog.
> Alternatively, run: `xattr -cr /Applications/ClaudeExplorer.app`

### Build from Source

```bash
git clone https://github.com/ivantha/claude-explorer.git
cd claude-explorer
make build
make install
```

## Usage

1. **Launch** Claude Explorer — it appears as an icon in your menu bar
2. **Use Claude Code** as you normally would
3. **Glance at the menu bar** to see your current usage percentage
4. **Click the icon** to see detailed stats: token counts, cost, burn rate, and per-model breakdown
5. The app **auto-refreshes** at your configured interval

## Configuration

Access settings from the app's menu bar popover.

| Setting | Description | Default |
|---------|-------------|---------|
| Plan | Your Claude subscription tier | Pro |
| Refresh Interval | How often usage data is recalculated | 30s |
| Launch at Login | Start automatically with macOS | Off |

### Plan Token Limits

Token limits per 5-hour window (input + output combined):

| Plan | Token Limit |
|------|-------------|
| Pro | 19,000 |
| Max (5x) | 88,000 |
| Max (20x) | 220,000 |

## How It Works

Claude Explorer reads the JSONL log files that Claude Code writes to `~/.claude/projects/`. It:

1. **Scans** all `*.jsonl` files across project directories
2. **Parses** `assistant` and `progress` events to extract token usage
3. **Deduplicates** entries by message ID
4. **Groups** usage into 5-hour rolling window blocks (matching Claude's rate-limit windows)
5. **Calculates** usage percentage against your plan's token limit, estimated cost, and burn rate

No data leaves your machine — everything is computed locally from files already on disk.

## Requirements

- **macOS 14** (Sonoma) or later
- **Claude Code** installed and used (so that log files exist at `~/.claude/`)
- No API key or authentication needed

## License

[MIT](LICENSE)
