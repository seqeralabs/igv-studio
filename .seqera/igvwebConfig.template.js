/**
 * IGV Web App Configuration Template for Seqera Studio
 * 
 * This template provides the base configuration for IGV webapp.
 * It will be dynamically modified by the discovery scripts to include
 * auto-detected genomic data from Fusion-mounted data links.
 */

var igvwebConfig = {
    // Genome configuration
    genomes: "https://s3.amazonaws.com/igv.org.genomes/genomes.json",
    
    // Track registry for pre-defined tracks
    trackRegistryFile: undefined,
    
    // Custom genomes (will be populated by discovery)
    customGenomes: [],
    
    // Data link tracks (will be populated by discovery)
    dataLinkTracks: {},
    
    // Authentication (optional)
    // dropboxAPIKey: "",
    // clientId: "",
    // apiKey: "",
    
    // URL shortener
    urlShortener: {
        provider: "tinyURL"
    },
    
    // Main IGV configuration
    igvConfig: {
        // Default genome
        genome: "hg38",
        
        // Starting locus
        locus: "all",
        
        // Genome list URL
        genomeList: "https://s3.amazonaws.com/igv.org.genomes/genomes.json",
        
        // Query parameters support
        queryParametersSupported: true,
        
        // UI elements
        showChromosomeWidget: true,
        showSVGButton: false,
        showTrackLabelButton: true,
        showCursorTrackingGuide: true,
        showCenterGuide: false,
        
        // Default tracks (will be extended with discovered data)
        tracks: []
    }
};

// Export for CommonJS environments (if needed)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = igvwebConfig;
}