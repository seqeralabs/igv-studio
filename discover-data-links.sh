#!/bin/bash

# IGV Studio Data Link Discovery Script
# Scans /workspace/data/ for genomic files and outputs JSON structure

set -e

DATA_DIR="/workspace/data"
OUTPUT_FILE="/tmp/discovered-tracks.json"

echo "Discovering genomic data in Fusion-mounted data links..."

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "No data links found at $DATA_DIR"
    echo '{"tracks": [], "genomes": []}' > "$OUTPUT_FILE"
    exit 0
fi

# Function to determine track type from file extension
get_track_type() {
    local file="$1"
    case "${file,,}" in
        *.bam|*.sam|*.cram)
            echo "alignment"
            ;;
        *.vcf|*.vcf.gz|*.bcf)
            echo "variant"
            ;;
        *.bed|*.bed.gz)
            echo "annotation"
            ;;
        *.gff|*.gff3|*.gtf|*.gff.gz|*.gtf.gz)
            echo "annotation"
            ;;
        *.bw|*.bigwig)
            echo "wig"
            ;;
        *.bb|*.bigbed)
            echo "annotation"
            ;;
        *.wig|*.wig.gz)
            echo "wig"
            ;;
        *.seg)
            echo "seg"
            ;;
        *.mut|*.maf)
            echo "mut"
            ;;
        *)
            echo "annotation"  # Default fallback
            ;;
    esac
}

# Function to check if a file has an index
find_index_file() {
    local data_file="$1"
    local base_name="${data_file%.*}"
    
    # Common index extensions
    local index_extensions=("bai" "tbi" "csi" "idx")
    
    for ext in "${index_extensions[@]}"; do
        if [ -f "${data_file}.${ext}" ]; then
            echo "${data_file}.${ext}"
            return 0
        fi
        if [ -f "${base_name}.${ext}" ]; then
            echo "${base_name}.${ext}"
            return 0
        fi
    done
    
    # Special case for FASTA index
    if [[ "$data_file" == *.fa || "$data_file" == *.fasta ]]; then
        if [ -f "${data_file}.fai" ]; then
            echo "${data_file}.fai"
            return 0
        fi
    fi
    
    return 1
}

# Function to create a human-readable track name
create_track_name() {
    local filepath="$1"
    local datalink="$2"
    
    local filename=$(basename "$filepath")
    local name_without_ext="${filename%.*}"
    
    # Remove common genomics suffixes for cleaner names
    name_without_ext="${name_without_ext%.sorted}"
    name_without_ext="${name_without_ext%.filtered}"
    name_without_ext="${name_without_ext%.dedup}"
    
    # Format: "DataLink - SampleName"
    echo "${datalink} - ${name_without_ext}"
}

# Function to detect if file is a reference genome
is_reference_genome() {
    local file="$1"
    case "${file,,}" in
        *.fa|*.fasta|*.2bit)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Start JSON structure
echo '{"tracks": [], "genomes": [], "userConfigs": []}' > "$OUTPUT_FILE"

# Supported genomic file extensions
TRACK_EXTENSIONS="bam sam cram vcf vcf.gz bcf bed bed.gz gff gff3 gtf gff.gz gtf.gz bw bigwig bb bigbed wig wig.gz seg mut maf"
GENOME_EXTENSIONS="fa fasta 2bit"

echo "Scanning data links..."

# First, look for user-provided IGV config files
echo "Looking for user-provided IGV configurations..."
for datalink_dir in "$DATA_DIR"/*; do
    if [ ! -d "$datalink_dir" ]; then
        continue
    fi
    
    datalink_name=$(basename "$datalink_dir")
    
    # Look for IGV config files (various naming patterns users might use)
    for config_pattern in "igv-config.json" "igvConfig.json" "igv.json" ".igv-config.json" "config/igv.json"; do
        config_file="$datalink_dir/$config_pattern"
        if [ -f "$config_file" ]; then
            echo "Found user IGV config: $config_file"
            
            # Validate JSON and add to user configs
            if jq empty "$config_file" 2>/dev/null; then
                jq --arg source "$datalink_name" \
                   --arg path "$config_file" \
                   '.userConfigs += [{
                     "source": $source,
                     "path": $path,
                     "config": (input)
                   }]' "$OUTPUT_FILE" "$config_file" > /tmp/temp.json && mv /tmp/temp.json "$OUTPUT_FILE"
                echo "  Valid JSON config added from: $datalink_name"
            else
                echo "  Warning: Invalid JSON in $config_file, skipping"
            fi
        fi
    done
done

# Find all data link directories
for datalink_dir in "$DATA_DIR"/*; do
    if [ ! -d "$datalink_dir" ]; then
        continue
    fi
    
    datalink_name=$(basename "$datalink_dir")
    echo "Processing data link: $datalink_name"
    
    # Find genomic data files
    while IFS= read -r -d '' filepath; do
        # Skip hidden files and directories
        [[ "$(basename "$filepath")" =~ ^\. ]] && continue
        
        # Skip index files (they'll be detected automatically)
        case "${filepath,,}" in
            *.bai|*.tbi|*.csi|*.idx|*.fai)
                continue
                ;;
        esac
        
        # Check if it's a reference genome
        if is_reference_genome "$filepath"; then
            echo "Found reference genome: $filepath"
            
            index_file=""
            if index_path=$(find_index_file "$filepath"); then
                index_file="$index_path"
            fi
            
            genome_name=$(create_track_name "$filepath" "$datalink_name")
            
            # Add genome to JSON
            jq --arg id "${datalink_name}-$(basename "${filepath%.*}")" \
               --arg name "$genome_name" \
               --arg fasta "$filepath" \
               --arg index "$index_file" \
               '.genomes += [{
                 "id": $id,
                 "name": $name,
                 "fastaURL": $fasta,
                 "indexURL": ($index | select(length > 0))
               }]' "$OUTPUT_FILE" > /tmp/temp.json && mv /tmp/temp.json "$OUTPUT_FILE"
            continue
        fi
        
        # Process as track
        track_type=$(get_track_type "$filepath")
        track_name=$(create_track_name "$filepath" "$datalink_name")
        
        echo "Found track: $filepath ($track_type)"
        
        # Look for index file
        index_file=""
        if index_path=$(find_index_file "$filepath"); then
            index_file="$index_path"
            echo "  Index found: $index_path"
        fi
        
        # Add track to JSON using jq
        jq --arg name "$track_name" \
           --arg url "$filepath" \
           --arg type "$track_type" \
           --arg index "$index_file" \
           --arg source "$datalink_name" \
           '.tracks += [{
             "name": $name,
             "url": $url,
             "type": $type,
             "indexURL": ($index | select(length > 0)),
             "source": $source,
             "height": (if $type == "alignment" then 300 elif $type == "wig" then 150 else 100 end)
           }]' "$OUTPUT_FILE" > /tmp/temp.json && mv /tmp/temp.json "$OUTPUT_FILE"
        
    done < <(find "$datalink_dir" -type f \( $(printf -- '-name *.%s -o ' $TRACK_EXTENSIONS $GENOME_EXTENSIONS | sed 's/-o $//' ) \) -print0)
done

# Get counts for summary
track_count=$(jq '.tracks | length' "$OUTPUT_FILE")
genome_count=$(jq '.genomes | length' "$OUTPUT_FILE")
config_count=$(jq '.userConfigs | length' "$OUTPUT_FILE")

echo "Discovery complete:"
echo "  Tracks found: $track_count"
echo "  Genomes found: $genome_count"
echo "  User configs found: $config_count"
echo "  Output: $OUTPUT_FILE"

# Pretty print the JSON for debugging (if requested)
if [ "$DEBUG" = "1" ]; then
    echo "Discovered data structure:"
    jq '.' "$OUTPUT_FILE"
fi