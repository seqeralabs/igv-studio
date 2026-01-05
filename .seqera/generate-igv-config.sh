#!/bin/bash

# IGV Studio Configuration Generator
# Takes discovered data JSON and generates igvwebConfig.js

set -e

DISCOVERED_DATA="${1:-/tmp/discovered-tracks.json}"
TEMPLATE_CONFIG="${2:-/opt/igv-webapp/js/igvwebConfig.template.js}"
OUTPUT_CONFIG="${3:-/opt/igv-webapp/js/igvwebConfig.js}"

echo "Generating IGV configuration..."
echo "  Input: $DISCOVERED_DATA"
echo "  Template: $TEMPLATE_CONFIG"
echo "  Output: $OUTPUT_CONFIG"

# Check if discovered data exists
if [ ! -f "$DISCOVERED_DATA" ]; then
    echo "No discovered data found, using default configuration"
    cp "$TEMPLATE_CONFIG" "$OUTPUT_CONFIG"
    exit 0
fi

# Read discovered data
track_count=$(jq '.tracks | length' "$DISCOVERED_DATA")
genome_count=$(jq '.genomes | length' "$DISCOVERED_DATA")
config_count=$(jq '.userConfigs | length' "$DISCOVERED_DATA")

echo "Processing discovered data:"
echo "  $track_count tracks"
echo "  $genome_count genomes" 
echo "  $config_count user configs"

# Start with template configuration
cp "$TEMPLATE_CONFIG" "$OUTPUT_CONFIG"

# Function to merge user configurations
merge_user_configs() {
    echo "Merging user-provided configurations..."
    
    # Extract and merge each user config
    local config_index=0
    while [ $config_index -lt $config_count ]; do
        local source=$(jq -r ".userConfigs[$config_index].source" "$DISCOVERED_DATA")
        echo "  Merging config from: $source"
        
        # Extract the user config
        local user_config=$(jq ".userConfigs[$config_index].config" "$DISCOVERED_DATA")
        
        # Merge tracks if present in user config
        if echo "$user_config" | jq -e '.tracks' > /dev/null; then
            local user_tracks=$(echo "$user_config" | jq '.tracks')
            # Add source annotation to user tracks
            user_tracks=$(echo "$user_tracks" | jq --arg source "$source" 'map(. + {"source": $source, "userDefined": true})')
            
            # Merge into main config using a temp file approach
            echo "var tempUserTracks = $user_tracks;" >> "$OUTPUT_CONFIG"
            echo "igvwebConfig.igvConfig.tracks = (igvwebConfig.igvConfig.tracks || []).concat(tempUserTracks);" >> "$OUTPUT_CONFIG"
        fi
        
        # Merge genomes if present in user config
        if echo "$user_config" | jq -e '.genomes' > /dev/null; then
            local user_genomes=$(echo "$user_config" | jq '.genomes')
            echo "var tempUserGenomes = $user_genomes;" >> "$OUTPUT_CONFIG"
            echo "igvwebConfig.customGenomes = (igvwebConfig.customGenomes || []).concat(tempUserGenomes);" >> "$OUTPUT_CONFIG"
        fi
        
        # Merge other IGV config properties
        for key in "locus" "showChromosomeWidget" "showSVGButton" "reference"; do
            if echo "$user_config" | jq -e ".$key" > /dev/null; then
                local value=$(echo "$user_config" | jq ".$key")
                echo "if (typeof igvwebConfig.igvConfig.$key === 'undefined') { igvwebConfig.igvConfig.$key = $value; }" >> "$OUTPUT_CONFIG"
            fi
        done
        
        config_index=$((config_index + 1))
    done
}

# Function to add discovered tracks
add_discovered_tracks() {
    if [ $track_count -eq 0 ]; then
        return 0
    fi
    
    echo "Adding discovered tracks..."
    
    # Convert discovered tracks to JavaScript array
    local discovered_tracks=$(jq '.tracks' "$DISCOVERED_DATA")
    
    # Add the tracks to the configuration
    echo "" >> "$OUTPUT_CONFIG"
    echo "// Auto-discovered tracks from Fusion data links" >> "$OUTPUT_CONFIG"
    echo "var discoveredTracks = $discovered_tracks;" >> "$OUTPUT_CONFIG"
    echo "igvwebConfig.igvConfig.tracks = (igvwebConfig.igvConfig.tracks || []).concat(discoveredTracks);" >> "$OUTPUT_CONFIG"
}

# Function to add discovered genomes
add_discovered_genomes() {
    if [ $genome_count -eq 0 ]; then
        return 0
    fi
    
    echo "Adding discovered genomes..."
    
    # Convert discovered genomes to JavaScript array
    local discovered_genomes=$(jq '.genomes' "$DISCOVERED_DATA")
    
    # Add genomes to custom genome list
    echo "" >> "$OUTPUT_CONFIG"
    echo "// Auto-discovered genomes from Fusion data links" >> "$OUTPUT_CONFIG"
    echo "var discoveredGenomes = $discovered_genomes;" >> "$OUTPUT_CONFIG"
    echo "igvwebConfig.customGenomes = (igvwebConfig.customGenomes || []).concat(discoveredGenomes);" >> "$OUTPUT_CONFIG"
}

# Function to create track registry for discovered data
create_track_registry() {
    if [ $track_count -eq 0 ] && [ $config_count -eq 0 ]; then
        return 0
    fi
    
    echo "Creating track registry for data links..."
    
    # Group tracks by source (data link)
    local sources=$(jq -r '[.tracks[].source, .userConfigs[].source] | unique | .[]' "$DISCOVERED_DATA" 2>/dev/null || echo "")
    
    if [ -n "$sources" ]; then
        echo "" >> "$OUTPUT_CONFIG"
        echo "// Data link track registry" >> "$OUTPUT_CONFIG"
        echo "igvwebConfig.dataLinkTracks = {" >> "$OUTPUT_CONFIG"
        
        local first=true
        while IFS= read -r source; do
            [ -z "$source" ] && continue
            
            if [ "$first" = false ]; then
                echo "," >> "$OUTPUT_CONFIG"
            fi
            first=false
            
            echo -n "  \"$source\": {" >> "$OUTPUT_CONFIG"
            echo "    \"label\": \"$source Data\", \"tracks\": [" >> "$OUTPUT_CONFIG"
            
            # Get tracks for this source
            local source_tracks=$(jq --arg source "$source" '[.tracks[] | select(.source == $source)]' "$DISCOVERED_DATA")
            echo "      $source_tracks" | sed 's/^/      /' >> "$OUTPUT_CONFIG"
            
            echo "    ]" >> "$OUTPUT_CONFIG"
            echo -n "  }" >> "$OUTPUT_CONFIG"
            
        done <<< "$sources"
        
        echo "" >> "$OUTPUT_CONFIG"
        echo "};" >> "$OUTPUT_CONFIG"
    fi
}

# Execute the configuration generation steps
echo "Step 1: Merging user configurations"
merge_user_configs

echo "Step 2: Adding discovered tracks"
add_discovered_tracks

echo "Step 3: Adding discovered genomes"
add_discovered_genomes

echo "Step 4: Creating track registry"
create_track_registry

# Add final configuration summary
echo "" >> "$OUTPUT_CONFIG"
echo "// Configuration summary" >> "$OUTPUT_CONFIG"
echo "console.log('IGV Studio loaded with:');" >> "$OUTPUT_CONFIG"
echo "console.log('  Tracks:', (igvwebConfig.igvConfig.tracks || []).length);" >> "$OUTPUT_CONFIG"
echo "console.log('  Custom genomes:', (igvwebConfig.customGenomes || []).length);" >> "$OUTPUT_CONFIG"
echo "console.log('  Data link sources:', Object.keys(igvwebConfig.dataLinkTracks || {}).length);" >> "$OUTPUT_CONFIG"

echo "IGV configuration generated successfully!"
echo "  Total tracks in config: $(jq '[.tracks[] | select(.source)] | length' "$DISCOVERED_DATA" 2>/dev/null || echo "0")"
echo "  Output file: $OUTPUT_CONFIG"