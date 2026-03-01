# 0xMarvul RECON FLOW

![0xMarvul RECON FLOW](New_0xMarvul.png)

A comprehensive bash-based reconnaissance automation tool for bug bounty hunting and security assessments. This tool automates the process of subdomain enumeration, live host discovery, URL gathering, and sensitive file detection.

## Features

- **Automated Subdomain Enumeration**: Uses multiple sources (Subfinder, Assetfinder, crt.sh, Shrewdeye, HackerTarget, RapidDNS, Anubis-DB)
- **Parallel Subdomain Enumeration**: Optional parallel mode with `-parallel` flag for faster subdomain discovery
- **Live Host Detection**: Identifies active web servers using httpx
- **Subdomain Takeover Check**: Optional check for subdomain takeover vulnerabilities with Nuclei (use `-takeover` flag)
- **Technology Detection**: Detects web technologies, CMS, frameworks, and servers
- **URL Discovery**: Gathers URLs from multiple sources (Gospider, Waybackurls, Katana)
- **Extended URL Discovery**: Optional extra URL gathering with GAU and Hakrawler (use `-moreurls` flag)
- **Parameter Discovery**: Discovers URL parameters using ParamSpider
- **Directory Bruteforce**: Optional directory and file discovery with Dirsearch (use `-dir` flag)
- **Secret Finding**: Optional secret discovery in JavaScript files with SecretFinder (use `-secret` flag)
- **Smart Filtering**: Automatically categorizes JavaScript, PHP, JSON, and sensitive files
- **BIGRAC Detection**: Identifies sensitive files like Swagger docs, API endpoints, config files, credentials, etc.
- **Discord Notifications**: Real-time notifications via Discord webhooks (enabled by default)
- **Graceful Skip Feature**: Press **ENTER** to skip any long-running tool while preserving partial results
- **Error Handling**: Continues execution even if some tools fail or timeout
- **Color-Coded Output**: Easy-to-read terminal output with status indicators
- **Progress Tracking**: Real-time progress updates with timestamps
- **Comprehensive Summary**: Detailed statistics and file descriptions at the end

## Graceful Skip Feature

One of the powerful features of 0xMarvul RECON FLOW is the ability to skip long-running tools without stopping the entire scan.

### How It Works

When running any tool that might take a long time (like `waybackurls`, `katana`, `gospider`, `dirsearch`, `naabu`, etc.), you'll see a hint message:

```
[*] Running Waybackurls...
    (Press ENTER to skip...)
```

**Press ENTER** at any time during the tool's execution to:
- **Stop that specific tool** immediately
- **Preserve any partial results** already gathered
- **Continue to the next tool** in the workflow

### Example

```bash
[*] Running Waybackurls...
    (Press ENTER to skip...)
[!] Skipped: waybackurls (user interrupted) - partial results saved
[*] Running Katana...
    (Press ENTER to skip...)
```

### Why This Feature?

- **Tools like `waybackurls` can take hours or even days** on large targets
- You may have gathered enough data and want to move forward
- Prevents wasting time on tools that are taking too long
- **Partial results are always saved** - you never lose what was already collected
- Gives you complete control over your reconnaissance workflow

### Supported Tools

The graceful skip feature works with these potentially long-running tools:
- **waybackurls** - Historical URL discovery
- **katana** - Modern web crawler
- **gospider** - Fast web spider
- **dirsearch** - Directory brute-forcing
- **paramspider** - Parameter discovery
- **secretfinder** - Secret scanning in JavaScript
- **naabu** - Fast port scanner
- **nmap** - Detailed port scanning
- **nuclei** - Vulnerability scanner with takeover templates

## Prerequisites

This tool requires several external security tools to be installed. Below are the installation instructions for each:

### Required Tools

1. **Subfinder** - Fast subdomain discovery tool
   ```bash
   go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
   ```

2. **Assetfinder** - Find domains and subdomains
   ```bash
   go install github.com/tomnomnom/assetfinder@latest
   ```

3. **httpx** - Fast HTTP probe
   ```bash
   go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
   ```

4. **Gospider** - Fast web spider
   ```bash
   go install github.com/jaeles-project/gospider@latest
   ```

5. **Waybackurls** - Fetch URLs from Wayback Machine
   ```bash
   go install github.com/tomnomnom/waybackurls@latest
   ```

6. **Katana** - Next-generation crawling framework
   ```bash
   go install github.com/projectdiscovery/katana/cmd/katana@latest
   ```

7. **ParamSpider** - Parameter discovery tool
   ```bash
   pip install paramspider
   ```

8. **jq** - JSON processor
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # macOS
   brew install jq
   
   # Arch Linux
   sudo pacman -S jq
   ```

9. **curl** - Transfer data with URLs (usually pre-installed)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install curl
   
   # macOS
   brew install curl
   ```

### Optional Tools

10. **Dirsearch** - Web path scanner (only needed if using `-dir` flag)
    ```bash
    pip install dirsearch
    ```

11. **SecretFinder** - Find secrets in JavaScript files (only needed if using `-secret` flag)
    ```bash
    # Clone and install
    git clone https://github.com/m4ll0k/SecretFinder.git
    cd SecretFinder
    pip install -r requirements.txt
    # Make it accessible in PATH
    sudo ln -s $(pwd)/SecretFinder.py /usr/local/bin/secretfinder
    sudo chmod +x /usr/local/bin/secretfinder
    ```

12. **Nuclei** - Vulnerability scanner (only needed if using `-takeover` flag)
    ```bash
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    # Update nuclei templates to get takeover templates
    nuclei -update-templates
    ```

13. **GF (GF Patterns)** - Pattern-based grep for filtering URLs (only needed if using `-gf` flag)
    ```bash
    # Install gf
    go install github.com/tomnomnom/gf@latest
    
    # Install gf patterns
    git clone https://github.com/1ndianl33t/Gf-Patterns.git
    mkdir -p ~/.gf
    cp Gf-Patterns/*.json ~/.gf/
    
    # Or install patterns from tomnomnom's repo
    git clone https://github.com/tomnomnom/gf.git
    cp gf/examples/*.json ~/.gf/
    ```

14. **GAU (GetAllUrls)** - Fetch known URLs from various sources (only needed if using `-moreurls` flag)
    ```bash
    go install github.com/lc/gau/v2/cmd/gau@latest
    ```

15. **Hakrawler** - Fast web crawler (only needed if using `-moreurls` flag)
    ```bash
    go install github.com/hakluke/hakrawler@latest
    ```

16. **Naabu** - Fast port scanner (only needed if using `-port` flag)
    ```bash
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    ```

17. **Nmap** - Network mapper (only needed if using `-port` flag)
    ```bash
    # Ubuntu/Debian
    sudo apt-get install nmap
    
    # macOS
    brew install nmap
    ```

18. **dnsx** - DNS toolkit (only needed if using `-port` flag)
    ```bash
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    ```

### Quick Installation (All Go Tools)

If you have Go installed, you can install all Go-based tools at once:

```bash
# Install all Go tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/jaeles-project/gospider@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/tomnomnom/gf@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/hakluke/hakrawler@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

# Install Python tools
pip install paramspider dirsearch

# Install SecretFinder
git clone https://github.com/m4ll0k/SecretFinder.git
cd SecretFinder
pip install -r requirements.txt
sudo ln -s $(pwd)/SecretFinder.py /usr/local/bin/secretfinder
sudo chmod +x /usr/local/bin/secretfinder
cd ..

# Install GF patterns
git clone https://github.com/1ndianl33t/Gf-Patterns.git
mkdir -p ~/.gf
cp Gf-Patterns/*.json ~/.gf/

# Make sure Go binaries are in your PATH
export PATH=$PATH:$(go env GOPATH)/bin
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
```

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/0xmarvul/0xMarvul_RECON_FLOW.git
   cd 0xMarvul_RECON_FLOW
   ```

2. Make the script executable:
   ```bash
   chmod +x 0xMarvul_RECON_FLOW.sh
   ```

3. Run the tool:
   ```bash
   ./0xMarvul_RECON_FLOW.sh target.com
   ```

## Usage

Basic usage:
```bash
./0xMarvul_RECON_FLOW.sh <domain> [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-parallel` | Run subdomain enumeration tools in parallel (faster) |
| `-moreurls` | Enable extra URL gathering with GAU and Hakrawler |
| `-dir` | Enable directory bruteforce with dirsearch |
| `-secret` | Enable secret finding in JavaScript files with SecretFinder |
| `-takeover` | Enable subdomain takeover check with Nuclei |
| `-gf` | Enable GF patterns to filter URLs for vulnerabilities |
| `-grep` | Extract juicy URLs by keywords (configs, backups, secrets, admin panels, etc.) |
| `-port` | Enable port scanning with Naabu and Nmap |
| `--webhook <url>` | Use custom Discord webhook URL |
| `--no-notify` | Disable Discord notifications |

### Examples

**Basic reconnaissance:**
```bash
./0xMarvul_RECON_FLOW.sh example.com
```

**With parallel subdomain enumeration:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -parallel
```

**With extra URL gathering:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -moreurls
```

**With parallel mode and extra URLs:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -parallel -moreurls
```

**With directory bruteforce:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -dir
```

**With secret finding:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -secret
```

**With subdomain takeover check:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -takeover
```

**With GF patterns for vulnerability filtering:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -gf
```

**With port scanning:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -port
```

**With grep juicy URLs:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -grep
```

**With GF patterns and grep:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -gf -grep
```

**With all optional features:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -parallel -moreurls -dir -secret -takeover -gf -port
```

**Custom webhook without notifications:**
```bash
./0xMarvul_RECON_FLOW.sh example.com --webhook "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"
```

**With directory bruteforce and no notifications:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -dir --no-notify
```

The script will:
1. Check for required dependencies
2. Send a scan start notification to Discord (if enabled)
3. Create an output directory named after the target domain
4. Perform reconnaissance across multiple phases:
   - Subdomain enumeration
   - Live host detection
   - Subdomain takeover check (if `-takeover` flag used)
   - Technology detection
   - URL gathering
   - Parameter discovery
   - File type filtering
   - GF patterns filtering (if `-gf` flag used)
   - Directory bruteforce (if `-dir` flag used)
   - Secret finding (if `-secret` flag used)
5. Send error notifications if any tools fail
6. Save all results in organized files
7. Send a completion notification with full statistics
8. Display a comprehensive summary

## Output Structure

After running the tool, all results will be saved in a directory named after your target domain:

```
target.com/
├── subs_subfinder.txt          # Subdomains from Subfinder
├── subs_assetfinder.txt        # Subdomains from Assetfinder
├── subs_crtsh.txt              # Subdomains from Certificate Transparency logs
├── subs_shrewdeye.txt          # Subdomains from Shrewdeye
├── subs_hackertarget.txt       # Subdomains from HackerTarget
├── subs_rapiddns.txt           # Subdomains from RapidDNS
├── subs_anubis.txt             # Subdomains from Anubis-DB
├── all_subs.txt                # All unique subdomains combined
├── live_hosts.txt              # Active/responsive web servers
├── takeover_results.txt        # Subdomain takeover check results (only if -takeover flag used)
├── tech_detect.txt             # Detected technologies (CMS, frameworks, servers)
├── gospider_output/            # Directory containing Gospider results
├── wayback.txt                 # Historical URLs from Wayback Machine
├── katana.txt                  # URLs discovered by Katana
├── gau.txt                     # URLs from GetAllUrls (only if -moreurls flag used)
├── hakrawler.txt               # URLs from Hakrawler (only if -moreurls flag used)
├── allurls.txt                 # All unique URLs combined
├── params.txt                  # Discovered parameters from ParamSpider
├── javascript.txt              # JavaScript file URLs
├── php.txt                     # PHP file URLs
├── json.txt                    # JSON file URLs
├── BIGRAC.txt                  # Sensitive files (configs, APIs, credentials, etc.)
├── gf/                         # GF patterns results (only if -gf flag used)
│   ├── xss.txt                 # URLs potentially vulnerable to XSS
│   ├── sqli.txt                # URLs potentially vulnerable to SQL injection
│   ├── ssrf.txt                # URLs potentially vulnerable to SSRF
│   ├── lfi.txt                 # URLs potentially vulnerable to LFI
│   ├── redirect.txt            # URLs with redirect parameters
│   ├── rce.txt                 # URLs potentially vulnerable to RCE
│   ├── idor.txt                # URLs potentially vulnerable to IDOR
│   └── ssti.txt                # URLs potentially vulnerable to SSTI
├── secrets_output/             # Directory containing secrets found in JS files (only if -secret flag used)
│   └── secrets_found.txt       # Secrets found by SecretFinder
├── mar0xwan.txt                # Dirsearch results (only if -dir flag used)
├── open_ports.txt              # Open ports discovered by Naabu (only if -port flag used)
└── ports_detailed.txt          # Detailed port scan with service detection (only if -port flag used)
```

### With `-grep` flag:
```
target.com/
└── grep_results/
    ├── config.txt      # Config files (.env, .yaml, .conf)
    ├── backup.txt      # Backup files (.bak, .old, .zip)
    ├── database.txt    # Database files (.sql, phpmyadmin)
    ├── secrets.txt     # Secrets & credentials
    ├── sourcecode.txt  # Source code (.git, .svn)
    ├── api.txt         # API docs (swagger, graphql)
    ├── admin.txt       # Admin panels
    ├── debug.txt       # Debug & dev files
    ├── logs.txt        # Log files
    ├── uploads.txt     # Upload directories
    ├── keys.txt        # Keys & certificates
    ├── datafiles.txt   # Sensitive data files
    ├── internal.txt    # Internal paths
    ├── cloud.txt       # Cloud & AWS URLs
    └── ALL_JUICY.txt   # All combined
```

## Discord Notifications

0xMarvul RECON FLOW includes real-time Discord webhook integration to keep you updated on scan progress.

### How It Works

Discord notifications are **enabled by default** and will send three types of messages:

#### 1. Scan Started Notification
Sent when the scan begins, showing:
- Target domain being scanned
- Timestamp when scan started

#### 2. Scan Completed Notification
Sent when the scan finishes successfully, showing:
- Target domain
- Total subdomains found
- Live hosts discovered
- Total URLs collected
- JavaScript files found
- PHP files found
- JSON files found
- Sensitive files (BIGRAC) found
- Parameters discovered
- Subdomain takeovers found (if `-takeover` flag used)
- Secrets found (if `-secret` flag used)
- Dirsearch results (if `-dir` flag used)
- Technologies detected
- Total scan duration

#### 3. Error Notifications
Sent whenever a tool fails or times out, showing:
- Which tool encountered an error
- Error message or reason
- Note that the scan continues with other tools

### Discord Message Examples

**Scan Started:**
```
🚀 Scan Started
Starting reconnaissance on **target.com**

🎯 Target: target.com
⏰ Started: 2025-12-20 14:30:00
```

**Scan Completed:**
```
✅ Recon Complete
Finished scanning **target.com**

📍 Subdomains: 150
🌐 Live Hosts: 45
🔗 Total URLs: 3420
📜 JavaScript: 89
🐘 PHP Files: 234
📋 JSON Files: 56
🔴 BIGRAC: 12
🔍 Parameters: 156
🚨 Takeovers: 2 found (if -takeover flag used)
🔑 Secrets: 15 found (if -secret flag used)
📁 Dirsearch: 245 found (if -dir flag used)
🔧 Technologies: Apache/2.4.41, PHP/7.4, WordPress, jQuery, Nginx
⏱️ Duration: 5m 32s
```

**Tool Error:**
```
⚠️ Tool Error
An error occurred during scan of **target.com**

🔧 Tool: crt.sh
❌ Error: Connection timeout

Scan will continue with other tools
```

### Using Discord Notifications

**Default Usage (notifications enabled):**
```bash
./0xMarvul_RECON_FLOW.sh target.com
```

**Custom Webhook URL:**
If you want to use your own Discord webhook:
```bash
./0xMarvul_RECON_FLOW.sh target.com --webhook "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
```

**Disable Notifications:**
If you don't want Discord notifications for a specific scan:
```bash
./0xMarvul_RECON_FLOW.sh target.com --no-notify
```

### Setting Up Your Own Discord Webhook

1. Open your Discord server and go to **Server Settings**
2. Navigate to **Integrations** → **Webhooks**
3. Click **New Webhook** or edit an existing one
4. Copy the **Webhook URL**
5. Use it with the `--webhook` flag or replace the default URL in the script

### Default Webhook

The script includes a default Discord webhook URL. If you're using this tool for your own purposes, you should:
- Create your own Discord webhook
- Either pass it via `--webhook` flag each time, or
- Edit the `DISCORD_WEBHOOK` variable in the script to use your webhook by default

**Security Note**: For production use, consider storing the webhook URL in an environment variable or external configuration file rather than hardcoding it in the script to prevent accidental exposure in version control.

## Color Coding

The tool uses color-coded output for better readability:

- **🟢 Green**: Success messages
- **🔴 Red**: Error messages
- **🟡 Yellow**: Warning messages
- **🔵 Cyan/Blue**: Informational messages

## 📊 Output File Descriptions

| File | Description | Use Case |
|------|-------------|----------|
| `subs_subfinder.txt` | Subdomains from Subfinder | Quick subdomain discovery |
| `subs_assetfinder.txt` | Subdomains from Assetfinder | Additional subdomain sources |
| `subs_crtsh.txt` | Certificate Transparency logs | Historical subdomain data |
| `subs_shrewdeye.txt` | Subdomains from Shrewdeye | Free subdomain enumeration |
| `subs_hackertarget.txt` | Subdomains from HackerTarget | Free API subdomain discovery |
| `subs_rapiddns.txt` | Subdomains from RapidDNS | Web-scraped subdomain data |
| `subs_anubis.txt` | Subdomains from Anubis-DB | Subdomain database |
| `all_subs.txt` | Deduplicated subdomains | Complete subdomain list |
| `live_hosts.txt` | Active web servers | Target for further testing |
| `tech_detect.txt` | Detected technologies | Identify CMS, frameworks, servers |
| `gospider_output/` | Gospider crawl results | Deep URL discovery |
| `wayback.txt` | Wayback Machine URLs | Historical endpoints |
| `katana.txt` | Katana crawler results | Modern URL discovery |
| `gau.txt` | URLs from GAU | Additional URL sources (if -moreurls used) |
| `hakrawler.txt` | URLs from Hakrawler | Web crawler results (if -moreurls used) |
| `allurls.txt` | All URLs combined | Combined URLs from URL discovery tools |
| `params.txt` | Discovered parameters | Parameter fuzzing and testing |
| `javascript.txt` | JavaScript files | Find secrets, API keys, endpoints |
| `php.txt` | PHP files | Test for vulnerabilities |
| `json.txt` | JSON files | API responses, configurations |
| `BIGRAC.txt` | Sensitive files | High-value targets (APIs, configs, credentials) |
| `gf/` | GF patterns results | Filtered URLs by vulnerability type (if -gf used) |
| `gf/xss.txt` | XSS pattern matches | URLs potentially vulnerable to XSS |
| `gf/sqli.txt` | SQLi pattern matches | URLs potentially vulnerable to SQL injection |
| `gf/ssrf.txt` | SSRF pattern matches | URLs potentially vulnerable to SSRF |
| `gf/lfi.txt` | LFI pattern matches | URLs potentially vulnerable to LFI |
| `gf/redirect.txt` | Redirect pattern matches | URLs with redirect parameters |
| `gf/rce.txt` | RCE pattern matches | URLs potentially vulnerable to RCE |
| `gf/idor.txt` | IDOR pattern matches | URLs potentially vulnerable to IDOR |
| `gf/ssti.txt` | SSTI pattern matches | URLs potentially vulnerable to SSTI |
| `takeover_results.txt` | Subdomain takeover results | Vulnerable subdomains (if -takeover used) |
| `secrets_output/` | SecretFinder results | Secrets found in JavaScript files (if -secret used) |
| `mar0xwan.txt` | Dirsearch results | Directory bruteforce findings (if -dir used) |
| `grep_results/` | Grep juicy URLs results | Categorized juicy/sensitive URLs (if -grep used) |
| `grep_results/config.txt` | Config file URLs | .env, .yaml, .conf files |
| `grep_results/backup.txt` | Backup file URLs | .bak, .old, .zip files |
| `grep_results/database.txt` | Database file URLs | .sql, phpmyadmin |
| `grep_results/secrets.txt` | Secret URLs | passwords, tokens, api_keys |
| `grep_results/sourcecode.txt` | Source code URLs | .git, .svn exposure |
| `grep_results/api.txt` | API documentation URLs | swagger, graphql |
| `grep_results/admin.txt` | Admin panel URLs | wp-admin, dashboard |
| `grep_results/debug.txt` | Debug URLs | phpinfo, server-status |
| `grep_results/logs.txt` | Log file URLs | .log, error.log |
| `grep_results/uploads.txt` | Upload directory URLs | /uploads/, /files/ |
| `grep_results/keys.txt` | Key & certificate URLs | .pem, .key files |
| `grep_results/datafiles.txt` | Sensitive data file URLs | .csv, .xlsx, .pdf |
| `grep_results/internal.txt` | Internal path URLs | internal, private paths |
| `grep_results/cloud.txt` | Cloud service URLs | s3, amazonaws |
| `grep_results/ALL_JUICY.txt` | All juicy URLs combined | Complete list of findings |

## BIGRAC Detection

**BIGRAC** (Bug bounty Interesting Gateways, Routes, Apis, and Configurations) detection finds sensitive files including:

- Swagger/OpenAPI documentation (`/swagger`, `/api-docs`)
- Configuration files (`config.json`, `config.yaml`, `.env`)
- Database files (`db.sql`, `dump.sql`, `backup`)
- Credential files (`.htpasswd`, `credentials`)
- API schemas and manifests
- Environment files
- Package configuration files

## Error Handling

The tool is designed to be resilient:

- **Continues execution** even if individual tools fail
- **Timeout protection** for external API calls (crt.sh, Shrewdeye)
- **Logs failed tools** in the final summary
- **Graceful degradation** when tools are not installed

## Use Cases

This tool is perfect for:

- **Bug Bounty Hunting**: Comprehensive reconnaissance of target domains
- **Security Assessments**: Initial information gathering phase
- **Asset Discovery**: Finding all subdomains and URLs for an organization
- **Attack Surface Mapping**: Identifying all potential entry points
- **Sensitive File Detection**: Finding exposed configurations and credentials

## Ethical Usage

This tool is intended for:
- ✅ Authorized security testing
- ✅ Bug bounty programs
- ✅ Your own domains
- ✅ Educational purposes

**Always ensure you have permission before scanning any target.**

## Example Output

```
[✓] Target Domain: example.com
[*] Start Time: 2025-12-20 13:45:00

═══════════════════════════════════════
[STEP] Step 1: Subdomain Enumeration
═══════════════════════════════════════

[*] Running Subfinder...
[✓] Subfinder completed
[*] Running Assetfinder...
[✓] Assetfinder completed
[*] Querying crt.sh...
[✓] crt.sh query completed

═══════════════════════════════════════
FINAL SUMMARY
═══════════════════════════════════════

Statistics:
  ► Total Subdomains: 150
  ► Live Hosts: 45
  ► Total URLs: 1250
  ► JavaScript files: 120
  ► PHP files: 30
  ► JSON files: 25
  ► BIGRAC sensitive files: 8
```

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## License

This project is open source and available for educational and ethical security testing purposes.

## Author

**Marwan Khodair** **(0xMarvul)**

## Support

If you find this tool useful, please consider giving it a star on GitHub!

## Resources

- [Subfinder Documentation](https://github.com/projectdiscovery/subfinder)
- [httpx Documentation](https://github.com/projectdiscovery/httpx)
- [Katana Documentation](https://github.com/projectdiscovery/katana)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

## Updates

Check the repository regularly for updates and new features!

---

**Note**: This tool aggregates data from multiple sources. Some sources may be temporarily unavailable or return no results. The tool will continue execution and log any failures.
