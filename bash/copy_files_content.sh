#!/bin/bash

# Function to print usage
print_usage() {
    echo "Usage: $0 [-p PATH] [-e EXTENSIONS] [-s]"
    echo "  -p PATH        Specify the directory path (default: current directory)"
    echo "  -e EXTENSIONS  Comma-separated list of file extensions to include (default: txt,md,cs,js,html,css)"
    echo "  -s             Print output to screen"
    exit 1
}

# Default values
PATH_TO_SEARCH="."
EXTENSIONS="txt,md,cs,js,html,css"
PRINT_TO_SCREEN=false

# Parse command line options
while getopts "p:e:sh" opt; do
    case ${opt} in
        p )
            PATH_TO_SEARCH=$OPTARG
            ;;
        e )
            EXTENSIONS=$OPTARG
            ;;
        s )
            PRINT_TO_SCREEN=true
            ;;
        h )
            print_usage
            ;;
        \? )
            print_usage
            ;;
    esac
done

# Check if the path exists
if [ ! -d "$PATH_TO_SEARCH" ]; then
    echo "Error: The specified path does not exist or is not a directory: $PATH_TO_SEARCH"
    exit 1
fi

# Convert extensions to a format suitable for 'find'
IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
FIND_EXTENSIONS=()
for i in "${EXT_ARRAY[@]}"; do
    FIND_EXTENSIONS+=("-name" "*.$i")
done

# Function to format and output file content
format_output() {
    local file="$1"
    local relative_path="${file#$PATH_TO_SEARCH/}"
    echo "\`\`\`$relative_path"
    cat "$file"
    echo "\`\`\`"
    echo
}

# Process files
output=$(find "$PATH_TO_SEARCH" -type f \( "${FIND_EXTENSIONS[@]}" \) -print0 | 
    while IFS= read -r -d '' file; do
        format_output "$file"
    done
)

# Print to screen if option is set
if $PRINT_TO_SCREEN; then
    echo "$output"
fi

# Copy to clipboard (requires 'pbcopy', which is available on macOS)
echo "$output" | pbcopy

echo "The formatted output has been copied to your clipboard."
if $PRINT_TO_SCREEN; then
    echo "The output has also been printed to the console."
else
    echo "The output was not printed to the console. Use -s to enable console output."
fi

echo
echo "Processed directory: $(cd "$PATH_TO_SEARCH"; pwd)"
echo "Included extensions: $EXTENSIONS"
