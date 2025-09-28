# Better Pokemon Colorscripts Randomizer

An intelligent Pokemon randomizer that showcases Pokemon with their alternate forms. Features smart weighted selection to give you variety while highlighting Pokemon with unique forms like regional variants, mega evolutions, and costume variations.

## Quick Install

```bash
# Download and setup
curl -O https://raw.githubusercontent.com/SwapFLip/better-pokemon-colorscripts-randomizer/main/randomizer.sh
chmod +x randomizer.sh

# Run it!
./randomizer.sh
```

## Prerequisites

You need [pokemon-colorscripts](https://github.com/phonerebelx/pokemon-colorscripts) installed:

```bash
# Arch Linux / AUR
yay -S pokemon-colorscripts-git

# Manual installation
git clone https://github.com/phonerebelx/pokemon-colorscripts.git
cd pokemon-colorscripts
sudo ./install.sh

# Test it works
pokemon-colorscripts -r
```

## Features

- **Smart Selection**: 50% random Pokemon, 45% Pokemon with forms, 5% shiny
- **Auto-Caching**: Discovers and caches all Pokemon forms automatically  
- **Fast Performance**: Instant after initial cache build
- **Form Support**: Hat Pikachu, regional forms, megas, costumes, and more
- **Debug Tools**: Built-in testing and troubleshooting commands

## Basic Usage

```bash
# Show random Pokemon (auto-builds cache on first run ~5-10 min)
./randomizer.sh

# Force rebuild the forms cache  
./randomizer.sh --build-cache

# Clear cache and start fresh
./randomizer.sh --clear-cache

# Show current cache contents
./randomizer.sh --show-cache
```

## Advanced Commands

| Command | Description | Example |
|---------|-------------|---------|
| `--debug-build [N]` | Test cache building on first N Pokemon | `--debug-build 10` |
| `--debug-build [name]` | Test specific Pokemon form detection | `--debug-build pikachu` |
| `--test-parse [name]` | Debug form extraction for one Pokemon | `--test-parse charizard` |
| `--quiet` | Silent mode (no progress messages) | `--quiet --build-cache` |

## How the Selection Works

The script uses weighted probabilities to ensure variety:

- **50% - Pure Random**: Any Pokemon from the complete list
- **45% - Form Showcase**: Randomly picks a Pokemon with alternate forms, then randomly picks one of its forms
- **5% - Shiny Surprise**: Random shiny Pokemon

This means Pokemon like Pikachu (16+ hat forms) and Alcremie (dozens of variants) get highlighted while still showing regular Pokemon frequently.

## Examples

```bash
# Basic usage
./randomizer.sh

# Silent cache rebuild
./randomizer.sh --quiet --build-cache

# Test if Pikachu forms are detected correctly  
./randomizer.sh --test-parse pikachu

# Debug first 20 Pokemon with detailed output
./randomizer.sh --debug-build 20
```

## Troubleshooting

### Script Won't Execute
```bash
# Make sure it's executable
chmod +x randomizer.sh

# Check if pokemon-colorscripts is installed
which pokemon-colorscripts
pokemon-colorscripts -r
```

### Cache Issues
```bash
# Cache seems broken or empty
./randomizer.sh --clear-cache
./randomizer.sh --build-cache

# Test form parsing works
./randomizer.sh --test-parse pikachu
```

### No Forms Found
```bash
# Debug with verbose output
./randomizer.sh --debug-build 5

# Test known Pokemon with forms
./randomizer.sh --test-parse pikachu
./randomizer.sh --test-parse charizard
```

### Performance Notes
- **First run**: 5-10 minutes to scan all Pokemon (one-time setup)
- **Daily usage**: Nearly instant execution
- **Cache location**: `~/.pokemon_forms_cache`
- **Auto-refresh**: Cache rebuilds after 7 days

## What Pokemon Have Forms?
As of now, 181 pokemon has forms in the original

## Optional: Add to PATH

```bash
# Method 1: System-wide
sudo mv randomizer.sh /usr/local/bin/pokemon-randomizer

# Method 2: User-specific  
mkdir -p ~/.local/bin
ln -s "$(pwd)/randomizer.sh" ~/.local/bin/pokemon-randomizer

# Then use anywhere:
pokemon-randomizer
```

---

**Built on** [pokemon-colorscripts](https://github.com/phonerebelx/pokemon-colorscripts) **by phonerebelx**
