# Pokemon Form Randomizer

A powerful Pokemon display script that intelligently showcases random Pokemon with their alternate forms. Built on top of [pokemon-colorscripts](https://github.com/phonerebelx/pokemon-colorscripts), this tool provides smart weighted selection, comprehensive form caching, and extensive debugging capabilities.

## Features

- **Advanced Form Discovery**: Automatically detects all available Pokemon forms using intelligent parsing
- **Weighted Selection Algorithm**: Ensures variety while highlighting Pokemon with unique forms
- **Robust Error Handling**: Gracefully handles cache corruption, network issues, and parsing errors
- **Performance Optimized**: Efficient caching system minimizes repeated API calls
- **Generation Coverage**: Supports all Pokemon generations available in pokemon-colorscripts (typically Gen 1-8, ~900 Pokemon)

## Prerequisites

You need to have `pokemon-colorscripts` installed:

```bash
# On Arch Linux / AUR
yay -S pokemon-colorscripts-git

# Manual installation
git clone https://github.com/phonerebelx/pokemon-colorscripts.git
cd pokemon-colorscripts
sudo ./install.sh
```

## Installation

1. **Download the script**:
   ```bash
   wget https://raw.githubusercontent.com/[YOUR-USERNAME]/[REPO-NAME]/main/randomizer.sh
   # Or using curl
   curl -O https://raw.githubusercontent.com/[YOUR-USERNAME]/[REPO-NAME]/main/randomizer.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x randomizer.sh
   ```

3. **Optional - Add to PATH for global access**:
   ```bash
   # Method 1: Move to system-wide location
   sudo mv randomizer.sh /usr/local/bin/pokemon-randomizer
   
   # Method 2: Create symlink (keeps original location)
   mkdir -p ~/.local/bin
   ln -s "$(pwd)/randomizer.sh" ~/.local/bin/pokemon-randomizer
   
   # Method 3: Add current directory to PATH (in ~/.bashrc or ~/.zshrc)
   export PATH="$PATH:$(pwd)"
   ```

## Quick Start

```bash
# Basic usage - shows random Pokemon with intelligent selection
./randomizer.sh

# First-time setup - build the forms cache (runs automatically on first use)
./randomizer.sh --build-cache
```

## Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `./randomizer.sh` | **Default**: Intelligent weighted random Pokemon display |
| `./randomizer.sh --build-cache` | Force complete rebuild of the forms cache |
| `./randomizer.sh --clear-cache` | Delete cache and force fresh start |
| `./randomizer.sh --show-cache` | Display current cache contents and statistics |

### Debug & Testing Commands

| Command | Description | Example |
|---------|-------------|---------|
| `--debug-build [N]` | Build cache for first N Pokemon with verbose output | `--debug-build 10` |
| `--debug-build [name]` | Test cache building for specific Pokemon | `--debug-build pikachu` |
| `--test-parse [name]` | Test form extraction for one Pokemon | `--test-parse charizard` |

### Modifiers

| Modifier | Description | Example |
|----------|-------------|---------|
| `--quiet` | Suppress all progress messages during cache operations | `./randomizer.sh --quiet --build-cache` |

## How It Works

### Selection Algorithm

The script uses a sophisticated weighted probability system to ensure both variety and showcase rare forms:

- **50% - Pure Random**: Any Pokemon from the complete available list (fair representation)
- **45% - Form-Enhanced Selection**: 
  - Randomly selects from Pokemon that have alternate forms
  - Then randomly selects one of that Pokemon's available forms
  - Highlights Pokemon with unique variants (hats, regional forms, megas, etc.)
- **5% - Shiny Surprise**: Random shiny Pokemon for that extra sparkle

This approach ensures you see the full spectrum of Pokemon while giving special attention to those with interesting alternate forms.

### Cache System

The script maintains an intelligent cache system at `~/.pokemon_forms_cache`:

- **Automatic Initialization**: Builds cache on first run (5-10 minutes initial setup)
- **Smart Refresh Logic**: Auto-rebuilds when cache exceeds 7 days old
- **Efficient Storage**: Stores Pokemon-to-forms mappings in optimized format
- **Error Recovery**: Detects corrupted cache and rebuilds automatically
- **Performance Focused**: Subsequent runs are near-instantaneous

### Form Discovery

The script discovers forms by:
1. Getting the complete Pokemon list from `pokemon-colorscripts`
2. Testing each Pokemon with an invalid form name
3. Parsing the error output to extract available forms
4. Filtering out standard forms (normal, default, base)

## Examples

```bash
# Display a random Pokemon with intelligent selection
./randomizer.sh

# Silent cache rebuild (no progress output)
./randomizer.sh --quiet --build-cache

# Debug specific Pokemon forms detection
./randomizer.sh --test-parse alcremie

# Inspect your current cache contents
./randomizer.sh --show-cache

# Test form parsing on a subset for troubleshooting
./randomizer.sh --debug-build 20

# Test specific Pokemon you suspect has parsing issues
./randomizer.sh --debug-build mewtwo
```

## Troubleshooting

### Cache Issues

```bash
# Cache seems corrupted or empty
./randomizer.sh --clear-cache
./randomizer.sh --build-cache

# Verify form parsing works correctly
./randomizer.sh --test-parse pikachu
```

### No Forms Found After Cache Build

```bash
# Debug parsing with verbose output
./randomizer.sh --debug-build 5

# Test a Pokemon known to have many forms
./randomizer.sh --test-parse pikachu

# Check if pokemon-colorscripts is working
pokemon-colorscripts -n pikachu -f original-cap
```

### Script Won't Execute

```bash
# Ensure script is executable
chmod +x randomizer.sh

# Check if pokemon-colorscripts is installed
which pokemon-colorscripts

# Verify pokemon-colorscripts works
pokemon-colorscripts -r
```

### Performance

- **Initial Setup**: 5-10 minutes for complete cache build (one-time)
- **Daily Usage**: Near-instantaneous execution
- **Cache Size**: Typically 100-200 Pokemon with alternate forms
- **Memory Usage**: Minimal - cache file usually under 10KB

## Technical Details

### Cache Format
```
# Forms cache built on [date] (queried: [count])
pikachu:original-cap:hoenn-cap:sinnoh-cap:unova-cap:kalos-cap:alola-cap:partner-cap:world-cap
charizard:mega-x:mega-y:gigantamax
```

### Form Extraction Logic
- Uses `awk` to parse `pokemon-colorscripts` error output
- Looks for "Available forms" messages
- Extracts dash-prefixed form names
- Filters out standard/default form names

## Configuration

Edit these variables in the script to customize behavior:

```bash
CACHE_EXPIRY_DAYS=7     # How often to rebuild cache
INVALID_FORM="hi"       # Form name used for discovery
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test with `--debug-build` and `--test-parse`
4. Submit a pull request

### Testing

Always test changes thoroughly:
```bash
./randomizer.sh --debug-build 10
./randomizer.sh --test-parse pikachu
./randomizer.sh --clear-cache && ./randomizer.sh
```

## Acknowledgments

- Built on top of [pokemon-colorscripts](https://github.com/phonerebelx/pokemon-colorscripts) by phonerebelx
- Inspired by the community need for enhanced Pokemon form randomization
- Thanks to all contributors who helped improve form detection and caching algorithms
