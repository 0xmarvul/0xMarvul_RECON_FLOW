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

# Discord Webhook Configuration
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1451940045475807315/-6ecZ9WRgnY5GS-5iJ_BC0Cdus9L35BpBbIjsYRldmeQvOWYouGbddeTXJvWYKPQz5tg"
NOTIFY_ENABLED=true
START_TIME_EPOCH=$(date +%s)

# Feature flags
ENABLE_DIRSEARCH=false
ENABLE_SECRETFINDER=false
ENABLE_TAKEOVER=false
ENABLE_GF=false
ENABLE_PORT_SCAN=false

# Banner function
show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     ██████╗ ██╗  ██╗███╗   ███╗ █████╗ ██████╗ ██╗   ██╗██╗   ║
║    ██╔═████╗╚██╗██╔╝████╗ ████║██╔══██╗██╔══██╗██║   ██║██║   ║
║    ██║██╔██║ ╚███╔╝ ██╔████╔██║███████║██████╔╝██║   ██║██║   ║
║    ████╔╝██║ ██╔██╗ ██║╚██╔╝██║██╔══██║██╔══██╗╚██╗ ██╔╝██║   ║
║    ╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║██║  ██║██║  ██║ ╚████╔╝ ███████╗║
║     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝║
║                                                               ║
║    ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗               ║
║    ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║               ║
║    ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║               ║
║    ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║               ║
║    ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║               ║
║    ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝               ║
║                                                               ║
║    ███████╗██╗      ██████╗ ██╗    ██╗                       ║
║    ██╔════╝██║     ██╔═══██╗██║    ██║                       ║
║    █████╗  ██║     ██║   ██║██║ █╗ ██║                       ║
║    ██╔══╝  ██║     ██║   ██║██║███╗██║                       ║
║    ██║     ███████╗╚██████╔╝╚███╔███╔╝                       ║
║    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝                        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${BOLD}${GREEN}    [ 0xMarvul RECON FLOW - v1.0 ]${NC}"
    echo -e "${CYAN}    Automated Reconnaissance Tool for Bug Bounty${NC}"
    if [ "$NOTIFY_ENABLED" = true ]; then
        echo -e "${GREEN}    🔔 Discord Notifications: Enabled${NC}"
    else
        echo -e "${YELLOW}    🔕 Discord Notifications: Disabled${NC}"
    fi
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

# Function to get ISO 8601 timestamp for Discord
get_iso_timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# Function to escape JSON strings
escape_json() {
    local str="$1"
    # Escape backslashes, quotes, newlines, tabs, carriage returns, and form feeds
    echo "$str" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\r/\\r/g; s/\f/\\f/g'
}

# Function to send Discord notification
send_discord() {
    if [ "$NOTIFY_ENABLED" = false ]; then
        return 0
    fi
    
    if [ -z "$DISCORD_WEBHOOK" ]; then
        return 0
    fi
    
    local title="$(escape_json "$1")"
    local description="$(escape_json "$2")"
    local color="$3"
    local fields="$4"
    local footer="$(escape_json "$5")"
    
    # Build JSON payload
    local json_payload=$(cat <<EOF
{
  "embeds": [{
    "title": "$title",
    "description": "$description",
    "color": $color,
    "fields": $fields,
    "footer": {"text": "$footer"},
    "timestamp": "$(get_iso_timestamp)"
  }]
}
EOF
)
    
    # Send to Discord webhook
    curl -s -H "Content-Type: application/json" -X POST -d "$json_payload" "$DISCORD_WEBHOOK" > /dev/null 2>&1
}

# Send scan start notification
send_discord_start() {
    local domain="$1"
    local timestamp="$2"
    local domain_escaped="$(escape_json "$domain")"
    local timestamp_escaped="$(escape_json "$timestamp")"
    
    local fields='[
      {"name": "🎯 Target", "value": "'"$domain_escaped"'", "inline": true},
      {"name": "⏰ Started", "value": "'"$timestamp_escaped"'", "inline": true}
    ]'
    
    send_discord "🚀 Scan Started" "Starting reconnaissance on **$domain_escaped**" 255 "$fields" "0xMarvul RECON FLOW"
}

# Send scan completion notification
send_discord_complete() {
    local domain="$1"
    local total_subs="${2:-0}"
    local live_hosts="${3:-0}"
    local total_urls="${4:-0}"
    local js_count="${5:-0}"
    local php_count="${6:-0}"
    local json_count="${7:-0}"
    local bigrac_count="${8:-0}"
    local param_count="${9:-0}"
    local dirsearch_count="${10:-0}"
    local technologies="${11:-N/A}"
    local takeover_count="${12:-0}"
    local secret_count="${13:-0}"
    
    # Calculate duration
    local end_time_epoch=$(date +%s)
    local duration=$((end_time_epoch - START_TIME_EPOCH))
    local duration_min=$((duration / 60))
    local duration_sec=$((duration % 60))
    local duration_str="${duration_min}m ${duration_sec}s"
    
    local domain_escaped="$(escape_json "$domain")"
    local duration_escaped="$(escape_json "$duration_str")"
    local tech_escaped="$(escape_json "$technologies")"
    
    local fields='[
      {"name": "📍 Subdomains", "value": "'"$total_subs"'", "inline": true},
      {"name": "🌐 Live Hosts", "value": "'"$live_hosts"'", "inline": true},
      {"name": "🔗 Total URLs", "value": "'"$total_urls"'", "inline": true},
      {"name": "📜 JavaScript", "value": "'"$js_count"'", "inline": true},
      {"name": "🐘 PHP Files", "value": "'"$php_count"'", "inline": true},
      {"name": "📋 JSON Files", "value": "'"$json_count"'", "inline": true},
      {"name": "🔴 BIGRAC", "value": "'"$bigrac_count"'", "inline": true},
      {"name": "🔍 Parameters", "value": "'"$param_count"'", "inline": true}'
    
    # Add takeover field only if it was run
    if [ "$ENABLE_TAKEOVER" = true ]; then
        fields="$fields"',
      {"name": "🚨 Takeovers", "value": "'"$takeover_count"' found", "inline": true}'
    fi
    
    # Add secrets field only if it was run
    if [ "$ENABLE_SECRETFINDER" = true ]; then
        fields="$fields"',
      {"name": "🔑 Secrets", "value": "'"$secret_count"' found", "inline": true}'
    fi
    
    # Add dirsearch field only if it was run
    if [ "$ENABLE_DIRSEARCH" = true ] && [ "$dirsearch_count" -gt 0 ]; then
        fields="$fields"',
      {"name": "📁 Dirsearch", "value": "'"$dirsearch_count"' found", "inline": true}'
    fi
    
    fields="$fields"',
      {"name": "🔧 Technologies", "value": "'"$tech_escaped"'", "inline": false},
      {"name": "⏱️ Duration", "value": "'"$duration_escaped"'", "inline": true}
    ]'
    
    send_discord "✅ Recon Complete" "Finished scanning **$domain_escaped**" 65280 "$fields" "0xMarvul RECON FLOW"
}

# Send error notification
send_discord_error() {
    local domain="$1"
    local tool_name="$2"
    local error_msg="$3"
    local domain_escaped="$(escape_json "$domain")"
    local tool_escaped="$(escape_json "$tool_name")"
    local error_escaped="$(escape_json "$error_msg")"
    
    local fields='[
      {"name": "🔧 Tool", "value": "'"$tool_escaped"'", "inline": true},
      {"name": "❌ Error", "value": "'"$error_escaped"'", "inline": true}
    ]'
    
    send_discord "⚠️ Tool Error" "An error occurred during scan of **$domain_escaped**" 16711680 "$fields" "Scan will continue with other tools"
}

# Check dependencies
check_dependencies() {
    print_step "Checking Dependencies"
    
    local tools=("subfinder" "assetfinder" "httpx" "gospider" "waybackurls" "katana" "paramspider" "jq" "curl")
    local missing_tools=()
    local optional_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_success "$tool is installed"
        else
            print_warning "$tool is NOT installed"
            missing_tools+=("$tool")
        fi
    done
    
    # Check optional tools
    if [ "$ENABLE_DIRSEARCH" = true ]; then
        if command -v dirsearch &> /dev/null; then
            print_success "dirsearch is installed"
        else
            print_warning "dirsearch is NOT installed (required for -dir flag)"
            optional_tools+=("dirsearch")
        fi
    fi
    
    if [ "$ENABLE_SECRETFINDER" = true ]; then
        if command -v secretfinder &> /dev/null; then
            print_success "secretfinder is installed"
        else
            print_warning "secretfinder is NOT installed (required for -secret flag)"
            optional_tools+=("secretfinder")
        fi
    fi
    
    if [ "$ENABLE_TAKEOVER" = true ]; then
        if command -v subzy &> /dev/null; then
            print_success "subzy is installed"
        else
            print_warning "subzy is NOT installed (required for -takeover flag)"
            optional_tools+=("subzy")
        fi
    fi
    
    if [ "$ENABLE_GF" = true ]; then
        if command -v gf &> /dev/null; then
            print_success "gf is installed"
        else
            print_warning "gf is NOT installed (required for -gf flag)"
            optional_tools+=("gf")
        fi
    fi
    
    if [ "$ENABLE_PORT_SCAN" = true ]; then
        if command -v naabu &> /dev/null; then
            print_success "naabu is installed"
        else
            print_warning "naabu is NOT installed (required for -port flag)"
            optional_tools+=("naabu")
        fi
        if command -v nmap &> /dev/null; then
            print_success "nmap is installed"
        else
            print_warning "nmap is NOT installed (required for -port flag)"
            optional_tools+=("nmap")
        fi
        if command -v dnsx &> /dev/null; then
            print_success "dnsx is installed"
        else
            print_warning "dnsx is NOT installed (required for -port flag)"
            optional_tools+=("dnsx")
        fi
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_warning "Some tools are missing. Script will continue with available tools."
        print_info "Missing tools: ${missing_tools[*]}"
    fi
    
    if [ ${#optional_tools[@]} -gt 0 ]; then
        print_warning "Optional tools missing: ${optional_tools[*]}"
    fi
    
    if [ ${#missing_tools[@]} -eq 0 ] && [ ${#optional_tools[@]} -eq 0 ]; then
        print_success "All dependencies are installed!"
    fi
    
    echo ""
}

# Usage function
usage() {
    echo -e "${YELLOW}Usage: $0 <domain> [options]${NC}"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${CYAN}-dir${NC}              Enable directory bruteforce with dirsearch"
    echo -e "  ${CYAN}-secret${NC}           Enable secret finding in JavaScript files"
    echo -e "  ${CYAN}-takeover${NC}         Enable subdomain takeover check with Subzy"
    echo -e "  ${CYAN}-gf${NC}               Enable GF patterns to filter URLs for vulnerabilities"
    echo -e "  ${CYAN}-port${NC}             Enable port scanning with Naabu and Nmap"
    echo -e "  ${CYAN}--webhook <url>${NC}   Use custom Discord webhook URL"
    echo -e "  ${CYAN}--no-notify${NC}       Disable Discord notifications"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ${CYAN}$0 target.com${NC}"
    echo -e "  ${CYAN}$0 target.com -dir${NC}"
    echo -e "  ${CYAN}$0 target.com -gf${NC}"
    echo -e "  ${CYAN}$0 target.com -secret${NC}"
    echo -e "  ${CYAN}$0 target.com -takeover${NC}"
    echo -e "  ${CYAN}$0 target.com -port${NC}"
    echo -e "  ${CYAN}$0 target.com -dir -gf -secret -takeover -port${NC}"
    echo ""
    exit 1
}

# Main execution
main() {
    # Parse command line arguments
    DOMAIN=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -dir)
                ENABLE_DIRSEARCH=true
                shift
                ;;
            -secret)
                ENABLE_SECRETFINDER=true
                shift
                ;;
            -takeover)
                ENABLE_TAKEOVER=true
                shift
                ;;
            -gf)
                ENABLE_GF=true
                shift
                ;;
            -port)
                ENABLE_PORT_SCAN=true
                shift
                ;;
            --webhook)
                DISCORD_WEBHOOK="$2"
                shift 2
                ;;
            --no-notify)
                NOTIFY_ENABLED=false
                shift
                ;;
            -h|--help)
                show_banner
                usage
                ;;
            *)
                if [ -z "$DOMAIN" ]; then
                    DOMAIN="$1"
                else
                    echo -e "${RED}Error: Unknown argument '$1'${NC}"
                    usage
                fi
                shift
                ;;
        esac
    done
    
    # Clear terminal before starting scan
    clear
    
    show_banner
    
    # Check if domain is provided
    if [ -z "$DOMAIN" ]; then
        print_error "No domain provided!"
        usage
    fi
    
    OUTPUT_DIR="$DOMAIN"
    
    # Capture start time for duration calculation
    START_TIME=$(date +%s)
    
    print_info "Target Domain: ${BOLD}$DOMAIN${NC}"
    print_info "Start Time: $(get_timestamp)"
    
    # Send start notification
    send_discord_start "$DOMAIN" "$(get_timestamp)"
    
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
            send_discord_error "$DOMAIN" "subfinder" "Command execution failed"
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
            send_discord_error "$DOMAIN" "assetfinder" "Command execution failed"
        fi
    else
        print_warning "Assetfinder not installed, skipping..."
    fi
    
    # crt.sh
    if command -v curl &> /dev/null && command -v jq &> /dev/null; then
        print_info "Running crt.sh..."
        crt_response=$(timeout 30 curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" 2>/dev/null)
        
        # Check if response is valid JSON before parsing
        if echo "$crt_response" | jq -e . >/dev/null 2>&1; then
            echo "$crt_response" | jq -r '.[].name_value // empty' | sed 's/^\*\.//' | sort -u > subs_crtsh.txt
            if [ ! -s subs_crtsh.txt ]; then
                print_warning "crt.sh returned no results"
            else
                print_success "crt.sh completed"
            fi
        else
            print_warning "crt.sh returned invalid response, trying alternative..."
            # Alternative: Parse HTML response
            # Escape domain for safe use in regex - escape all special regex characters
            local domain_escaped=$(printf '%s\n' "$DOMAIN" | sed 's/[.[\]*^$()+?{|}\\]/\\&/g')
            if timeout 30 curl -s "https://crt.sh/?q=%25.$DOMAIN" 2>/dev/null | grep -oE '[a-zA-Z0-9._-]+\.'"$domain_escaped" | sort -u > subs_crtsh.txt; then
                if [ ! -s subs_crtsh.txt ]; then
                    print_warning "crt.sh returned no results"
                else
                    print_success "crt.sh completed (via HTML fallback)"
                fi
            else
                print_error "crt.sh failed"
                failed_tools+=("crt.sh")
                send_discord_error "$DOMAIN" "crt.sh" "Connection failed"
            fi
        fi
    else
        print_warning "curl or jq not installed, skipping crt.sh..."
    fi
    
    # Shrewdeye
    if command -v curl &> /dev/null; then
        print_info "Running Shrewdeye..."
        if timeout 30 curl -s "https://shrewdeye.app/domains/$DOMAIN.txt" > subs_shrewdeye.txt 2>/dev/null; then
            if [ ! -s subs_shrewdeye.txt ]; then
                print_warning "Shrewdeye returned no results"
            else
                print_success "Shrewdeye completed"
            fi
        else
            print_error "Shrewdeye failed"
            failed_tools+=("shrewdeye")
            send_discord_error "$DOMAIN" "shrewdeye" "Connection failed"
        fi
    else
        print_warning "curl not installed, skipping Shrewdeye..."
    fi
    
    # Step 2: Aggregate and Deduplicate
    print_step "Step 2: DNS Resolution"
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
    print_step "Step 3: Live Host Check"
    print_info "Timestamp: $(get_timestamp)"
    
    if [ -s all_subs.txt ] && command -v httpx &> /dev/null; then
        print_info "Running httpx..."
        if cat all_subs.txt | httpx -silent -o live_hosts.txt 2>/dev/null; then
            live_hosts=$(wc -l < live_hosts.txt 2>/dev/null || echo 0)
            print_success "httpx completed - Live hosts found: $live_hosts"
        else
            print_error "httpx failed"
            failed_tools+=("httpx")
            send_discord_error "$DOMAIN" "httpx" "Command execution failed"
            live_hosts=0
        fi
    else
        print_warning "httpx not installed or no subdomains, skipping..."
        live_hosts=0
    fi
    
    # Port Scanning (Optional)
    port_count=0
    if [ "$ENABLE_PORT_SCAN" = true ]; then
        print_step "Port Scanning (-port)"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s live_hosts.txt ] && command -v dnsx &> /dev/null && command -v naabu &> /dev/null; then
            print_info "Extracting domains and resolving to IPs..."
            # Step 1: Extract domains & resolve to IPs
            sed 's|https\?://||' live_hosts.txt | cut -d'/' -f1 | sort -u > domains_for_port.txt
            if dnsx -a -resp-only -silent < domains_for_port.txt | sort -u > ips.txt 2>/dev/null; then
                ip_count=$(wc -l < ips.txt 2>/dev/null || echo 0)
                print_success "Resolved $ip_count unique IPs"
                
                if [ "$ip_count" -gt 0 ]; then
                    # Step 2: Fast scan with Naabu (find open ports)
                    print_info "Running Naabu for fast port discovery..."
                    if naabu -l ips.txt -o open_ports.txt 2>/dev/null; then
                        if [ -s open_ports.txt ]; then
                            port_count=$(wc -l < open_ports.txt 2>/dev/null || echo 0)
                            print_success "Naabu completed - Found $port_count open ports"
                            
                            # Step 3: Detailed scan with Nmap (get service names)
                            if command -v nmap &> /dev/null; then
                                print_info "Running Nmap for detailed service detection..."
                                # Extract unique ports and format for nmap
                                port_list=$(cut -d':' -f2 open_ports.txt | sort -u | tr '\n' ',' | sed 's/,$//')
                                if [ -n "$port_list" ]; then
                                    if nmap -iL ips.txt -p "$port_list" -sV -oN ports_detailed.txt 2>/dev/null; then
                                        print_success "Nmap completed - Detailed results saved to ports_detailed.txt"
                                    else
                                        print_warning "Nmap scan failed"
                                    fi
                                else
                                    print_warning "No ports to scan with Nmap"
                                fi
                            else
                                print_warning "Nmap not installed, skipping detailed port scan"
                            fi
                        else
                            print_warning "Naabu completed - No open ports found"
                        fi
                    else
                        print_error "Naabu failed"
                        failed_tools+=("naabu")
                        send_discord_error "$DOMAIN" "naabu" "Command execution failed"
                    fi
                else
                    print_warning "No IPs resolved, skipping port scan"
                fi
            else
                print_error "DNS resolution failed"
                failed_tools+=("dnsx")
                send_discord_error "$DOMAIN" "dnsx" "Command execution failed"
            fi
        else
            if [ ! -s live_hosts.txt ]; then
                print_warning "No live hosts to scan for ports"
            else
                print_warning "dnsx or naabu not installed, skipping port scan..."
            fi
        fi
    fi
    
    # Step 10: Subdomain Takeover Check (Optional)
    takeover_count=0
    if [ "$ENABLE_TAKEOVER" = true ]; then
        print_step "Step 10: Subdomain Takeover (-takeover)"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s live_hosts.txt ] && command -v subzy &> /dev/null; then
            print_info "Running Subzy to check for subdomain takeover..."
            if subzy run --targets live_hosts.txt --hide_fails > takeover_results.txt 2>/dev/null; then
                if [ -s takeover_results.txt ]; then
                    takeover_count=$(grep -c "VULNERABLE" takeover_results.txt 2>/dev/null || echo 0)
                    if [ "$takeover_count" -gt 0 ]; then
                        print_success "Subzy completed - Found $takeover_count potential takeovers!"
                        # Send Discord alert for takeovers found
                        send_discord_error "$DOMAIN" "Subdomain Takeover" "Found $takeover_count vulnerable subdomains!"
                    else
                        print_success "Subzy completed - No takeovers found"
                    fi
                else
                    print_warning "Subzy completed - No results"
                fi
            else
                print_error "Subzy failed"
                failed_tools+=("subzy")
                send_discord_error "$DOMAIN" "subzy" "Command execution failed"
            fi
        else
            if [ ! -s live_hosts.txt ]; then
                print_warning "No live hosts to check for takeover"
            else
                print_warning "Subzy not installed, skipping takeover check..."
            fi
        fi
    fi
    
    # Technology Detection (unnumbered - runs between steps)
    technologies="N/A"
    if [ -s live_hosts.txt ] && command -v httpx &> /dev/null; then
        print_info "Running Tech Detection..."
        if cat live_hosts.txt | httpx -tech-detect -silent -o tech_detect.txt 2>/dev/null; then
            if [ -s tech_detect.txt ]; then
                technologies=$(grep -oP '\[.*?\]' tech_detect.txt 2>/dev/null | tr -d '[]' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g' | head -c 200)
                if [ -z "$technologies" ]; then
                    technologies="N/A"
                fi
                print_success "Tech Detection completed"
                print_info "Technologies detected: $technologies"
            else
                print_success "Tech Detection completed"
            fi
        else
            print_error "Tech Detection failed"
            failed_tools+=("tech-detect")
            send_discord_error "$DOMAIN" "tech-detect" "Command execution failed"
        fi
    else
        if [ ! -s live_hosts.txt ]; then
            print_warning "No live hosts to scan for technologies"
        else
            print_warning "httpx not installed, skipping technology detection..."
        fi
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
                send_discord_error "$DOMAIN" "gospider" "Command execution failed"
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
                send_discord_error "$DOMAIN" "waybackurls" "Command execution failed"
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
                send_discord_error "$DOMAIN" "katana" "Command execution failed"
            fi
        else
            print_warning "Katana not installed, skipping..."
        fi
    else
        print_warning "No live hosts found, skipping URL gathering..."
    fi
    
    # Step 4 continued: Merge URLs
    if [ -f wayback.txt ] || [ -f katana.txt ]; then
        cat wayback.txt katana.txt 2>/dev/null | sort -u > allurls.txt
        total_urls=$(wc -l < allurls.txt 2>/dev/null || echo 0)
        print_success "Total unique URLs collected: $total_urls"
        print_info "Check gospider_output/ directory manually for additional URLs"
    else
        print_warning "No URL files found to merge"
        total_urls=0
    fi
    
    # Step 6: Parameter Discovery
    print_step "Step 6: Parameter Discovery"
    print_info "Timestamp: $(get_timestamp)"
    
    param_count=0
    if command -v paramspider &> /dev/null; then
        print_info "Running ParamSpider..."
        if paramspider -d "$DOMAIN" 2>/dev/null; then
            # ParamSpider saves output to results directory by default
            # Find and move the output file to params.txt
            if [ -f "results/${DOMAIN}.txt" ]; then
                cp "results/${DOMAIN}.txt" params.txt 2>/dev/null
            elif [ -f "output/${DOMAIN}.txt" ]; then
                cp "output/${DOMAIN}.txt" params.txt 2>/dev/null
            fi
            if [ -f params.txt ]; then
                param_count=$(wc -l < params.txt 2>/dev/null || echo 0)
                print_success "ParamSpider completed - Parameters found: $param_count"
            else
                print_success "ParamSpider completed"
            fi
        else
            print_error "ParamSpider failed"
            failed_tools+=("paramspider")
            send_discord_error "$DOMAIN" "paramspider" "Command execution failed"
        fi
    else
        print_warning "ParamSpider not installed, skipping parameter discovery..."
    fi
    
    # Step 5: Filter Specific File Types (JavaScript Extraction)
    print_step "Step 5: JavaScript Extraction"
    print_info "Timestamp: $(get_timestamp)"
    
    if [ -s allurls.txt ]; then
        # JavaScript files
        print_info "Filtering JavaScript files..."
        grep -E "\.js" allurls.txt > javascript.txt 2>/dev/null
        js_count=$(wc -l < javascript.txt 2>/dev/null || echo 0)
        print_success "JavaScript files found: $js_count"
        
        # PHP files
        print_info "Filtering PHP files..."
        grep -E "\.php" allurls.txt > php.txt 2>/dev/null
        php_count=$(wc -l < php.txt 2>/dev/null || echo 0)
        print_success "PHP files found: $php_count"
        
        # JSON files
        print_info "Filtering JSON files..."
        grep -Ei '\.json($|\?|&)' allurls.txt > json.txt 2>/dev/null
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
    
    # Step 9: GF Patterns (Optional)
    if [ "$ENABLE_GF" = true ]; then
        print_step "Step 9: GF Patterns (-gf)"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s allurls.txt ] && command -v gf &> /dev/null; then
            print_info "Running GF patterns on URLs..."
            
            # Create gf output directory
            mkdir -p gf
            
            # Run all patterns
            gf xss < allurls.txt > gf/xss.txt 2>/dev/null
            gf sqli < allurls.txt > gf/sqli.txt 2>/dev/null
            gf ssrf < allurls.txt > gf/ssrf.txt 2>/dev/null
            gf lfi < allurls.txt > gf/lfi.txt 2>/dev/null
            gf redirect < allurls.txt > gf/redirect.txt 2>/dev/null
            gf rce < allurls.txt > gf/rce.txt 2>/dev/null
            gf idor < allurls.txt > gf/idor.txt 2>/dev/null
            gf ssti < allurls.txt > gf/ssti.txt 2>/dev/null
            
            # Count results
            xss_count=$(wc -l < gf/xss.txt 2>/dev/null || echo 0)
            sqli_count=$(wc -l < gf/sqli.txt 2>/dev/null || echo 0)
            ssrf_count=$(wc -l < gf/ssrf.txt 2>/dev/null || echo 0)
            lfi_count=$(wc -l < gf/lfi.txt 2>/dev/null || echo 0)
            redirect_count=$(wc -l < gf/redirect.txt 2>/dev/null || echo 0)
            rce_count=$(wc -l < gf/rce.txt 2>/dev/null || echo 0)
            idor_count=$(wc -l < gf/idor.txt 2>/dev/null || echo 0)
            ssti_count=$(wc -l < gf/ssti.txt 2>/dev/null || echo 0)
            
            print_success "GF Patterns completed:"
            echo -e "    ${GREEN}►${NC} XSS: $xss_count"
            echo -e "    ${GREEN}►${NC} SQLi: $sqli_count"
            echo -e "    ${GREEN}►${NC} SSRF: $ssrf_count"
            echo -e "    ${GREEN}►${NC} LFI: $lfi_count"
            echo -e "    ${GREEN}►${NC} Redirect: $redirect_count"
            echo -e "    ${GREEN}►${NC} RCE: $rce_count"
            echo -e "    ${GREEN}►${NC} IDOR: $idor_count"
            echo -e "    ${GREEN}►${NC} SSTI: $ssti_count"
            
            # Remove empty files
            find gf/ -type f -empty -delete 2>/dev/null
            
        else
            if [ ! -s allurls.txt ]; then
                print_warning "No URLs to filter with GF patterns"
            else
                print_warning "GF not installed, skipping..."
            fi
        fi
    fi
    
    # Step 7: Directory Bruteforce (Optional)
    dirsearch_count=0
    if [ "$ENABLE_DIRSEARCH" = true ]; then
        print_step "Step 7: Directory Bruteforce (-dir)"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s live_hosts.txt ] && command -v dirsearch &> /dev/null; then
            print_info "Running Dirsearch..."
            if [ -f ~/Desktop/WORDLIST/ULTRA_MEGA.txt ]; then
                dirsearch_cmd="dirsearch -l live_hosts.txt -o mar0xwan.txt -w ~/Desktop/WORDLIST/ULTRA_MEGA.txt -i 200 -e conf,config,bak,backup,swp,old,db,sql,asp,aspx,aspx,asp~,py,py~,rb,rb~,php,php~,bak,bkp,cache,cgi,conf,csv,html,inc,jar,js,json,jsp,jsp~,lock,log,rar,old,sql,sql.gz,http://sql.zip,sql.tar.gz,sql~,swp,swp~,tar,tar.bz2,tar.gz,txt,wadl,zip,.log,.xml,.js.,.json 2>/dev/null"
            else
                print_warning "Custom wordlist not found, using default"
                dirsearch_cmd="dirsearch -l live_hosts.txt -o mar0xwan.txt -i 200 2>/dev/null"
            fi
            
            if eval "$dirsearch_cmd"; then
                print_success "Dirsearch completed"
                if [ -f mar0xwan.txt ]; then
                    dirsearch_count=$(grep -c "200" mar0xwan.txt 2>/dev/null || echo 0)
                    print_info "Dirsearch findings (200 status): $dirsearch_count"
                fi
            else
                print_error "Dirsearch failed"
                failed_tools+=("dirsearch")
                send_discord_error "$DOMAIN" "dirsearch" "Command execution failed"
            fi
        else
            if [ ! -s live_hosts.txt ]; then
                print_warning "No live hosts to scan with Dirsearch"
            else
                print_warning "Dirsearch not installed, skipping directory bruteforce..."
            fi
        fi
    fi
    
    # Step 8: Secret Finding (Optional)
    secret_count=0
    if [ "$ENABLE_SECRETFINDER" = true ]; then
        print_step "Step 8: SecretFinder (-secret)"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s javascript.txt ] && command -v secretfinder &> /dev/null; then
            print_info "Running SecretFinder on JavaScript files..."
            
            # Run secretfinder with direct file input (much faster than looping)
            secretfinder -i javascript.txt -o cli > secrets_found.txt 2>/dev/null
            
            if [ -s secrets_found.txt ]; then
                secret_count=$(wc -l < secrets_found.txt 2>/dev/null || echo 0)
                print_success "SecretFinder completed - Found $secret_count potential secrets"
            else
                print_warning "SecretFinder completed - No secrets found"
            fi
        else
            if [ ! -s javascript.txt ]; then
                print_warning "No JavaScript files to scan for secrets"
            else
                print_warning "SecretFinder not installed, skipping..."
            fi
        fi
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
    echo -e "  ${GREEN}►${NC} Parameters discovered: ${BOLD}${param_count:-0}${NC}"
    if [ "$ENABLE_TAKEOVER" = true ]; then
        echo -e "  ${GREEN}►${NC} Subdomain Takeovers: ${BOLD}${takeover_count:-0}${NC}"
    fi
    if [ "$ENABLE_SECRETFINDER" = true ]; then
        echo -e "  ${GREEN}►${NC} Secrets found: ${BOLD}${secret_count:-0}${NC}"
    fi
    if [ "$ENABLE_DIRSEARCH" = true ]; then
        echo -e "  ${GREEN}►${NC} Dirsearch findings: ${BOLD}${dirsearch_count:-0}${NC}"
    fi
    if [ "$ENABLE_PORT_SCAN" = true ]; then
        echo -e "  ${GREEN}►${NC} Open ports found: ${BOLD}${port_count:-0}${NC}"
    fi
    if [ "$ENABLE_GF" = true ]; then
        echo -e "  ${GREEN}►${NC} GF Patterns saved to: ${BOLD}gf/${NC} folder"
    fi
    echo ""
    
    echo -e "${BOLD}${BLUE}Generated Files:${NC}"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_subfinder.txt${NC} - Subdomains from Subfinder"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_assetfinder.txt${NC} - Subdomains from Assetfinder"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_crtsh.txt${NC} - Subdomains from Certificate Transparency logs (crt.sh)"
    echo -e "  ${CYAN}►${NC} ${BOLD}subs_shrewdeye.txt${NC} - Subdomains from Shrewdeye"
    echo -e "  ${CYAN}►${NC} ${BOLD}all_subs.txt${NC} - All unique subdomains combined"
    echo -e "  ${CYAN}►${NC} ${BOLD}live_hosts.txt${NC} - Active/responsive web servers"
    echo -e "  ${CYAN}►${NC} ${BOLD}tech_detect.txt${NC} - Detected technologies (CMS, frameworks, servers)"
    echo -e "  ${CYAN}►${NC} ${BOLD}gospider_output/${NC} - Directory containing crawled URLs from Gospider"
    echo -e "  ${CYAN}►${NC} ${BOLD}wayback.txt${NC} - Historical URLs from Wayback Machine"
    echo -e "  ${CYAN}►${NC} ${BOLD}katana.txt${NC} - URLs discovered by Katana crawler"
    echo -e "  ${CYAN}►${NC} ${BOLD}allurls.txt${NC} - All unique URLs combined (wayback + katana)"
    echo -e "  ${CYAN}►${NC} ${BOLD}params.txt${NC} - Discovered parameters from ParamSpider"
    echo -e "  ${CYAN}►${NC} ${BOLD}javascript.txt${NC} - JavaScript file URLs (potential secrets, endpoints)"
    echo -e "  ${CYAN}►${NC} ${BOLD}php.txt${NC} - PHP file URLs (potential vulnerabilities)"
    echo -e "  ${CYAN}►${NC} ${BOLD}json.txt${NC} - JSON file URLs (API responses, configs)"
    echo -e "  ${CYAN}►${NC} ${BOLD}BIGRAC.txt${NC} - Sensitive files: swagger docs, API docs, configs, .env, SQL dumps, credentials"
    if [ "$ENABLE_TAKEOVER" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}takeover_results.txt${NC} - Subdomain takeover check results from Subzy"
    fi
    if [ "$ENABLE_SECRETFINDER" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}secrets_found.txt${NC} - Secrets found in JavaScript files"
    fi
    if [ "$ENABLE_DIRSEARCH" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}mar0xwan.txt${NC} - Directory bruteforce results from Dirsearch"
    fi
    if [ "$ENABLE_PORT_SCAN" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}open_ports.txt${NC} - Open ports discovered by Naabu"
        echo -e "  ${CYAN}►${NC} ${BOLD}ports_detailed.txt${NC} - Detailed port scan with service detection from Nmap"
    fi
    if [ "$ENABLE_GF" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}gf/${NC} - Folder containing GF pattern results (xss.txt, sqli.txt, ssrf.txt, etc.)"
    fi
    echo ""
    
    if [ ${#failed_tools[@]} -gt 0 ]; then
        echo -e "${BOLD}${RED}Failed/Skipped Tools:${NC}"
        for tool in "${failed_tools[@]}"; do
            echo -e "  ${RED}✗${NC} $tool"
        done
        echo ""
    fi
    
    # Discord End Notification
    if [ -n "$DISCORD_WEBHOOK" ] && [ "$NOTIFY_ENABLED" = true ]; then
        END_TIME=$(date +%s)
        DURATION_SEC=$((END_TIME - START_TIME))
        DURATION_MIN=$((DURATION_SEC / 60))
        DURATION_REMAIN=$((DURATION_SEC % 60))
        
        # Build the Discord message with each stat on separate lines
        local discord_msg="Finished scanning $DOMAIN
📍 Subdomains
$(wc -l < all_subs.txt 2>/dev/null || echo 0)
🌐 Live Hosts
$(wc -l < live_hosts.txt 2>/dev/null || echo 0)
🔗 Total URLs
$(wc -l < allurls.txt 2>/dev/null || echo 0)
📜 JavaScript
$(wc -l < javascript.txt 2>/dev/null || echo 0)
🐘 PHP Files
$(grep -c '\.php' allurls.txt 2>/dev/null || echo 0)
📋 JSON Files
$(grep -c '\.json' allurls.txt 2>/dev/null || echo 0)
🔍 Parameters
$(wc -l < params.txt 2>/dev/null || echo 0)"

        # Add optional sections only if they were enabled
        if [ "$ENABLE_DIRSEARCH" = true ]; then
            local dirsearch_count_local=$(grep -c "200" mar0xwan.txt 2>/dev/null || echo 0)
            if [ "$dirsearch_count_local" -gt 0 ]; then
                discord_msg="${discord_msg}
📁 Dirsearch
${dirsearch_count_local} found"
            fi
        fi
        
        if [ "$ENABLE_PORT_SCAN" = true ]; then
            local port_count_local=$(wc -l < open_ports.txt 2>/dev/null || echo 0)
            if [ "$port_count_local" -gt 0 ]; then
                discord_msg="${discord_msg}
🔌 Open Ports
${port_count_local}"
            fi
        fi
        
        if [ "$ENABLE_SECRETFINDER" = true ]; then
            local secret_count_local=$(wc -l < secrets_found.txt 2>/dev/null || echo 0)
            if [ "$secret_count_local" -gt 0 ]; then
                discord_msg="${discord_msg}
🔑 Secrets
${secret_count_local}"
            fi
        fi
        
        discord_msg="${discord_msg}
⏱️ Duration
${DURATION_MIN}m ${DURATION_REMAIN}s"
        
        send_discord "✅ Recon Complete" "$discord_msg" 65280 "[]" "0xMarvul RECON FLOW"
    fi
    
    print_success "Reconnaissance completed!"
    echo -e "${CYAN}All output files saved in: ${BOLD}$OUTPUT_DIR/${NC}\n"
}

# Run main function
main "$@"
