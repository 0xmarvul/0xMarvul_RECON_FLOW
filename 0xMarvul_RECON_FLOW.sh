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

# Skip control variables
skip_current=false
current_pid=""
exit_script=false

# Trap handler for CTRL+C - Skip current tool
trap_ctrlc() {
    skip_current=true
    if [ -n "$current_pid" ] && kill -0 "$current_pid" 2>/dev/null; then
        kill -TERM "$current_pid" 2>/dev/null
        wait "$current_pid" 2>/dev/null
    fi
    echo -e "\n${YELLOW}[!] Skipping current tool...${NC}"
}

# Trap handler for CTRL+Z - Exit entire script
trap_ctrlz() {
    exit_script=true
    if [ -n "$current_pid" ] && kill -0 "$current_pid" 2>/dev/null; then
        kill -TERM "$current_pid" 2>/dev/null
        wait "$current_pid" 2>/dev/null
    fi
    echo -e "\n${RED}[!] Exiting 0xMarvul RECON FLOW...${NC}"
    echo -e "${RED}[!] Partial results saved in $OUTPUT_DIR/${NC}"
    send_discord_cancelled "$DOMAIN"
    exit 1
}

# Set up traps
trap trap_ctrlc SIGINT
trap trap_ctrlz SIGTSTP

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

# Function to run a tool with skip support
run_tool() {
    local tool_name="$1"
    shift
    local command="$@"
    
    skip_current=false
    
    print_info "Running $tool_name... (CTRL+C to skip, CTRL+Z to exit)"
    
    # Run command in background and capture PID
    eval "$command" &
    current_pid=$!
    
    # Wait for the process
    wait $current_pid 2>/dev/null
    local exit_code=$?
    current_pid=""
    
    # Check if we should exit the script
    if [ "$exit_script" = true ]; then
        echo -e "\n${RED}[!] Exiting 0xMarvul RECON FLOW...${NC}"
        echo -e "${RED}[!] Partial results saved in $OUTPUT_DIR/${NC}"
        send_discord_cancelled "$DOMAIN"
        exit 1
    fi
    
    # Check if we skipped
    if [ "$skip_current" = true ]; then
        print_warning "Skipped: $tool_name"
        return 1
    fi
    
    # Check exit code
    if [ $exit_code -eq 0 ]; then
        print_success "$tool_name completed"
        return 0
    else
        print_error "$tool_name failed"
        return 2
    fi
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

# Send cancelled scan notification
send_discord_cancelled() {
    local domain="$1"
    local domain_escaped="$(escape_json "$domain")"
    
    local fields='[
      {"name": "📁 Partial Results", "value": "Saved in '"$domain_escaped"'/", "inline": true}
    ]'
    
    send_discord "⏹️ Scan Cancelled" "Scan of **$domain_escaped** was manually stopped" 16776960 "$fields" "0xMarvul RECON FLOW"
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
    echo -e "  ${CYAN}--webhook <url>${NC}    Use custom Discord webhook URL"
    echo -e "  ${CYAN}--no-notify${NC}        Disable Discord notifications"
    echo ""
    echo -e "${BOLD}Controls:${NC}"
    echo -e "  ${CYAN}CTRL+C${NC}            Skip current tool"
    echo -e "  ${CYAN}CTRL+Z${NC}            Exit entire script"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ${CYAN}$0 target.com${NC}"
    echo -e "  ${CYAN}$0 target.com -dir${NC}"
    echo -e "  ${CYAN}$0 target.com -dir --no-notify${NC}"
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
    
    show_banner
    
    echo -e "${BOLD}${YELLOW}Controls:${NC}"
    echo -e "  ${CYAN}CTRL+C${NC} - Skip current tool"
    echo -e "  ${CYAN}CTRL+Z${NC} - Exit entire script"
    echo ""
    
    # Check if domain is provided
    if [ -z "$DOMAIN" ]; then
        print_error "No domain provided!"
        usage
    fi
    
    OUTPUT_DIR="$DOMAIN"
    
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
        if run_tool "Subfinder" "subfinder -d '$DOMAIN' -o subs_subfinder.txt 2>/dev/null"; then
            : # Success
        elif [ $? -eq 2 ]; then
            failed_tools+=("subfinder")
            send_discord_error "$DOMAIN" "subfinder" "Command execution failed"
        fi
    else
        print_warning "Subfinder not installed, skipping..."
    fi
    
    # Assetfinder
    if command -v assetfinder &> /dev/null; then
        if run_tool "Assetfinder" "assetfinder --subs-only '$DOMAIN' > subs_assetfinder.txt 2>/dev/null"; then
            : # Success
        elif [ $? -eq 2 ]; then
            failed_tools+=("assetfinder")
            send_discord_error "$DOMAIN" "assetfinder" "Command execution failed"
        fi
    else
        print_warning "Assetfinder not installed, skipping..."
    fi
    
    # crt.sh
    if command -v curl &> /dev/null && command -v jq &> /dev/null; then
        if run_tool "crt.sh" "timeout 30 curl -s 'https://crt.sh/?q=%25.$DOMAIN&output=json' | jq -r '.[].name_value' | sort -u > subs_crtsh.txt 2>/dev/null"; then
            if [ ! -s subs_crtsh.txt ]; then
                print_warning "crt.sh returned no results"
            fi
        elif [ $? -eq 2 ]; then
            failed_tools+=("crt.sh")
            send_discord_error "$DOMAIN" "crt.sh" "Connection timeout"
        fi
    else
        print_warning "curl or jq not installed, skipping crt.sh..."
    fi
    
    # Shrewdeye
    if command -v curl &> /dev/null; then
        if run_tool "Shrewdeye" "timeout 30 curl -s 'https://shrewdeye.app/domains/$DOMAIN.txt' > subs_shrewdeye.txt 2>/dev/null"; then
            if [ ! -s subs_shrewdeye.txt ]; then
                print_warning "Shrewdeye returned no results"
            fi
        elif [ $? -eq 2 ]; then
            failed_tools+=("shrewdeye")
            send_discord_error "$DOMAIN" "shrewdeye" "Connection failed"
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
        if run_tool "httpx" "cat all_subs.txt | httpx -silent -o live_hosts.txt 2>/dev/null"; then
            live_hosts=$(wc -l < live_hosts.txt 2>/dev/null || echo 0)
            print_success "Live hosts found: $live_hosts"
        elif [ $? -eq 2 ]; then
            failed_tools+=("httpx")
            send_discord_error "$DOMAIN" "httpx" "Command execution failed"
            live_hosts=0
        else
            live_hosts=0
        fi
    else
        print_warning "httpx not installed or no subdomains, skipping..."
        live_hosts=0
    fi
    
    # Step 3.5: Technology Detection
    print_step "Step 3.5: Technology Detection"
    print_info "Timestamp: $(get_timestamp)"
    
    technologies="N/A"
    if [ -s live_hosts.txt ] && command -v httpx &> /dev/null; then
        if run_tool "Tech Detection" "cat live_hosts.txt | httpx -tech-detect -silent -o tech_detect.txt 2>/dev/null"; then
            if [ -s tech_detect.txt ]; then
                technologies=$(grep -oP '\[.*?\]' tech_detect.txt 2>/dev/null | tr -d '[]' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g' | head -c 200)
                if [ -z "$technologies" ]; then
                    technologies="N/A"
                fi
                print_info "Technologies detected: $technologies"
            fi
        elif [ $? -eq 2 ]; then
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
            if run_tool "Gospider" "gospider -S live_hosts.txt -o gospider_output --quiet 2>/dev/null"; then
                print_info "Gospider output saved in gospider_output/ directory"
            elif [ $? -eq 2 ]; then
                failed_tools+=("gospider")
                send_discord_error "$DOMAIN" "gospider" "Command execution failed"
            fi
        else
            print_warning "Gospider not installed, skipping..."
        fi
        
        # Waybackurls
        if command -v waybackurls &> /dev/null; then
            if run_tool "Waybackurls" "cat live_hosts.txt | waybackurls > wayback.txt 2>/dev/null"; then
                : # Success
            elif [ $? -eq 2 ]; then
                failed_tools+=("waybackurls")
                send_discord_error "$DOMAIN" "waybackurls" "Command execution failed"
            fi
        else
            print_warning "Waybackurls not installed, skipping..."
        fi
        
        # Katana
        if command -v katana &> /dev/null; then
            if run_tool "Katana" "katana -list live_hosts.txt -o katana.txt -silent 2>/dev/null"; then
                : # Success
            elif [ $? -eq 2 ]; then
                failed_tools+=("katana")
                send_discord_error "$DOMAIN" "katana" "Command execution failed"
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
    
    # Step 5.5: Parameter Discovery
    print_step "Step 5.5: Parameter Discovery with ParamSpider"
    print_info "Timestamp: $(get_timestamp)"
    
    param_count=0
    if command -v paramspider &> /dev/null; then
        if run_tool "ParamSpider" "paramspider -d '$DOMAIN' -o params.txt 2>/dev/null"; then
            if [ -f params.txt ]; then
                param_count=$(wc -l < params.txt 2>/dev/null || echo 0)
                print_success "Parameters found: $param_count"
            fi
        elif [ $? -eq 2 ]; then
            failed_tools+=("paramspider")
            send_discord_error "$DOMAIN" "paramspider" "Command execution failed"
        fi
    else
        print_warning "ParamSpider not installed, skipping parameter discovery..."
    fi
    
    # Step 6: Filter Specific File Types
    print_step "Step 6: Filtering Specific File Types"
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
    
    # Step 6.5: Directory Bruteforce (Optional)
    dirsearch_count=0
    if [ "$ENABLE_DIRSEARCH" = true ]; then
        print_step "Step 6.5: Directory Bruteforce with Dirsearch"
        print_info "Timestamp: $(get_timestamp)"
        
        if [ -s live_hosts.txt ] && command -v dirsearch &> /dev/null; then
            if [ -f ~/Desktop/WORDLIST/ULTRA_MEGA.txt ]; then
                dirsearch_cmd="dirsearch -l live_hosts.txt -o mar0xwan.txt -w ~/Desktop/WORDLIST/ULTRA_MEGA.txt -i 200 -e conf,config,bak,backup,swp,old,db,sql,asp,aspx,aspx,asp~,py,py~,rb,rb~,php,php~,bak,bkp,cache,cgi,conf,csv,html,inc,jar,js,json,jsp,jsp~,lock,log,rar,old,sql,sql.gz,http://sql.zip,sql.tar.gz,sql~,swp,swp~,tar,tar.bz2,tar.gz,txt,wadl,zip,.log,.xml,.js.,.json 2>/dev/null"
            else
                print_warning "Custom wordlist not found, using default"
                dirsearch_cmd="dirsearch -l live_hosts.txt -o mar0xwan.txt -i 200 2>/dev/null"
            fi
            
            if run_tool "Dirsearch" "$dirsearch_cmd"; then
                if [ -f mar0xwan.txt ]; then
                    dirsearch_count=$(grep -c "200" mar0xwan.txt 2>/dev/null || echo 0)
                    print_success "Dirsearch findings (200 status): $dirsearch_count"
                fi
            elif [ $? -eq 2 ]; then
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
    if [ "$ENABLE_DIRSEARCH" = true ]; then
        echo -e "  ${GREEN}►${NC} Dirsearch findings: ${BOLD}${dirsearch_count:-0}${NC}"
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
    if [ "$ENABLE_DIRSEARCH" = true ]; then
        echo -e "  ${CYAN}►${NC} ${BOLD}mar0xwan.txt${NC} - Directory bruteforce results from Dirsearch"
    fi
    echo ""
    
    if [ ${#failed_tools[@]} -gt 0 ]; then
        echo -e "${BOLD}${RED}Failed/Skipped Tools:${NC}"
        for tool in "${failed_tools[@]}"; do
            echo -e "  ${RED}✗${NC} $tool"
        done
        echo ""
    fi
    
    # Send completion notification to Discord
    send_discord_complete "$DOMAIN" "${total_subs:-0}" "${live_hosts:-0}" "${total_urls:-0}" "${js_count:-0}" "${php_count:-0}" "${json_count:-0}" "${bigrac_count:-0}" "${param_count:-0}" "${dirsearch_count:-0}" "$technologies"
    
    print_success "Reconnaissance completed!"
    echo -e "${CYAN}All output files saved in: ${BOLD}$OUTPUT_DIR/${NC}\n"
}

# Run main function
main "$@"
