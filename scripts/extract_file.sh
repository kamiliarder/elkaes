#!/bin/bash

# Script to recursively detect file type and extract until non-compressed file is found
# Uses temporary directory for extraction, only keeps final result

EXTRACTION_COUNT=0
TEMP_DIR=""
ORIGINAL_DIR=$(pwd)
FINAL_FILE=""

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

extract_file() {
    local FILE="$1"
    
    if [ ! -f "$FILE" ]; then
        echo "Error: File '$FILE' not found"
        return 1
    fi
    
    # Detect file type using 'file' command
    FILETYPE=$(file -b "$FILE")
    echo "Processing: $FILE"
    echo "Detected file type: $FILETYPE"
    
    # Check if it's a compressed file type
    case "$FILETYPE" in
        *"Zip archive"*)
            echo "Extracting with unzip..."
            unzip -q "$FILE"
            EXTRACTED=$(unzip -Z1 "$FILE" | head -1)
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"gzip compressed"*)
            echo "Extracting with gunzip..."
            EXTRACTED="${FILE%.gz}"
            gunzip -k "$FILE"
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"bzip2 compressed"*)
            echo "Extracting with bunzip2..."
            EXTRACTED="${FILE%.bz2}"
            bunzip2 -k "$FILE"
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"XZ compressed"*)
            echo "Extracting with unxz..."
            EXTRACTED="${FILE%.xz}"
            unxz -k "$FILE"
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"POSIX tar archive"*|*"tar archive"*)
            echo "Extracting with tar..."
            tar -xf "$FILE"
            EXTRACTED=$(tar -tf "$FILE" | head -1)
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"gzip compressed data"*".tar"*|*"tar.gz"*)
            echo "Extracting tar.gz with tar..."
            tar -xzf "$FILE"
            EXTRACTED=$(tar -tzf "$FILE" | head -1)
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"bzip2 compressed data"*".tar"*|*"tar.bz2"*)
            echo "Extracting tar.bz2 with tar..."
            tar -xjf "$FILE"
            EXTRACTED=$(tar -tjf "$FILE" | head -1)
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"XZ compressed data"*".tar"*|*"tar.xz"*)
            echo "Extracting tar.xz with tar..."
            tar -xJf "$FILE"
            EXTRACTED=$(tar -tJf "$FILE" | head -1)
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"RAR archive"*)
            echo "Extracting with unrar..."
            unrar x -inul "$FILE"
            EXTRACTED=$(unrar lb "$FILE" | head -1)
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *"7-zip archive"*)
            echo "Extracting with 7z..."
            7z x -y "$FILE" > /dev/null
            EXTRACTED=$(7z l -slt "$FILE" | grep "^Path = " | sed -n '2p' | cut -d'=' -f2 | xargs)
            EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
            ;;
        *)
            echo "Not a compressed file. Final file: $FILE"
            echo "File type: $FILETYPE"
            echo ""
            echo "Total extractions: $EXTRACTION_COUNT"
            FINAL_FILE="$FILE"
            return 0
            ;;
    esac
    
    echo "Extracted: $EXTRACTED (Count: $EXTRACTION_COUNT)"
    echo ""
    
    # Recursively process the extracted file
    if [ -n "$EXTRACTED" ] && [ -f "$EXTRACTED" ]; then
        extract_file "$EXTRACTED"
    else
        echo "Extraction complete!"
    fi
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"
echo ""

# Copy input file to temp directory
cp "$INPUT_FILE" "$TEMP_DIR/"
INPUT_BASENAME=$(basename "$INPUT_FILE")

# Change to temp directory
cd "$TEMP_DIR"

# Extract the file
extract_file "$INPUT_BASENAME"

# Move final result back to original directory
if [ -n "$FINAL_FILE" ] && [ -f "$FINAL_FILE" ]; then
    FINAL_BASENAME=$(basename "$FINAL_FILE")
    echo ""
    echo "Moving final result to: $ORIGINAL_DIR/$FINAL_BASENAME"
    mv "$FINAL_FILE" "$ORIGINAL_DIR/"
    echo "Done! Final file: $FINAL_BASENAME"
else
    echo "Warning: No final file found"
fi

cd "$ORIGINAL_DIR"
