#!/bin/bash

# Constants
DATA_DIR="$HOME/.habit-tracker"
DATA_FILE="$DATA_DIR/habits.json"
CONFIG_FILE="$DATA_DIR/config.json"

# Color schemes
declare -A COLORS=(
    ["bg"]="235"
    ["fg"]="223"
    ["red"]="167"
    ["green"]="142"
    ["yellow"]="214"
    ["blue"]="109"
    ["purple"]="175"
)

# declare -A COLORS=(
#     ["bg"]="233"
#     ["fg"]="189"
#     ["red"]="203"
#     ["green"]="108"
#     ["yellow"]="222"
#     ["blue"]="110"
#     ["purple"]="176"
# )

# Ensure data directory exists
mkdir -p "$DATA_DIR"

# Initialize files if they don't exist
if [ ! -f "$DATA_FILE" ]; then
    echo '{"habits":{}}' > "$DATA_FILE"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo '{"theme":"gruvbox"}' > "$CONFIG_FILE"
fi

# Helper functions
generate_id() {
    # Generate random 5-character ID
    cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1
}

get_color() {
    local color=$1
    echo -e "\e[38;5;${COLORS[$color]}m"
}

reset_color() {
    echo -e "\e[0m"
}

convert_to_timestamp() {
    local date_str=$1
    # Try different date formats
    if [[ $date_str =~ ^[0-9]+$ ]]; then
        # Already a timestamp
        echo "$date_str"
    else
        # Try to convert various date formats to timestamp
        date -d "$date_str" +%s 2>/dev/null || {
            echo "Error: Invalid date format. Please use YYYY-MM-DD or timestamp" >&2
            return 1
        }
    fi
}

find_habit_by_prefix() {
    local prefix=$1
    local habits=$(jq -r '.habits | keys[]' "$DATA_FILE")
    local matches=()
    
    # First try to find by name
    local name_match=$(jq -r ".habits | to_entries[] | select(.value.name == \"$prefix\") | .key" "$DATA_FILE")
    if [ ! -z "$name_match" ]; then
        echo "$name_match"
        return 0
    fi
    
    # Then try to find by ID prefix
    for habit in $habits; do
        if [[ $habit == $prefix* ]]; then
            matches+=("$habit")
        fi
    done
    
    if [ ${#matches[@]} -eq 1 ]; then
        echo "${matches[0]}"
    elif [ ${#matches[@]} -gt 1 ]; then
        echo "Multiple matches found: ${matches[*]}" >&2
        return 1
    else
        echo "No matching habit found" >&2
        return 1
    fi
}

get_streak() {
    local habit_id=$1
    local last_relapse=$(jq -r ".habits[\"$habit_id\"].relapses[-1].timestamp // .habits[\"$habit_id\"].start_date" "$DATA_FILE")
    local now=$(date +%s)
    local diff=$((now - last_relapse))
    echo $((diff / 86400)) # Convert to days
}

# Main functions
add_habit() {
    local name=$1
    local start_date=${2:-$(date +%s)}
    
    # Convert date to timestamp
    start_date=$(convert_to_timestamp "$start_date") || return 1
    
    local id=$(generate_id)
    
    # Check if name already exists
    if jq -e ".habits | to_entries[] | select(.value.name == \"$name\")" "$DATA_FILE" >/dev/null; then
        echo "Habit with name '$name' already exists"
        return 1
    fi
    
    local temp_file=$(mktemp)
    jq ".habits[\"$id\"] = {\"name\": \"$name\", \"start_date\": $start_date, \"relapses\": []}" "$DATA_FILE" > "$temp_file"
    mv "$temp_file" "$DATA_FILE"
    
    echo "Added habit '$name' with ID: $id"
}

remove_habit() {
    local id=$(find_habit_by_prefix "$1")
    if [ $? -ne 0 ]; then
        echo "$id"
        return 1
    fi
    
    local temp_file=$(mktemp)
    jq "del(.habits[\"$id\"])" "$DATA_FILE" > "$temp_file"
    mv "$temp_file" "$DATA_FILE"
    
    echo "Removed habit with ID: $id"
}

add_relapse() {
    local id=$(find_habit_by_prefix "$1")
    if [ $? -ne 0 ]; then
        echo "$id"
        return 1
    fi
    
    local timestamp=${2:-$(date +%s)}
    timestamp=$(convert_to_timestamp "$timestamp") || return 1
    
    local temp_file=$(mktemp)
    jq ".habits[\"$id\"].relapses += [{\"timestamp\": $timestamp}]" "$DATA_FILE" > "$temp_file"
    mv "$temp_file" "$DATA_FILE"
    
    echo "Added relapse for habit with ID: $id"
}

show_stats() {
    local id=$1
    
    if [ -z "$id" ]; then
        # Show all habits
        echo "All habits:"
        echo "------------------------"
        jq -r '.habits | to_entries[] | "\(.value.name) (\(.key)): \(.value.start_date)"' "$DATA_FILE" | while read line; do
            local habit_id=$(echo $line | cut -d'(' -f2 | cut -d')' -f1)
            local streak=$(get_streak "$habit_id")
            local start_timestamp=$(jq -r ".habits[\"$habit_id\"].start_date" "$DATA_FILE")
            local start_date=$(date -d "@$start_timestamp" "+%Y-%m-%d")
            echo -e "$(get_color "yellow")$line$(reset_color)"
            echo -e "Start date: $start_date"
            echo -e "Current streak: $(get_color "green")$streak days$(reset_color)"
            echo "------------------------"
        done
    else
        # Show specific habit
        id=$(find_habit_by_prefix "$id")
        if [ $? -ne 0 ]; then
            echo "$id"
            return 1
        fi
        
        local name=$(jq -r ".habits[\"$id\"].name" "$DATA_FILE")
        local start_timestamp=$(jq -r ".habits[\"$id\"].start_date" "$DATA_FILE")
        local start_date=$(date -d "@$start_timestamp" "+%Y-%m-%d")
        local streak=$(get_streak "$id")
        
        echo -e "$(get_color "yellow")$name ($id)$(reset_color)"
        echo "------------------------"
        echo -e "Start date: $start_date"
        echo -e "Current streak: $(get_color "green")$streak days$(reset_color)"
        echo "Relapses:"
        jq -r ".habits[\"$id\"].relapses[] | .timestamp" "$DATA_FILE" | while read timestamp; do
            echo -e "$(get_color "red")- $(date -d "@$timestamp" "+%Y-%m-%d")$(reset_color)"
        done
    fi
}

modify_habit() {
    local id=$(find_habit_by_prefix "$1")
    if [ $? -ne 0 ]; then
        echo "$id"
        return 1
    fi
    
    local name=$2
    local start_date=$3
    
    local temp_file=$(mktemp)
    if [ ! -z "$name" ]; then
        jq ".habits[\"$id\"].name = \"$name\"" "$DATA_FILE" > "$temp_file"
        mv "$temp_file" "$DATA_FILE"
    fi
    
    if [ ! -z "$start_date" ]; then
        start_date=$(convert_to_timestamp "$start_date") || return 1
        jq ".habits[\"$id\"].start_date = $start_date" "$DATA_FILE" > "$temp_file"
        mv "$temp_file" "$DATA_FILE"
    fi
    
    echo "Modified habit with ID: $id"
}

# Help function
show_help() {
    echo "Usage: $(basename $0) [OPTIONS]"
    echo
    echo "Options:"
    echo "  -a, --add NAME [DATE]          Add new habit (DATE format: YYYY-MM-DD)"
    echo "  -r, --remove ID                Remove habit"
    echo "  -m, --modify ID NAME [DATE]    Modify habit"
    echo "  -s, --stats [ID]               Show stats (all or specific habit)"
    echo "  -f, --fail ID [DATE]           Record a relapse"
    echo "  -h, --help                     Show this help"
    echo
    echo "Notes:"
    echo "  - ID can be full ID, habit name, or unique prefix"
    echo "  - Dates should be in YYYY-MM-DD format"
    echo "  - Names should be quoted if they contain spaces"
}

# Main script
case "$1" in
    -a|--add)
        shift
        add_habit "$@"
        ;;
    -r|--remove)
        shift
        remove_habit "$@"
        ;;
    -m|--modify)
        shift
        modify_habit "$@"
        ;;
    -s|--stats)
        shift
        show_stats "$@"
        ;;
    -f|--fail)
        shift
        add_relapse "$@"
        ;;
    -h|--help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
