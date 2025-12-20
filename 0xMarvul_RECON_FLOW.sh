#!/bin/bash

# ============================================
#  0xMarvul RECON FLOW - Reconnaissance Tool
#  Author: 0xMarvul
#  Description: Automated reconnaissance tool for bug bounty and security assessments
# ============================================

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Banner function
show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
 _____ _   ____  __                      _
|  _  |_|_|    \|  | ___ ___ _ _ _ ___ _| |
| |   |_'_| |  |     |_ -|  _| | | | . | . |
|__|__|_,_|____|__|__|___|___|_  |_|  _|___|
                              |___|_|

    ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗
    ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║
    ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║
    ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║
    ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║
    ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝

    ███████╗██╗      ██████╗ ██╗    ██╗
    ██╔════╝██║     ██╔═══██╗██║    ██║
    █████╗  ██║     ██║   ██║██║ █╗ ██║
    ██╔══╝  ██║     ██║   ██║██║███╗██║
    ██║     ███████╗╚██████╔╝╚███╔███╔╝
    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝

EOF
    echo -e "${BOLD}${GREEN}    [ 0xMarvul RECON FLOW - v1.0 ]${NC}"
    echo -e "${CYAN}    Automated Reconnaissance Tool for Bug Bounty${NC}"
    echo -e "${CYAN}    ===========================================${NC}\n"
}

# Function to print messages with colors
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_info() {
    echo -e "${CYAN}[*] $1${NC}"
}

print_step() {
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}[STEP] $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════${NC}\n"
}

# Function to get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Check dependencies
check_dependencies() {
    print_step "Checking Dependencies"
    
    local tools=("subfinder" "assetfinder" "httpx" "gospider" "waybackurls" "katana" "jq" "curl")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_success "$tool is installed"
        else
            print_warning "$tool is NOT installed"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_warning "Some tools are missing. Script will continue with available tools."
        print_info "Missing tools: ${missing_tools[*]}"
    else
        print_success "All dependencies are installed!"
    fi
    
    echo ""
}

# Usage function
usage() {
    echo -e "${YELLOW}Usage: $0 <domain>${NC}"
    echo -e "${CYAN}Example: $0 target.com${NC}"
    exit 1
}

# Main execution
main() {
    show_banner
    
    # Check if domain is provided
    if [ $# -eq 0 ]; then
        print_error "No domain provided!"
        usage
    fi
    
    DOMAIN=$1
    OUTPUT_DIR="$DOMAIN"
    
    print_info "Target Domain: ${BOLD}$DOMAIN${NC}"
    print_info "Start Time: $(get_timestamp)"
    
    # Check dependencies
    check_dependencies
    
    # Create output directory
    print_step "Creating Output Directory"
    if [ -d "$OUTPUT_DIR" ]; then
        print_warning "Directory $OUTPUT_DIR already exists"
        read -p "Do you want to continue? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Exiting..."
            exit 1
        fi
    else
        mkdir -p "$OUTPUT_DIR"
        print_success "Created directory: $OUTPUT_DIR"
    fi
    
    cd "$OUTPUT_DIR" || exit 1
    
    # Array to track failed tools
    failed_tools=()
    
    # Step 1: Subdomain Enumeration
    print_step "Step 1: Subdomain Enumeration"
    print_info "Timestamp: $(get_timestamp)"
    
    # Subfinder
    if command -v subfinder &> /dev/null; then
        print_info "Running Subfinder..."
        if subfinder -d "$DOMAIN" -o subs_subfinder.txt 2>/dev/null; then
            print_success "Subfinder completed"
        else
            print_error "Subfinder failed"
            failed_tools+=("subfinder")
        fi
    else
        print_warning "Subfinder not installed, skipping..."
    fi
    
    # Assetfinder
    if command -v assetfinder &> /dev/null; then
        print_info "Running Assetfinder..."
        if assetfinder --subs-only "$DOMAIN" > subs_assetfinder.txt 2>/dev/null; then
            print_success "Assetfinder completed"
        else
            print_error "Assetfinder failed"
            failed_tools+=("assetfinder")
        fi
    else
        print_warning "Assetfinder not installed, skipping..."
    fi
    
    # crt.sh
    if command -v curl &> /dev/null && command -v jq &> /dev/null; then
        print_info "Querying crt.sh..."
        if timeout 30 curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" | jq -r '.[].name_value' | sort -u > subs_crtsh.txt 2>/dev/null; then
            if [ -s subs_crtsh.txt ]; then
                print_success "crt.sh query completed"
            else
                print_error "crt.sh returned no results or timed out"
                failed_tools+=("crt.sh")
            fi
        else
            print_error "crt.sh query failed or timed out"
            failed_tools+=("crt.sh")
        fi
    else
        print_warning "curl or jq not installed, skipping crt.sh..."
    fi
    
    # Shrewdeye
    if command -v curl &> /dev/null; then
        print_info "Querying Shrewdeye..."
        if timeout 30 curl -s "https://shrewdeye.app/domains/$DOMAIN.txt" > subs_shrewdeye.txt 2>/dev/null; then
            if [ -s subs_shrewdeye.txt ]; then
                print_success "Shrewdeye query completed"
            else
                print_warning "Shrewdeye returned no results"
            fi
        else
            print_error "Shrewdeye query failed"
            failed_tools+=("shrewdeye")
        fi
    else
        print_warning "curl not installed, skipping Shrewdeye..."
    fi
    
    # Step 2: Aggregate and Deduplicate
    print_step "Step 2: Aggregating and Deduplicating Subdomains"
    print_info "Timestamp: $(get_timestamp)"
    
    if ls subs_*.txt 1> /dev/null 2>&1; then
        cat subs_*.txt 2>/dev/null | sort -u > all_subs.txt
        total_subs=$(wc -l < all_subs.txt)
        print_success "Total unique subdomains found: $total_subs"
    else
        print_error "No subdomain files found"
        total_subs=0
    fi
    
    # Step 3: Check for Live Web Servers
    print_step "Step 3: Checking for Live Web Servers"
    print_info "Timestamp: $(get_timestamp)"
    
    if [ -s all_subs.txt ] && command -v httpx &> /dev/null; then
        print_info "Running httpx to find live hosts..."
        if cat all_subs.txt | httpx -silent -o live_hosts.txt 2>/dev/null; then
            live_hosts=$(wc -l < live_hosts.txt 2>/dev/null || echo 0)
            print_success "Live hosts found: $live_hosts"
        else
            print_error "httpx failed"
            failed_tools+=("httpx")
            live_hosts=0
        fi
    else
        if [ ! -s all_subs.txt ]; then
            print_warning "No subdomains to check for live hosts"
        else
            print_warning "httpx not installed, skipping live host check..."
        fi
        live_hosts=0
    fi
    
    # Step 4: URL Gathering
    print_step "Step 4: URL Gathering"
    print_info "Timestamp: $(get_timestamp)"
    
    if [ -s live_hosts.txt ]; then
        # Gospider
        if command -v gospider &> /dev/null; then
            print_info "Running Gospider..."
            if gospider -S live_hosts.txt -o gospider_output --quiet 2>/dev/null; then
                print_success "Gospider completed"
                print_info "Gospider output saved in gospider_output/ directory"
            else
                print_error "Gospider failed"
                failed_tools+=("gospider")
            fi
        else
            print_warning "Gospider not installed, skipping..."
        fi
        
        # Waybackurls
        if command -v waybackurls &> /dev/null; then
            print_info "Running Waybackurls..."
            if cat live_hosts.txt | waybackurls > wayback.txt 2>/dev/null; then
                print_success "Waybackurls completed"
            else
                print_error "Waybackurls failed"
                failed_tools+=("waybackurls")
            fi
        else
            print_warning "Waybackurls not installed, skipping..."
        fi
        
        # Katana
        if command -v katana &> /dev/null; then
            print_info "Running Katana..."
            if katana -list live_hosts.txt -o katana.txt -silent 2>/dev/null; then
                print_success "Katana completed"
            else
                print_error "Katana failed"
                failed_tools+=("katana")
            fi
        else
            print_warning "Katana not installed, skipping..."
        fi
    else
        print_warning "No live hosts found, skipping URL gathering..."
    fi
    
    # Step 5: Merge URLs
    print_step "Step 5: Merging URLs"
    print_info "Timestamp: $(get_timestamp)"
    
    if [ -f wayback.txt ] || [ -f katana.txt ]; then
        cat wayback.txt katana.txt 2>/dev/null | sort -u > allurls.txt
        total_urls=$(wc -l < allurls.txt 2>/dev/null || echo 0)
        print_success "Total unique URLs collected: $total_urls"
        print_info "Check gospider_output/ directory manually for additional URLs"
    else
        print_warning "No URL files found to merge"
        total_urls=0
    fi
    
    # Step 6: Filter Specific File Types
    print_step "Step 6: Filtering Specific File Types"
    print_info "Timestamp: $(get_timestamp)"
    
    if [ -s allurls.txt ]; then
        # JavaScript files
        print_info "Filtering JavaScript files..."
        grep -E "\.js" allurls.txt >> javascript.txt 2>/dev/null
        js_count=$(wc -l < javascript.txt 2>/dev/null || echo 0)
        print_success "JavaScript files found: $js_count"
        
        # PHP files
        print_info "Filtering PHP files..."
        grep -E "\.php" allurls.txt >> php.txt 2>/dev/null
        php_count=$(wc -l < php.txt 2>/dev/null || echo 0)
        print_success "PHP files found: $php_count"
        
        # JSON files
        print_info "Filtering JSON files..."
        grep -Ei '\.json($|\?|&)' allurls.txt >> json.txt 2>/dev/null
        json_count=$(wc -l < json.txt 2>/dev/null || echo 0)
        print_success "JSON files found: $json_count"
        
        # BIGRAC - Sensitive files
        print_info "Filtering BIGRAC (sensitive files)..."
        grep -Ei '/(swagger|openapi|api-docs|v2\/api-docs|swagger-resources)(\.json|/|$|\?)|\b(json|config|metadata|schema|manifest|openapi|swagger)(\.json|\.yaml|\.yml)?(\?|$|/)|\.(yaml|yml)($|\?|&)|(/|^)(package|config|composer|manifest)\.json($|\?|&)|/(\.env|env|config\.php|db\.sql|dump\.sql|backup|\.htpasswd|credentials|robots\.txt)$' allurls.txt | sort -u > BIGRAC.txt 2>/dev/null
        bigrac_count=$(wc -l < BIGRAC.txt 2>/dev/null || echo 0)
        print_success "BIGRAC sensitive files found: $bigrac_count"
    else
        print_warning "No URLs to filter"
    fi
    
    # Final Summary
    print_step "FINAL SUMMARY"
    print_info "End Time: $(get_timestamp)"
    echo ""
    
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║               RECONNAISSANCE SUMMARY                      ║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}Target Domain:${NC} ${BOLD}$DOMAIN${NC}"
    echo -e "${CYAN}Output Directory:${NC} ${BOLD}$OUTPUT_DIR${NC}"
    echo ""
    
    echo -e "${BOLD}${BLUE}Statistics:${NC}"
    echo -e "  ${GREEN}►${NC} Total Subdomains: ${BOLD}${total_subs:-0}${NC}"
    echo -e "  ${GREEN}►${NC} Live Hosts: ${BOLD}${live_hosts:-0}${NC}"
    echo -e "  ${GREEN}►${NC} Total URLs: ${BOLD}${total_urls:-0}${NC}"
    echo -e "  ${GREEN}►${NC} JavaScript files: ${BOLD}${js_count:-0}${NC}"
    echo -e "  ${GREEN}►${NC} PHP files: ${BOLD}${php_count:-0}${NC}"
    echo -e "  ${GREEN}►${NC} JSON files: ${BOLD}${json_count:-0}${NC}"
    echo -e "  ${GREEN}►${NC} BIGRAC sensitive files: ${BOLD}${bigrac_count:-0}${NC}"
    echo ""
    
    echo -e "${BOLD}${BLUE}Generated Files:${NC}"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_subfinder.txt${NC} - Subdomains from Subfinder"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_assetfinder.txt${NC} - Subdomains from Assetfinder"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_crtsh.txt${NC} - Subdomains from Certificate Transparency logs (crt.sh)"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_shrewdeye.txt${NC} - Subdomains from Shrewdeye"
    echo -e "  ${CYAN}►${NC} ${BOLD}all_subs.txt${NC} - All unique subdomains combined"
    echo -e "  ${CYAN}►${NC} ${BOLD}live_hosts.txt${NC} - Active/responsive web servers"
    echo -e "  ${CYAN}►${NC} ${BOLD}gospider_output/${NC} - Directory containing crawled URLs from Gospider"
    echo -e "  ${CYAN}►${NC} ${BOLD}wayback.txt${NC} - Historical URLs from Wayback Machine"
    echo -e "  ${CYAN}►${NC} ${BOLD}katana.txt${NC} - URLs discovered by Katana crawler"
    echo -e "  ${CYAN}►${NC} ${BOLD}allurls.txt${NC} - All unique URLs combined (wayback + katana)"
    echo -e "  ${CYAN}►${NC} ${BOLD}javascript.txt${NC} - JavaScript file URLs (potential secrets, endpoints)"
    echo -e "  ${CYAN}►${NC} ${BOLD}php.txt${NC} - PHP file URLs (potential vulnerabilities)"
    echo -e "  ${CYAN}►${NC} ${BOLD}json.txt${NC} - JSON file URLs (API responses, configs)"
    echo -e "  ${CYAN}►${NC} ${BOLD}BIGRAC.txt${NC} - Sensitive files: swagger docs, API docs, configs, .env, SQL dumps, credentials"
    echo ""
    
    if [ ${#failed_tools[@]} -gt 0 ]; then
        echo -e "${BOLD}${RED}Failed/Skipped Tools:${NC}"
        for tool in "${failed_tools[@]}"; do
            echo -e "  ${RED}✗${NC} $tool"
        done
        echo ""
    fi
    
    print_success "Reconnaissance completed!"
    echo -e "${CYAN}All output files saved in: ${BOLD}$OUTPUT_DIR/${NC}\n"
}

# Run main function
main "$@"
