#!/bin/bash

# Cache file location
CACHE_FILE="$HOME/.pokemon_forms_cache"
CACHE_EXPIRY_DAYS=7  # Rebuild if older

# Invalid form to use for discovery
INVALID_FORM="hi"

# Function to extract forms from tool's output (confirmed working)
extract_forms() {
    local output="$1"
    # Use awk: flexible trigger, handle blanks, collect - lines
    local forms=$(echo "$output" | awk '
    BEGIN { in_list = 0 }
    /Invalid form/ { next }  # Skip invalid message
    /[Aa]vailable.*[Ff]orms/ { in_list = 1; next }  # Flexible trigger (e.g., "Available alternate forms")
    in_list {
        if (/^$/) { next }  # Skip blank lines
        if (/^- /) {
            gsub(/^- /, "")  # Remove "- "
            gsub(/^[ \t]+|[ \t]+$/, "")  # Trim
            if ($0 != "" && $0 != "'$INVALID_FORM'" && $0 !~ /^(normal|default|base|standard|none)$/i) print $0
        } else {
            in_list = 0  # End on non-blank, non-list line
        }
    }
    END { }
    ' | sort -u | tr '\n' ':' | sed 's/:$//')  # Safe join

    if [ -n "$forms" ]; then
        echo "$forms"
    else
        echo ""
    fi
}

# Function to build/update cache (fixed arg handling)
build_cache() {
    local force="$1"
    local debug_arg="$2"  # Positive number for limit, non-empty string for specific; empty/"0" = no debug
    local quiet="$3"
    local cache_age=0
    local is_debug=0
    local limit=""
    local specific_poke=""

    # Handle debug arg: only if positive number or non-empty non-numeric (name)
    if [ -n "$debug_arg" ] && [ "$debug_arg" != "0" ]; then
        if [[ "$debug_arg" =~ ^[1-9][0-9]*$ ]]; then
            is_debug=1
            limit="$debug_arg"
            [ -z "$quiet" ] && echo "DEBUG MODE: Querying only first $limit Pokémon with verbose output."
        elif [ -n "$debug_arg" ]; then
            is_debug=1
            specific_poke="$debug_arg"
            [ -z "$quiet" ] && echo "DEBUG MODE: Querying only specific Pokémon '$specific_poke' with verbose output."
        fi
    fi

    # Check if cache exists and is recent (skip in debug/force)
    if [ "$is_debug" -eq 0 ] && [ -f "$CACHE_FILE" ] && [ ! "$force" = "force" ]; then
        cache_age=$(( ($(date +%s) - $(date -r "$CACHE_FILE" +%s)) / 86400 ))
        if [ "$cache_age" -lt "$CACHE_EXPIRY_DAYS" ]; then
            [ -z "$quiet" ] && echo "Cache is fresh ($cache_age days old). Skipping build."
            return 0
        else
            [ -z "$quiet" ] && echo "Cache is $cache_age days old (> $CACHE_EXPIRY_DAYS). Rebuilding..."
        fi
    fi

    # Get all Pokémon names (robust: strip prefixes, lowercase)
    local all_pokemon=$(pokemon-colorscripts -l 2>/dev/null | grep -v '^$' | sed 's/^[ \t]*[0-9]*[.)#: ]*//g; s/^[ \t]*//; s/[ \t]*$//; y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' | grep -v '^$')

    if [ -z "$all_pokemon" ]; then
        echo "Error: Could not fetch Pokémon list. Run 'pokemon-colorscripts -l' manually to check (expect lowercase names)."
        return 1
    fi

    # For specific debug
    if [ -n "$specific_poke" ]; then
        all_pokemon="$specific_poke"
    else
        # For limit debug
        if [ "$is_debug" -eq 1 ] && [ -n "$limit" ]; then
            all_pokemon=$(echo "$all_pokemon" | head -n "$limit")
        fi
    fi

    # Clear cache and add header
    echo "# Forms cache built on $(date) (queried: $(echo "$all_pokemon" | wc -l))" > "$CACHE_FILE"
    > "$CACHE_FILE.tmp"

    local count=0
    local total=$(echo "$all_pokemon" | wc -l)
    if [ "$is_debug" -eq 0 ]; then
        [ -z "$quiet" ] && echo "Querying $total Pokémon for forms (5-10 minutes)..."
    fi

    # Loop over Pokémon
    local pokemon_list=($all_pokemon)
    for i in "${!pokemon_list[@]}"; do
        local pokemon="${pokemon_list[$i]}"
        if [ -n "$pokemon" ]; then
            count=$((count + 1))
            if [ "$is_debug" -eq 0 ]; then
                [ -z "$quiet" ] && echo -ne "Progress: $count/$total\r"
            fi

            local output=$(pokemon-colorscripts -n "$pokemon" -f "$INVALID_FORM" 2>&1)
            local forms=$(extract_forms "$output")

            # Debug verbose
            if [ "$is_debug" -eq 1 ]; then
                echo "=== DEBUG: $((i+1)): $pokemon ==="
                echo "Raw output:"
                echo "$output"
                echo "Extracted: '$forms'"
                echo "----------------------------------------"
                if [ -n "$forms" ]; then
                    echo "SUCCESS: Forms found ($(echo "$forms" | tr ':' '\n' | wc -l) forms)!"
                else
                    echo "No forms (normal for this Pokémon)."
                fi
                echo ""
            fi

            if [ -n "$forms" ]; then
                echo "$pokemon:$forms" >> "$CACHE_FILE.tmp"
            fi
        fi
    done

    # Append data to cache
    if [ -s "$CACHE_FILE.tmp" ]; then
        cat "$CACHE_FILE.tmp" >> "$CACHE_FILE"
        rm -f "$CACHE_FILE.tmp"
    fi

    local num_forms=$(tail -n +2 "$CACHE_FILE" 2>/dev/null | wc -l)
    [ -z "$quiet" ] && echo ""
    [ -z "$quiet" ] && echo "Build complete! Found $num_forms Pokémon with forms."
    [ -z "$quiet" ] && [ "$num_forms" -gt 0 ] && echo "Sample: $(tail -n 1 "$CACHE_FILE")"
    [ -z "$quiet" ] && [ "$num_forms" -eq 0 ] && echo "No forms found across queried Pokémon. If full build, check tool with --test-parse."
}

# Function to load cache (FIXED: avoid subshell pipe issue)
load_cache() {
    local verbose="$1"
    declare -gA POKEMON_FORMS
    
    if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
        [ "$verbose" = "verbose" ] && echo "Cache missing or empty."
        return 1
    fi

    local loaded_count=0
    
    # Use process substitution to avoid subshell
    while IFS= read -r line; do
        if [ -n "$line" ] && [[ "$line" != \#* ]]; then  # Skip comments/empties
            local pokemon=$(echo "$line" | cut -d: -f1 | sed 's/^[ \t]*//;s/[ \t]*$//')
            local forms=$(echo "$line" | cut -d: -f2- | sed 's/^[ \t]*//;s/[ \t]*$//')
            if [ -n "$pokemon" ] && [ -n "$forms" ]; then
                POKEMON_FORMS["$pokemon"]="$forms"
                ((loaded_count++))
            fi
        fi
    done < <(tail -n +2 "$CACHE_FILE" 2>/dev/null)

    [ "$verbose" = "verbose" ]
    if [ "$loaded_count" -eq 0 ] && [ "$verbose" = "verbose" ]; then
        echo "Warning: 0 loaded (cache may be malformed). First few lines:"
        head -n 5 "$CACHE_FILE"
    fi
    
    return 0
}

# Function to test parsing for one Pokémon
test_parse() {
    local pokemon="$1"
    if [ -z "$pokemon" ]; then
        echo "Usage: --test-parse <pokemon> (e.g., pikachu)"
        return 1
    fi
    local output=$(pokemon-colorscripts -n "$pokemon" -f "$INVALID_FORM" 2>&1)
    echo "Raw output for $pokemon:"
    echo "$output"
    echo ""
    local extracted=$(extract_forms "$output")
    echo "Extracted forms: $extracted"
    if [ -n "$extracted" ]; then
        local count=$(echo "$extracted" | tr ':' '\n' | wc -l)
        echo "Count: $count (expected ~16 for pikachu)"
    else
        echo "No forms found. If this is pikachu, share raw output for tweaks."
    fi
}

# Handle commands
case "$1" in
    --build-cache|--full-build)
        build_cache "force" "" "${2:-}"  # Full, no debug; quiet optional
        exit 0
        ;;
    --debug-build)
        build_cache "" "${2:-5}" ""  # Default 5, or specific/name
        exit 0
        ;;
    --test-parse)
        test_parse "$2"
        exit 0
        ;;
    --show-cache)
        if [ -f "$CACHE_FILE" ]; then
            echo "Cache ($CACHE_FILE):"
            head -n 1 "$CACHE_FILE"
            tail -n +2 "$CACHE_FILE" | head -20
            total=$(tail -n +2 "$CACHE_FILE" 2>/dev/null | wc -l)
            [ "$total" -gt 20 ] && echo "... (total: $total)"
        else
            echo "No cache."
        fi
        exit 0
        ;;
    --clear-cache)
        rm -f "$CACHE_FILE"
        echo "Cache cleared."
        exit 0
        ;;
    --quiet)
        shift
        QUIET_MODE=1
        ;;
    *)
        # Main logic
        ;;
esac

# Seed random
RANDOM=$(date +%s)

# Declare the global associative array
declare -gA POKEMON_FORMS

# Ensure/load cache with proper args (empty second for full query)
if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
    build_cache "" "" "${QUIET_MODE:-}"
    load_cache "verbose"
else
    load_cache "silent"  # Silent load first to check
    if [ ${#POKEMON_FORMS[@]} -eq 0 ]; then
        echo "Cache exists but has 0 forms. Forcing full rebuild..."
        build_cache "force" "" "${QUIET_MODE:-}"
        load_cache "verbose"
    else
        load_cache "verbose"
    fi
fi

if [ ${#POKEMON_FORMS[@]} -eq 0 ]; then
    echo "Still no forms after rebuild. Run --debug-build 20 to check."
    pokemon-colorscripts --no-title  -r
    exit 0
fi

# Get Pokémon with forms
pokemons_with_forms=("${!POKEMON_FORMS[@]}")

# Random selection (only if forms available)
percent=$((RANDOM % 100))

if [ $percent -lt 50 ]; then
    pokemon-colorscripts --no-title  -r
elif [ $percent -lt 95 ]; then
    random_poke_index=$((RANDOM % ${#pokemons_with_forms[@]}))
    selected_poke="${pokemons_with_forms[$random_poke_index]}"
    forms_list="${POKEMON_FORMS[$selected_poke]}"
    IFS=':' read -ra forms <<< "$forms_list"
    random_form_index=$((RANDOM % ${#forms[@]}))
    selected_form="${forms[$random_form_index]}"
    pokemon-colorscripts --no-title  -n "$selected_poke" -f "$selected_form"
else
    pokemon-colorscripts --no-title -r -s
fi
