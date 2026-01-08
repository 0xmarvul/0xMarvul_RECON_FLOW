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
ENABLE_PARALLEL=false
ENABLE_MOREURLS=false
ENABLE_GREP=false
COMPARE_MODE=false

# Skip functionality variables
CURRENT_TOOL_PID=""
CURRENT_TOOL_NAME=""

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

# Print skip hint
print_skip_hint() {
    echo -e "    ${YELLOW}(Press ENTER to skip...)${NC}"
}

# Run a command with skip support
run_with_skip() {
    local tool_name="$1"
    shift
    local cmd="$@"
    
    CURRENT_TOOL_NAME="$tool_name"
    
    # Run the command in background
    eval "$cmd" &
    CURRENT_TOOL_PID=$!
    
    # Monitor for ENTER key or process completion
    while kill -0 "$CURRENT_TOOL_PID" 2>/dev/null; do
        # Check for ENTER key (non-blocking read with short timeout)
        if read -t 0.5 -n 1 key 2>/dev/null; then
            if [[ -z "$key" ]]; then  # ENTER key (empty when read with -n 1)
                kill "$CURRENT_TOOL_PID" 2>/dev/null
                wait "$CURRENT_TOOL_PID" 2>/dev/null
                print_warning "Skipped: $CURRENT_TOOL_NAME (user interrupted) - partial results saved"
                CURRENT_TOOL_PID=""
                CURRENT_TOOL_NAME=""
                return 2  # Return special code for skip
            fi
        fi
    done
    
    # Get exit code
    wait "$CURRENT_TOOL_PID"
    local exit_code=$?
    CURRENT_TOOL_PID=""
    CURRENT_TOOL_NAME=""
    return $exit_code
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

# Function to find latest compare folder
find_latest_compare() {
    local target_dir="$1"
    local compare_dir="$target_dir/compare"
    
    if [ ! -d "$compare_dir" ]; then
        # No compare folder exists, compare with original
        echo "$target_dir"
        return
    fi
    
    # Find highest numbered compare folder
    local latest=$(ls -d "$compare_dir"/compare_* 2>/dev/null | sort -t_ -k2 -n | tail -1)
    
    if [ -z "$latest" ]; then
        echo "$target_dir"
    else
        echo "$latest"
    fi
}

# Function to get next compare number
get_next_compare_number() {
    local target_dir="$1"
    local compare_dir="$target_dir/compare"
    
    if [ ! -d "$compare_dir" ]; then
        echo "1"
        return
    fi
    
    local latest=$(ls -d "$compare_dir"/compare_* 2>/dev/null | sort -t_ -k2 -n | tail -1)
    
    if [ -z "$latest" ]; then
        echo "1"
    else
        local num=$(basename "$latest" | sed 's/compare_//')
        echo $((num + 1))
    fi
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
        if command -v nuclei &> /dev/null; then
            print_success "nuclei is installed"
            # Check if takeover templates exist
            if [ -d "$HOME/nuclei-templates/http/takeovers" ]; then
                print_success "nuclei takeover templates found"
            else
                print_warning "nuclei takeover templates not found at ~/nuclei-templates/http/takeovers"
                print_info "Run: nuclei -update-templates"
            fi
        else
            print_warning "nuclei is NOT installed (required for -takeover flag)"
            optional_tools+=("nuclei")
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
    
    if [ "$ENABLE_MOREURLS" = true ]; then
        if command -v gau &> /dev/null; then
            print_success "gau is installed"
        else
            print_warning "gau is NOT installed (required for -moreurls flag)"
            optional_tools+=("gau")
        fi
        if command -v hakrawler &> /dev/null; then
            print_success "hakrawler is installed"
        else
            print_warning "hakrawler is NOT installed (required for -moreurls flag)"
            optional_tools+=("hakrawler")
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
    echo -e "  ${CYAN}-parallel${NC}         Run subdomain enumeration tools in parallel (faster)"
    echo -e "  ${CYAN}-moreurls${NC}         Enable extra URL gathering with GAU and Hakrawler"
    echo -e "  ${CYAN}-dir${NC}              Enable directory bruteforce with dirsearch"
    echo -e "  ${CYAN}-secret${NC}           Enable secret finding in JavaScript files"
    echo -e "  ${CYAN}-takeover${NC}         Enable subdomain takeover check with Nuclei"
    echo -e "  ${CYAN}-gf${NC}               Enable GF patterns to filter URLs for vulnerabilities"
    echo -e "  ${CYAN}-port${NC}             Enable port scanning with Naabu and Nmap"
    echo -e "  ${CYAN}-grep${NC}             Extract juicy URLs by keywords (configs, backups, secrets, etc.)"
    echo -e "  ${CYAN}-compare${NC}          Compare subdomains with previous scan (subdomain enum + live check only)"
    echo -e "  ${CYAN}--webhook <url>${NC}   Use custom Discord webhook URL"
    echo -e "  ${CYAN}--no-notify${NC}       Disable Discord notifications"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ${CYAN}$0 target.com${NC}"
    echo -e "  ${CYAN}$0 target.com -parallel${NC}"
    echo -e "  ${CYAN}$0 target.com -moreurls${NC}"
    echo -e "  ${CYAN}$0 target.com -parallel -moreurls${NC}"
    echo -e "  ${CYAN}$0 target.com -dir${NC}"
    echo -e "  ${CYAN}$0 target.com -gf${NC}"
    echo -e "  ${CYAN}$0 target.com -grep${NC}"
    echo -e "  ${CYAN}$0 target.com -gf -grep${NC}"
    echo -e "  ${CYAN}$0 target.com -secret${NC}"
    echo -e "  ${CYAN}$0 target.com -takeover${NC}"
    echo -e "  ${CYAN}$0 target.com -port${NC}"
    echo -e "  ${CYAN}$0 target.com -compare${NC}"
    echo -e "  ${CYAN}$0 target.com -parallel -moreurls -dir -gf${NC}"
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
            -parallel)
                ENABLE_PARALLEL=true
                shift
                ;;
            -moreurls)
                ENABLE_MOREURLS=true
                shift
                ;;
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
            -grep)
                ENABLE_GREP=true
                shift
                ;;
            -compare)
                COMPARE_MODE=true
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
    
    # Set up cleanup trap
    trap 'exit' INT TERM EXIT
    
    # Array to track failed tools
    failed_tools=()
    
    # Step 1: Subdomain Enumeration
    print_step "Step 1: Subdomain Enumeration"
    print_info "Timestamp: $(get_timestamp)"
    
    if [ "$ENABLE_PARALLEL" = true ]; then
        print_info "Running subdomain enumeration in parallel mode..."
        
        # Start all tools in background
        if command -v subfinder &> /dev/null; then
            subfinder -d "$DOMAIN" -o subs_subfinder.txt 2>/dev/null &
            pid_subfinder=$!
        fi
        
        if command -v assetfinder &> /dev/null; then
            assetfinder --subs-only "$DOMAIN" > subs_assetfinder.txt 2>/dev/null &
            pid_assetfinder=$!
        fi
        
        # crt.sh with timeout
        if command -v curl &> /dev/null && command -v jq &> /dev/null; then
            (timeout 30 curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" 2>/dev/null | jq -r '.[].name_value // empty' 2>/dev/null | sed 's/^\*\.//' | sort -u > subs_crtsh.txt) &
            pid_crtsh=$!
        fi
        
        # shrewdeye with timeout
        if command -v curl &> /dev/null; then
            (timeout 30 curl -s "https://shrewdeye.app/domains/$DOMAIN.txt" > subs_shrewdeye.txt 2>/dev/null) &
            pid_shrewdeye=$!
        fi
        
        # Wait for all to complete
        print_info "Waiting for all subdomain tools to complete..."
        if [ -n "${pid_subfinder:-}" ]; then
            if wait $pid_subfinder 2>/dev/null; then
                print_success "Subfinder completed"
            else
                print_warning "Subfinder failed or not installed"
                failed_tools+=("subfinder")
                send_discord_error "$DOMAIN" "subfinder" "Command execution failed"
            fi
        else
            print_warning "Subfinder not installed, skipping..."
        fi
        
        if [ -n "${pid_assetfinder:-}" ]; then
            if wait $pid_assetfinder 2>/dev/null; then
                print_success "Assetfinder completed"
            else
                print_warning "Assetfinder failed or not installed"
                failed_tools+=("assetfinder")
                send_discord_error "$DOMAIN" "assetfinder" "Command execution failed"
            fi
        else
            print_warning "Assetfinder not installed, skipping..."
        fi
        
        if [ -n "${pid_crtsh:-}" ]; then
            if wait $pid_crtsh 2>/dev/null; then
                print_success "crt.sh completed"
            else
                print_warning "crt.sh failed"
                failed_tools+=("crt.sh")
                send_discord_error "$DOMAIN" "crt.sh" "Connection failed"
            fi
        else
            print_warning "curl or jq not installed, skipping crt.sh..."
        fi
        
        if [ -n "${pid_shrewdeye:-}" ]; then
            if wait $pid_shrewdeye 2>/dev/null; then
                print_success "Shrewdeye completed"
            else
                print_warning "Shrewdeye failed"
                failed_tools+=("shrewdeye")
                send_discord_error "$DOMAIN" "shrewdeye" "Connection failed"
            fi
        else
            print_warning "curl not installed, skipping Shrewdeye..."
        fi
        
        print_success "Parallel subdomain enumeration completed!"
    else
        # Sequential mode (existing code)
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
                # Using ] at start of character class so it doesn't need escaping
                local domain_escaped=$(printf '%s\n' "$DOMAIN" | sed 's/[][\\.*^$()+?{|}]/\\&/g')
                if timeout 30 curl -s "https://crt.sh/?q=%25.$DOMAIN" 2>/dev/null | grep -oE "[a-zA-Z0-9._-]+\\.$domain_escaped" | sort -u > subs_crtsh.txt; then
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
    fi
    
    # Step 2: Aggregate and Deduplicate
    print_step "Step 2: DNS Resolution"
    print_info "Timestamp: $(get_timestamp)"
    
    if ls subs_*.txt 1> /dev/null 2>&1; then
        cat subs_*.txt 2>/dev/null | sort -u > all_subs.txt
        total_subs=$(wc -l < all_subs.txt)
        print_success "Total unique subdomains found: $total_subs"
        
        # Save as subdomains.txt for future comparisons (only if not in compare mode)
        if [ "$COMPARE_MODE" = false ]; then
            cp all_subs.txt subdomains.txt
        fi
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
    
    # Compare Mode Logic
    if [ "$COMPARE_MODE" = true ]; then
        print_step "Compare Mode - Analyzing Changes"
        print_info "Timestamp: $(get_timestamp)"
        
        # Check if previous scan exists
        if [ ! -f "$OUTPUT_DIR/subdomains.txt" ]; then
            print_error "No previous scan found for $DOMAIN. Run a normal scan first."
            exit 1
        fi
        
        # Find previous directory and get next compare number
        previous_dir=$(find_latest_compare "$OUTPUT_DIR")
        compare_num=$(get_next_compare_number "$OUTPUT_DIR")
        compare_output_dir="$OUTPUT_DIR/compare/compare_$compare_num"
        
        # Create compare directory
        mkdir -p "$compare_output_dir"
        print_info "Creating compare directory: compare_$compare_num"
        
        # Get previous subdomains file
        if [ "$previous_dir" = "$OUTPUT_DIR" ]; then
            previous_subs="$previous_dir/subdomains.txt"
        else
            previous_subs="$previous_dir/all_subdomains.txt"
        fi
        
        # Check if previous file exists
        if [ ! -f "$previous_subs" ]; then
            print_error "Previous subdomain file not found: $previous_subs"
            exit 1
        fi
        
        # Compare subdomains
        print_info "Comparing subdomains..."
        comm -13 <(sort "$previous_subs") <(sort all_subs.txt) > "$compare_output_dir/new_subdomains.txt"
        comm -23 <(sort "$previous_subs") <(sort all_subs.txt) > "$compare_output_dir/removed_subdomains.txt"
        
        # Get counts
        prev_sub_count=$(wc -l < "$previous_subs" 2>/dev/null || echo 0)
        curr_sub_count=$(wc -l < all_subs.txt 2>/dev/null || echo 0)
        new_sub_count=$(wc -l < "$compare_output_dir/new_subdomains.txt" 2>/dev/null || echo 0)
        removed_sub_count=$(wc -l < "$compare_output_dir/removed_subdomains.txt" 2>/dev/null || echo 0)
        
        # Compare live hosts
        if [ -s live_hosts.txt ]; then
            print_info "Comparing live hosts..."
            
            # Get previous live hosts file
            if [ "$previous_dir" = "$OUTPUT_DIR" ]; then
                previous_live="$previous_dir/live_hosts.txt"
            else
                previous_live="$previous_dir/all_live.txt"
            fi
            
            if [ -f "$previous_live" ]; then
                # Extract just hostnames for comparison
                cat "$previous_live" | sed 's|https\?://||' | cut -d'/' -f1 | sort -u > /tmp/prev_live_hosts.txt
                cat live_hosts.txt | sed 's|https\?://||' | cut -d'/' -f1 | sort -u > /tmp/curr_live_hosts.txt
                
                # Compare
                comm -13 /tmp/prev_live_hosts.txt /tmp/curr_live_hosts.txt > /tmp/new_live_hosts.txt
                comm -23 /tmp/prev_live_hosts.txt /tmp/curr_live_hosts.txt > /tmp/now_dead_hosts.txt
                
                # Get full URLs for new live hosts
                if [ -s /tmp/new_live_hosts.txt ]; then
                    grep -F -f /tmp/new_live_hosts.txt live_hosts.txt > "$compare_output_dir/new_live.txt" 2>/dev/null || touch "$compare_output_dir/new_live.txt"
                else
                    touch "$compare_output_dir/new_live.txt"
                fi
                
                # Save now dead hosts list
                cp /tmp/now_dead_hosts.txt "$compare_output_dir/now_dead.txt" 2>/dev/null || touch "$compare_output_dir/now_dead.txt"
                
                # Get counts
                prev_live_count=$(wc -l < /tmp/prev_live_hosts.txt 2>/dev/null || echo 0)
                curr_live_count=$(wc -l < /tmp/curr_live_hosts.txt 2>/dev/null || echo 0)
                new_live_count=$(wc -l < "$compare_output_dir/new_live.txt" 2>/dev/null || echo 0)
                now_dead_count=$(wc -l < "$compare_output_dir/now_dead.txt" 2>/dev/null || echo 0)
                
                # Clean up temp files
                rm -f /tmp/prev_live_hosts.txt /tmp/curr_live_hosts.txt /tmp/new_live_hosts.txt /tmp/now_dead_hosts.txt
            else
                print_warning "No previous live hosts file found"
                prev_live_count=0
                curr_live_count=$live_hosts
                new_live_count=$live_hosts
                now_dead_count=0
                touch "$compare_output_dir/new_live.txt"
                touch "$compare_output_dir/now_dead.txt"
            fi
        else
            prev_live_count=0
            curr_live_count=0
            new_live_count=0
            now_dead_count=0
            touch "$compare_output_dir/new_live.txt"
            touch "$compare_output_dir/now_dead.txt"
        fi
        
        # Save all results
        cp all_subs.txt "$compare_output_dir/all_subdomains.txt" 2>/dev/null || touch "$compare_output_dir/all_subdomains.txt"
        if [ -f live_hosts.txt ]; then
            cp live_hosts.txt "$compare_output_dir/all_live.txt" 2>/dev/null
        else
            touch "$compare_output_dir/all_live.txt"
        fi
        
        # Create summary
        cat > "$compare_output_dir/summary.txt" << EOF
Compare Summary - $(date)
Target: $DOMAIN
Compared with: $previous_dir

SUBDOMAINS:
- Previous: $prev_sub_count
- Current: $curr_sub_count
- New: $new_sub_count
- Removed: $removed_sub_count

LIVE HOSTS:
- Previous: $prev_live_count
- Current: $curr_live_count
- New Live: $new_live_count
- Now Dead: $now_dead_count
EOF
        
        # Display Results in CLI
        echo ""
        echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${GREEN}║             COMPARISON RESULTS                            ║${NC}"
        echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${CYAN}Target:${NC} ${BOLD}$DOMAIN${NC}"
        echo -e "${CYAN}Compared with:${NC} ${BOLD}$previous_dir${NC}"
        echo -e "${CYAN}Results saved to:${NC} ${BOLD}$compare_output_dir${NC}"
        echo ""
        
        echo -e "${BOLD}${BLUE}═══ SUBDOMAIN CHANGES ═══${NC}"
        echo -e "  ${GREEN}►${NC} Previous count: ${BOLD}$prev_sub_count${NC}"
        echo -e "  ${GREEN}►${NC} Current count:  ${BOLD}$curr_sub_count${NC}"
        echo -e "  ${GREEN}►${NC} New:            ${BOLD}${GREEN}$new_sub_count${NC}"
        echo -e "  ${RED}►${NC} Removed:        ${BOLD}${RED}$removed_sub_count${NC}"
        echo ""
        
        if [ "$new_sub_count" -gt 0 ]; then
            echo -e "${BOLD}${GREEN}╔═══ NEW SUBDOMAINS ═══╗${NC}"
            if [ "$new_sub_count" -le 20 ]; then
                while IFS= read -r subdomain; do
                    echo -e "  ${GREEN}+${NC} $subdomain"
                done < "$compare_output_dir/new_subdomains.txt"
            else
                head -20 "$compare_output_dir/new_subdomains.txt" | while IFS= read -r subdomain; do
                    echo -e "  ${GREEN}+${NC} $subdomain"
                done
                echo -e "  ${YELLOW}... and $((new_sub_count - 20)) more (see new_subdomains.txt)${NC}"
            fi
            echo -e "${BOLD}${GREEN}╚═══════════════════════╝${NC}"
            echo ""
        fi
        
        if [ "$removed_sub_count" -gt 0 ]; then
            echo -e "${BOLD}${RED}╔═══ REMOVED SUBDOMAINS ═══╗${NC}"
            if [ "$removed_sub_count" -le 20 ]; then
                while IFS= read -r subdomain; do
                    echo -e "  ${RED}-${NC} $subdomain"
                done < "$compare_output_dir/removed_subdomains.txt"
            else
                head -20 "$compare_output_dir/removed_subdomains.txt" | while IFS= read -r subdomain; do
                    echo -e "  ${RED}-${NC} $subdomain"
                done
                echo -e "  ${YELLOW}... and $((removed_sub_count - 20)) more (see removed_subdomains.txt)${NC}"
            fi
            echo -e "${BOLD}${RED}╚═════════════════════════╝${NC}"
            echo ""
        fi
        
        echo -e "${BOLD}${BLUE}═══ LIVE HOST CHANGES ═══${NC}"
        echo -e "  ${GREEN}►${NC} Previous count: ${BOLD}$prev_live_count${NC}"
        echo -e "  ${GREEN}►${NC} Current count:  ${BOLD}$curr_live_count${NC}"
        echo -e "  ${GREEN}►${NC} New Live:       ${BOLD}${GREEN}$new_live_count${NC}"
        echo -e "  ${RED}►${NC} Now Dead:       ${BOLD}${RED}$now_dead_count${NC}"
        echo ""
        
        if [ "$new_live_count" -gt 0 ]; then
            echo -e "${BOLD}${GREEN}╔═══ NEW LIVE HOSTS ═══╗${NC}"
            if [ "$new_live_count" -le 15 ]; then
                while IFS= read -r host; do
                    echo -e "  ${GREEN}+${NC} $host"
                done < "$compare_output_dir/new_live.txt"
            else
                head -15 "$compare_output_dir/new_live.txt" | while IFS= read -r host; do
                    echo -e "  ${GREEN}+${NC} $host"
                done
                echo -e "  ${YELLOW}... and $((new_live_count - 15)) more (see new_live.txt)${NC}"
            fi
            echo -e "${BOLD}${GREEN}╚═══════════════════════╝${NC}"
            echo ""
        fi
        
        if [ "$now_dead_count" -gt 0 ]; then
            echo -e "${BOLD}${RED}╔═══ NOW DEAD HOSTS ═══╗${NC}"
            if [ "$now_dead_count" -le 15 ]; then
                while IFS= read -r host; do
                    echo -e "  ${RED}⚫${NC} $host"
                done < "$compare_output_dir/now_dead.txt"
            else
                head -15 "$compare_output_dir/now_dead.txt" | while IFS= read -r host; do
                    echo -e "  ${RED}⚫${NC} $host"
                done
                echo -e "  ${YELLOW}... and $((now_dead_count - 15)) more (see now_dead.txt)${NC}"
            fi
            echo -e "${BOLD}${RED}╚═════════════════════╝${NC}"
            echo ""
        fi
        
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${BOLD}${CYAN}Results saved to: $compare_output_dir${NC}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${NC}"
        echo ""
        
        # Send Discord notification
        send_discord "🔍 Compare Results - $DOMAIN" "Comparison completed with $(basename $previous_dir)" 3447003 '[
            {"name": "🆕 New Subdomains", "value": "'"$new_sub_count"'", "inline": true},
            {"name": "❌ Removed", "value": "'"$removed_sub_count"'", "inline": true},
            {"name": "🟢 New Live", "value": "'"$new_live_count"'", "inline": true},
            {"name": "🔴 Now Dead", "value": "'"$now_dead_count"'", "inline": true},
            {"name": "📂 Results", "value": "compare_'"$compare_num"'", "inline": false}
        ]' "0xMarvul RECON FLOW"
        
        print_success "Comparison completed!"
        exit 0
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
                    print_skip_hint
                    run_with_skip "naabu" "naabu -l ips.txt -o open_ports.txt 2>/dev/null"
                    local exit_code=$?
                    if [ $exit_code -eq 0 ] || [ $exit_code -eq 2 ]; then
                        if [ -s open_ports.txt ]; then
                            port_count=$(wc -l < open_ports.txt 2>/dev/null || echo 0)
                            if [ $exit_code -eq 0 ]; then
                                print_success "Naabu completed - Found $port_count open ports"
                            else
                                print_info "Naabu - Found $port_count open ports (partial)"
                            fi
                            
                            # Step 3: Detailed scan with Nmap (get service names)
                            if command -v nmap &> /dev/null; then
                                print_info "Running Nmap for detailed service detection..."
                                print_skip_hint
                                # Extract unique ports and format for nmap (validate numeric and range)
                                port_list=$(cut -d':' -f2 open_ports.txt | grep -E '^[0-9]+$' | awk '$1 >= 1 && $1 <= 65535' | sort -u | tr '\n' ',' | sed 's/,$//')
                                if [ -n "$port_list" ]; then
                                    run_with_skip "nmap" "nmap -iL ips.txt -p \"$port_list\" -sV -oN ports_detailed.txt 2>/dev/null"
                                    local nmap_exit=$?
                                    if [ $nmap_exit -eq 0 ]; then
                                        print_success "Nmap completed - Detailed results saved to ports_detailed.txt"
                                    elif [ $nmap_exit -eq 2 ]; then
                                        # Skipped - message already printed
                                        :
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
                            if [ $exit_code -eq 0 ]; then
                                print_warning "Naabu completed - No open ports found"
                            fi
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
        print_step "Subdomain Takeover Check (-takeover)"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s live_hosts.txt ] && command -v nuclei &> /dev/null; then
            print_info "Running Nuclei takeover templates..."
            print_skip_hint
            
            # Check if templates exist
            if [ -d "$HOME/nuclei-templates/http/takeovers" ]; then
                run_with_skip "nuclei-takeover" "nuclei -l live_hosts.txt -t ~/nuclei-templates/http/takeovers -o takeover_results.txt 2>/dev/null"
                local exit_code=$?
                
                if [ $exit_code -eq 0 ] || [ $exit_code -eq 2 ]; then
                    if [ -s takeover_results.txt ]; then
                        takeover_count=$(grep -c . takeover_results.txt 2>/dev/null || echo 0)
                        if [ "$takeover_count" -gt 0 ]; then
                            if [ $exit_code -eq 0 ]; then
                                print_success "Nuclei takeover scan completed - Found $takeover_count potential takeovers!"
                            else
                                print_info "Nuclei takeover scan - Found $takeover_count potential takeovers (partial)!"
                            fi
                            # Show findings
                            echo ""
                            echo -e "    ${RED}⚠️  TAKEOVER VULNERABILITIES FOUND:${NC}"
                            while read line; do
                                echo -e "    ${YELLOW}►${NC} $line"
                            done < takeover_results.txt
                            echo ""
                            # Send Discord alert for takeovers found
                            send_discord "🚨 Subdomain Takeover Found!" "Found $takeover_count vulnerable subdomains on $DOMAIN" 16711680 '[{"name": "Target", "value": "'"$DOMAIN"'", "inline": true}, {"name": "Vulnerabilities", "value": "'"$takeover_count"'", "inline": true}]' "0xMarvul RECON FLOW - CRITICAL"
                        else
                            if [ $exit_code -eq 0 ]; then
                                print_success "Nuclei takeover scan completed - No takeovers found"
                            else
                                print_info "Nuclei takeover scan - No takeovers found (partial scan)"
                            fi
                        fi
                    else
                        if [ $exit_code -eq 0 ]; then
                            print_success "Nuclei takeover scan completed - No takeovers found"
                        fi
                    fi
                else
                    print_error "Nuclei takeover scan failed"
                    failed_tools+=("nuclei-takeover")
                    send_discord_error "$DOMAIN" "nuclei-takeover" "Command execution failed"
                fi
            else
                print_error "Nuclei takeover templates not found!"
                print_info "Please run: nuclei -update-templates"
                failed_tools+=("nuclei-templates")
            fi
        else
            if [ ! -s live_hosts.txt ]; then
                print_warning "No live hosts to check for takeover"
            else
                print_warning "Nuclei not installed, skipping takeover check..."
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
            print_skip_hint
            run_with_skip "gospider" "gospider -S live_hosts.txt -o gospider_output --quiet 2>/dev/null"
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                print_success "Gospider completed"
                print_info "Gospider output saved in gospider_output/ directory"
            elif [ $exit_code -eq 2 ]; then
                # Skipped - message already printed by run_with_skip
                :
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
            print_skip_hint
            run_with_skip "waybackurls" "cat live_hosts.txt | waybackurls > wayback.txt 2>/dev/null"
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                print_success "Waybackurls completed"
            elif [ $exit_code -eq 2 ]; then
                # Skipped - message already printed by run_with_skip
                :
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
            print_skip_hint
            run_with_skip "katana" "katana -list live_hosts.txt -o katana.txt -silent 2>/dev/null"
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                print_success "Katana completed"
            elif [ $exit_code -eq 2 ]; then
                # Skipped - message already printed by run_with_skip
                :
            else
                print_error "Katana failed"
                failed_tools+=("katana")
                send_discord_error "$DOMAIN" "katana" "Command execution failed"
            fi
        else
            print_warning "Katana not installed, skipping..."
        fi
        
        # GAU (Optional with -moreurls flag)
        if [ "$ENABLE_MOREURLS" = true ]; then
            if command -v gau &> /dev/null; then
                print_info "Running GAU..."
                print_skip_hint
                run_with_skip "gau" "echo \"$DOMAIN\" | gau > gau.txt 2>/dev/null"
                local exit_code=$?
                if [ $exit_code -eq 0 ]; then
                    gau_count=$(wc -l < gau.txt 2>/dev/null || echo 0)
                    print_success "GAU completed - URLs found: $gau_count"
                elif [ $exit_code -eq 2 ]; then
                    # Skipped - message already printed
                    :
                else
                    print_error "GAU failed"
                    failed_tools+=("gau")
                    send_discord_error "$DOMAIN" "gau" "Command execution failed"
                fi
            else
                print_warning "GAU not installed, skipping..."
            fi
            
            # Hakrawler (Optional with -moreurls flag)
            if [ -s live_hosts.txt ] && command -v hakrawler &> /dev/null; then
                print_info "Running Hakrawler..."
                print_skip_hint
                run_with_skip "hakrawler" "cat live_hosts.txt | hakrawler > hakrawler.txt 2>/dev/null"
                local exit_code=$?
                if [ $exit_code -eq 0 ]; then
                    hakrawler_count=$(wc -l < hakrawler.txt 2>/dev/null || echo 0)
                    print_success "Hakrawler completed - URLs found: $hakrawler_count"
                elif [ $exit_code -eq 2 ]; then
                    # Skipped - message already printed
                    :
                else
                    print_error "Hakrawler failed"
                    failed_tools+=("hakrawler")
                    send_discord_error "$DOMAIN" "hakrawler" "Command execution failed"
                fi
            else
                if [ ! -s live_hosts.txt ]; then
                    print_warning "No live hosts for Hakrawler"
                else
                    print_warning "Hakrawler not installed, skipping..."
                fi
            fi
        fi
    else
        print_warning "No live hosts found, skipping URL gathering..."
    fi
    
    # Step 4 continued: Merge URLs
    if [ "$ENABLE_MOREURLS" = true ]; then
        if [ -f wayback.txt ] || [ -f katana.txt ] || [ -f gau.txt ] || [ -f hakrawler.txt ]; then
            cat wayback.txt katana.txt gau.txt hakrawler.txt 2>/dev/null | sort -u > allurls.txt
            total_urls=$(wc -l < allurls.txt 2>/dev/null || echo 0)
            print_success "Total unique URLs collected: $total_urls"
            print_info "Check gospider_output/ directory manually for additional URLs"
        else
            print_warning "No URL files found to merge"
            total_urls=0
        fi
    else
        if [ -f wayback.txt ] || [ -f katana.txt ]; then
            cat wayback.txt katana.txt 2>/dev/null | sort -u > allurls.txt
            total_urls=$(wc -l < allurls.txt 2>/dev/null || echo 0)
            print_success "Total unique URLs collected: $total_urls"
            print_info "Check gospider_output/ directory manually for additional URLs"
        else
            print_warning "No URL files found to merge"
            total_urls=0
        fi
    fi
    
    # Step 6: Parameter Discovery
    print_step "Step 6: Parameter Discovery"
    print_info "Timestamp: $(get_timestamp)"
    
    param_count=0
    if command -v paramspider &> /dev/null; then
        print_info "Running ParamSpider..."
        print_skip_hint
        run_with_skip "paramspider" "paramspider -d \"$DOMAIN\" 2>/dev/null"
        local exit_code=$?
        if [ $exit_code -eq 0 ] || [ $exit_code -eq 2 ]; then
            # ParamSpider saves output to results directory by default
            # Find and move the output file to params.txt
            if [ -f "results/${DOMAIN}.txt" ]; then
                cp "results/${DOMAIN}.txt" params.txt 2>/dev/null
            elif [ -f "output/${DOMAIN}.txt" ]; then
                cp "output/${DOMAIN}.txt" params.txt 2>/dev/null
            fi
            if [ -f params.txt ]; then
                param_count=$(wc -l < params.txt 2>/dev/null || echo 0)
                if [ $exit_code -eq 0 ]; then
                    print_success "ParamSpider completed - Parameters found: $param_count"
                else
                    # Was skipped, partial results
                    print_info "ParamSpider - Parameters found (partial): $param_count"
                fi
            else
                if [ $exit_code -eq 0 ]; then
                    print_success "ParamSpider completed"
                fi
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
    
    # Grep Juicy URLs (Optional)
    if [ "$ENABLE_GREP" = true ]; then
        print_step "Grep Juicy URLs (-grep)"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s allurls.txt ]; then
            # Create grep results directory
            mkdir -p grep_results
            
            # Also combine Gospider output if exists
            if [ -d gospider_output ] && [ -n "$(find gospider_output -maxdepth 1 -type f -print -quit 2>/dev/null)" ]; then
                print_info "Combining Gospider output..."
                find gospider_output -type f -exec cat {} + 2>/dev/null | grep -oE "https?://[^ \"']+" | sort -u > gospider_urls.txt
                cat allurls.txt gospider_urls.txt 2>/dev/null | sort -u > all_urls_combined.txt
                INPUT_FILE="all_urls_combined.txt"
            else
                INPUT_FILE="allurls.txt"
            fi
            
            print_info "Grepping for juicy URLs..."
            
            # Config files
            print_info "  → Config files..."
            grep -iE "(\.config|\.conf|\.cfg|\.ini|\.env|\.properties|\.yaml|\.yml|\.toml|\.xml|settings|configuration)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/config.txt
            config_count=$(wc -l < grep_results/config.txt 2>/dev/null || echo 0)
            
            # Backup files
            print_info "  → Backup files..."
            grep -iE "\.(bak|backup|old|orig|original|copy|tmp|temp|swp|swo|save|~|zip|tar|gz|rar|7z)(\?|$|&)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/backup.txt
            backup_count=$(wc -l < grep_results/backup.txt 2>/dev/null || echo 0)
            
            # Database files
            print_info "  → Database files..."
            grep -iE "(\.sql|\.sqlite|\.sqlite3|\.db|\.mdb|\.dump|mysql|postgres|mongodb|database|phpmyadmin)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/database.txt
            database_count=$(wc -l < grep_results/database.txt 2>/dev/null || echo 0)
            
            # Secrets & Credentials
            print_info "  → Secrets & credentials..."
            grep -iE "(password|passwd|pwd|secret|token|api_key|apikey|api-key|auth_token|access_token|private_key|credential|htpasswd|htaccess)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/secrets.txt
            secrets_count=$(wc -l < grep_results/secrets.txt 2>/dev/null || echo 0)
            
            # Source code exposure
            print_info "  → Source code exposure..."
            grep -iE "(\.git|\.svn|\.hg|\.bzr|\.gitignore|\.gitconfig|\.gitattributes)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/sourcecode.txt
            sourcecode_count=$(wc -l < grep_results/sourcecode.txt 2>/dev/null || echo 0)
            
            # API & Documentation
            print_info "  → API & documentation..."
            grep -iE "(swagger|openapi|api-docs|graphql|graphiql|/api/|/v1/|/v2/|/v3/|rest/|wsdl|raml)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/api.txt
            api_count=$(wc -l < grep_results/api.txt 2>/dev/null || echo 0)
            
            # Admin panels
            print_info "  → Admin panels..."
            grep -iE "(admin|administrator|dashboard|cpanel|webadmin|manager|console|portal|backend|wp-admin|wp-login|wp-content|phpmyadmin|adminer)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/admin.txt
            admin_count=$(wc -l < grep_results/admin.txt 2>/dev/null || echo 0)
            
            # Debug & Development
            print_info "  → Debug & development..."
            grep -iE "(debug|trace|test|phpinfo|server-status|server-info|\.dev\.|\.staging\.|\.uat\.|\.local\.|\.test\.)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/debug.txt
            debug_count=$(wc -l < grep_results/debug.txt 2>/dev/null || echo 0)
            
            # Log files
            print_info "  → Log files..."
            grep -iE "(\.log|/logs/|/log/|error\.log|access\.log|debug\.log|audit\.log)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/logs.txt
            logs_count=$(wc -l < grep_results/logs.txt 2>/dev/null || echo 0)
            
            # Upload directories
            print_info "  → Upload directories..."
            grep -iE "(upload|uploads|file|files|attachment|attachments|media|assets|/tmp/|/temp/|/cache/)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/uploads.txt
            uploads_count=$(wc -l < grep_results/uploads.txt 2>/dev/null || echo 0)
            
            # Keys & Certificates
            print_info "  → Keys & certificates..."
            grep -iE "\.(pem|key|crt|cer|p12|pfx|jks|keystore|pub|ppk)(\?|$|&)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/keys.txt
            keys_count=$(wc -l < grep_results/keys.txt 2>/dev/null || echo 0)
            
            # Sensitive data files
            print_info "  → Sensitive data files..."
            grep -iE "(\.csv|\.xls|\.xlsx|\.doc|\.docx|\.pdf|data\.json|users\.json|export|dump)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/datafiles.txt
            datafiles_count=$(wc -l < grep_results/datafiles.txt 2>/dev/null || echo 0)
            
            # Internal/Private
            print_info "  → Internal & private..."
            grep -iE "(internal|private|hidden|secret|confidential|restricted|/priv/|/private/)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/internal.txt
            internal_count=$(wc -l < grep_results/internal.txt 2>/dev/null || echo 0)
            
            # Cloud & AWS
            print_info "  → Cloud & AWS..."
            grep -iE "(aws|s3\.|amazonaws|azure|blob\.core|gcp|googleusercontent|firebase|digitalocean|bucket)" "$INPUT_FILE" 2>/dev/null | sort -u > grep_results/cloud.txt
            cloud_count=$(wc -l < grep_results/cloud.txt 2>/dev/null || echo 0)
            
            # Combine all unique findings
            print_info "Combining all results..."
            find grep_results/ -type f -name '*.txt' ! -name 'ALL_JUICY.txt' -exec cat {} + 2>/dev/null | sort -u > grep_results/ALL_JUICY.txt
            total_juicy=$(wc -l < grep_results/ALL_JUICY.txt 2>/dev/null || echo 0)
            
            # Remove empty files (but check total_juicy first to avoid deleting ALL_JUICY.txt prematurely)
            find grep_results/ -name '*.txt' ! -name 'ALL_JUICY.txt' -type f -empty -delete 2>/dev/null
            
            # Print summary
            print_success "Grep Juicy URLs completed!"
            echo ""
            echo -e "    ${GREEN}►${NC} Config files:      ${BOLD}$config_count${NC}"
            echo -e "    ${GREEN}►${NC} Backup files:      ${BOLD}$backup_count${NC}"
            echo -e "    ${GREEN}►${NC} Database files:    ${BOLD}$database_count${NC}"
            echo -e "    ${GREEN}►${NC} Secrets:           ${BOLD}$secrets_count${NC}"
            echo -e "    ${GREEN}►${NC} Source code:       ${BOLD}$sourcecode_count${NC}"
            echo -e "    ${GREEN}►${NC} API docs:          ${BOLD}$api_count${NC}"
            echo -e "    ${GREEN}►${NC} Admin panels:      ${BOLD}$admin_count${NC}"
            echo -e "    ${GREEN}►${NC} Debug/Dev:         ${BOLD}$debug_count${NC}"
            echo -e "    ${GREEN}►${NC} Log files:         ${BOLD}$logs_count${NC}"
            echo -e "    ${GREEN}►${NC} Uploads:           ${BOLD}$uploads_count${NC}"
            echo -e "    ${GREEN}►${NC} Keys/Certs:        ${BOLD}$keys_count${NC}"
            echo -e "    ${GREEN}►${NC} Data files:        ${BOLD}$datafiles_count${NC}"
            echo -e "    ${GREEN}►${NC} Internal:          ${BOLD}$internal_count${NC}"
            echo -e "    ${GREEN}►${NC} Cloud/AWS:         ${BOLD}$cloud_count${NC}"
            echo ""
            echo -e "    ${CYAN}═══════════════════════════════════${NC}"
            echo -e "    ${BOLD}TOTAL JUICY URLs: $total_juicy${NC}"
            echo -e "    ${CYAN}═══════════════════════════════════${NC}"
            echo -e "    ${GREEN}►${NC} Results saved in: ${BOLD}grep_results/${NC}"
            
        else
            print_warning "No URLs to grep (allurls.txt is empty)"
        fi
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
            print_skip_hint
            if [ -f ~/Desktop/WORDLIST/ULTRA_MEGA.txt ]; then
                dirsearch_cmd="dirsearch -l live_hosts.txt -o mar0xwan.txt -w ~/Desktop/WORDLIST/ULTRA_MEGA.txt -i 200 -e conf,config,bak,backup,swp,old,db,sql,asp,aspx,aspx,asp~,py,py~,rb,rb~,php,php~,bak,bkp,cache,cgi,conf,csv,html,inc,jar,js,json,jsp,jsp~,lock,log,rar,old,sql,sql.gz,http://sql.zip,sql.tar.gz,sql~,swp,swp~,tar,tar.bz2,tar.gz,txt,wadl,zip,.log,.xml,.js.,.json 2>/dev/null"
            else
                print_warning "Custom wordlist not found, using default"
                dirsearch_cmd="dirsearch -l live_hosts.txt -o mar0xwan.txt -i 200 2>/dev/null"
            fi
            
            run_with_skip "dirsearch" "$dirsearch_cmd"
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                print_success "Dirsearch completed"
                if [ -f mar0xwan.txt ]; then
                    dirsearch_count=$(grep -c "200" mar0xwan.txt 2>/dev/null || echo 0)
                    print_info "Dirsearch findings (200 status): $dirsearch_count"
                fi
            elif [ $exit_code -eq 2 ]; then
                # Skipped - message already printed by run_with_skip
                :
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
            print_skip_hint
            
            # Run secretfinder with direct file input (much faster than looping)
            run_with_skip "secretfinder" "secretfinder -i javascript.txt -o cli > secrets_found.txt 2>/dev/null"
            local exit_code=$?
            
            if [ $exit_code -eq 0 ] || [ $exit_code -eq 2 ]; then
                if [ -s secrets_found.txt ]; then
                    secret_count=$(wc -l < secrets_found.txt 2>/dev/null || echo 0)
                    if [ $exit_code -eq 0 ]; then
                        print_success "SecretFinder completed - Found $secret_count potential secrets"
                    else
                        print_info "SecretFinder - Found $secret_count potential secrets (partial)"
                    fi
                else
                    if [ $exit_code -eq 0 ]; then
                        print_warning "SecretFinder completed - No secrets found"
                    fi
                fi
            else
                print_error "SecretFinder failed"
                failed_tools+=("secretfinder")
                send_discord_error "$DOMAIN" "secretfinder" "Command execution failed"
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
    if [ "$ENABLE_MOREURLS" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}gau.txt${NC} - URLs from GetAllUrls (GAU)"
        echo -e "  ${CYAN}►${NC} ${BOLD}hakrawler.txt${NC} - URLs from Hakrawler web crawler"
    fi
    echo -e "  ${CYAN}►${NC} ${BOLD}allurls.txt${NC} - All unique URLs combined from all sources"
    echo -e "  ${CYAN}►${NC} ${BOLD}params.txt${NC} - Discovered parameters from ParamSpider"
    echo -e "  ${CYAN}►${NC} ${BOLD}javascript.txt${NC} - JavaScript file URLs (potential secrets, endpoints)"
    echo -e "  ${CYAN}►${NC} ${BOLD}php.txt${NC} - PHP file URLs (potential vulnerabilities)"
    echo -e "  ${CYAN}►${NC} ${BOLD}json.txt${NC} - JSON file URLs (API responses, configs)"
    echo -e "  ${CYAN}►${NC} ${BOLD}BIGRAC.txt${NC} - Sensitive files: swagger docs, API docs, configs, .env, SQL dumps, credentials"
    if [ "$ENABLE_TAKEOVER" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}takeover_results.txt${NC} - Subdomain takeover vulnerabilities found by Nuclei"
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
    if [ "$ENABLE_GREP" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}grep_results/${NC} - Folder containing juicy URLs by category:"
        echo -e "      ${CYAN}•${NC} config.txt - Config files (.env, .yaml, .conf, etc.)"
        echo -e "      ${CYAN}•${NC} backup.txt - Backup files (.bak, .old, .zip, etc.)"
        echo -e "      ${CYAN}•${NC} database.txt - Database files (.sql, .db, phpmyadmin)"
        echo -e "      ${CYAN}•${NC} secrets.txt - Secrets & credentials (passwords, tokens, api_keys)"
        echo -e "      ${CYAN}•${NC} sourcecode.txt - Source code exposure (.git, .svn)"
        echo -e "      ${CYAN}•${NC} api.txt - API & documentation (swagger, graphql)"
        echo -e "      ${CYAN}•${NC} admin.txt - Admin panels (wp-admin, dashboard)"
        echo -e "      ${CYAN}•${NC} debug.txt - Debug & dev files (phpinfo, server-status)"
        echo -e "      ${CYAN}•${NC} logs.txt - Log files (.log, error.log)"
        echo -e "      ${CYAN}•${NC} uploads.txt - Upload directories"
        echo -e "      ${CYAN}•${NC} keys.txt - Keys & certificates (.pem, .key)"
        echo -e "      ${CYAN}•${NC} datafiles.txt - Sensitive data files (.csv, .xlsx)"
        echo -e "      ${CYAN}•${NC} internal.txt - Internal & private paths"
        echo -e "      ${CYAN}•${NC} cloud.txt - Cloud & AWS (s3, amazonaws)"
        echo -e "      ${CYAN}•${NC} ALL_JUICY.txt - All juicy URLs combined"
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
