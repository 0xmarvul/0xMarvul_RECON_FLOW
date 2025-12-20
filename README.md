# 0xMarvul RECON FLOW

![0xMarvul RECON FLOW](New_0xMarvul.png)

A comprehensive bash-based reconnaissance automation tool for bug bounty hunting and security assessments. This tool automates the process of subdomain enumeration, live host discovery, URL gathering, and sensitive file detection.

## 🎯 Features

- **Automated Subdomain Enumeration**: Uses multiple sources (Subfinder, Assetfinder, crt.sh, Shrewdeye)
- **Live Host Detection**: Identifies active web servers using httpx
- **Subdomain Takeover Check**: Optional check for subdomain takeover vulnerabilities with Subzy (use `-takeover` flag)
- **Technology Detection**: Detects web technologies, CMS, frameworks, and servers
- **URL Discovery**: Gathers URLs from multiple sources (Gospider, Waybackurls, Katana)
- **Parameter Discovery**: Discovers URL parameters using ParamSpider
- **Directory Bruteforce**: Optional directory and file discovery with Dirsearch (use `-dir` flag)
- **Secret Finding**: Optional secret discovery in JavaScript files with SecretFinder (use `-secret` flag)
- **Smart Filtering**: Automatically categorizes JavaScript, PHP, JSON, and sensitive files
- **BIGRAC Detection**: Identifies sensitive files like Swagger docs, API endpoints, config files, credentials, etc.
- **Discord Notifications**: Real-time notifications via Discord webhooks (enabled by default)
- **Error Handling**: Continues execution even if some tools fail or timeout
- **Color-Coded Output**: Easy-to-read terminal output with status indicators
- **Progress Tracking**: Real-time progress updates with timestamps
- **Comprehensive Summary**: Detailed statistics and file descriptions at the end

## 📋 Prerequisites

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

12. **Subzy** - Subdomain takeover vulnerability checker (only needed if using `-takeover` flag)
    ```bash
    go install -v github.com/LukaSikic/subzy@latest
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
go install -v github.com/LukaSikic/subzy@latest

# Install Python tools
pip install paramspider dirsearch

# Install SecretFinder
git clone https://github.com/m4ll0k/SecretFinder.git
cd SecretFinder
pip install -r requirements.txt
sudo ln -s $(pwd)/SecretFinder.py /usr/local/bin/secretfinder
sudo chmod +x /usr/local/bin/secretfinder
cd ..

# Make sure Go binaries are in your PATH
export PATH=$PATH:$(go env GOPATH)/bin
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
```

## 🚀 Installation

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

## 📖 Usage

Basic usage:
```bash
./0xMarvul_RECON_FLOW.sh <domain> [options]
```

### Options

- `-dir` - Enable directory bruteforce with dirsearch
- `-secret` - Enable secret finding in JavaScript files with SecretFinder
- `-takeover` - Enable subdomain takeover check with Subzy
- `--webhook <url>` - Use custom Discord webhook URL
- `--no-notify` - Disable Discord notifications

### Examples

**Basic reconnaissance:**
```bash
./0xMarvul_RECON_FLOW.sh example.com
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

**With all optional features:**
```bash
./0xMarvul_RECON_FLOW.sh example.com -dir -secret -takeover
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
   - Directory bruteforce (if `-dir` flag used)
   - Secret finding (if `-secret` flag used)
5. Send error notifications if any tools fail
6. Save all results in organized files
7. Send a completion notification with full statistics
8. Display a comprehensive summary

## 📁 Output Structure

After running the tool, all results will be saved in a directory named after your target domain:

```
target.com/
├── subs_subfinder.txt          # Subdomains from Subfinder
├── subs_assetfinder.txt        # Subdomains from Assetfinder
├── subs_crtsh.txt              # Subdomains from Certificate Transparency logs
├── subs_shrewdeye.txt          # Subdomains from Shrewdeye
├── all_subs.txt                # All unique subdomains combined
├── live_hosts.txt              # Active/responsive web servers
├── takeover_results.txt        # Subdomain takeover check results (only if -takeover flag used)
├── tech_detect.txt             # Detected technologies (CMS, frameworks, servers)
├── gospider_output/            # Directory containing Gospider results
├── wayback.txt                 # Historical URLs from Wayback Machine
├── katana.txt                  # URLs discovered by Katana
├── allurls.txt                 # All unique URLs combined
├── params.txt                  # Discovered parameters from ParamSpider
├── javascript.txt              # JavaScript file URLs
├── php.txt                     # PHP file URLs
├── json.txt                    # JSON file URLs
├── BIGRAC.txt                  # Sensitive files (configs, APIs, credentials, etc.)
├── secrets_output/             # Directory containing secrets found in JS files (only if -secret flag used)
│   └── secrets_found.txt       # Secrets found by SecretFinder
└── mar0xwan.txt                # Dirsearch results (only if -dir flag used)
```

## 🔔 Discord Notifications

0xMarvul RECON FLOW includes real-time Discord webhook integration to keep you updated on scan progress.

### How It Works

Discord notifications are **enabled by default** and will send three types of messages:

#### 1. 🚀 Scan Started Notification
Sent when the scan begins, showing:
- Target domain being scanned
- Timestamp when scan started

#### 2. ✅ Scan Completed Notification
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

#### 3. ⚠️ Error Notifications
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

## 🎨 Color Coding

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
| `all_subs.txt` | Deduplicated subdomains | Complete subdomain list |
| `live_hosts.txt` | Active web servers | Target for further testing |
| `tech_detect.txt` | Detected technologies | Identify CMS, frameworks, servers |
| `gospider_output/` | Gospider crawl results | Deep URL discovery |
| `wayback.txt` | Wayback Machine URLs | Historical endpoints |
| `katana.txt` | Katana crawler results | Modern URL discovery |
| `allurls.txt` | All URLs combined | Complete URL list |
| `params.txt` | Discovered parameters | Parameter fuzzing and testing |
| `javascript.txt` | JavaScript files | Find secrets, API keys, endpoints |
| `php.txt` | PHP files | Test for vulnerabilities |
| `json.txt` | JSON files | API responses, configurations |
| `BIGRAC.txt` | Sensitive files | High-value targets (APIs, configs, credentials) |
| `takeover_results.txt` | Subdomain takeover results | Vulnerable subdomains (if -takeover used) |
| `secrets_output/` | SecretFinder results | Secrets found in JavaScript files (if -secret used) |
| `mar0xwan.txt` | Dirsearch results | Directory bruteforce findings (if -dir used) |

## 🔒 BIGRAC Detection

**BIGRAC** (Bug bounty Interesting Gateways, Routes, Apis, and Configurations) detection finds sensitive files including:

- Swagger/OpenAPI documentation (`/swagger`, `/api-docs`)
- Configuration files (`config.json`, `config.yaml`, `.env`)
- Database files (`db.sql`, `dump.sql`, `backup`)
- Credential files (`.htpasswd`, `credentials`)
- API schemas and manifests
- Environment files
- Package configuration files

## ⚠️ Error Handling

The tool is designed to be resilient:

- **Continues execution** even if individual tools fail
- **Timeout protection** for external API calls (crt.sh, Shrewdeye)
- **Logs failed tools** in the final summary
- **Graceful degradation** when tools are not installed

## 🎯 Use Cases

This tool is perfect for:

- **Bug Bounty Hunting**: Comprehensive reconnaissance of target domains
- **Security Assessments**: Initial information gathering phase
- **Asset Discovery**: Finding all subdomains and URLs for an organization
- **Attack Surface Mapping**: Identifying all potential entry points
- **Sensitive File Detection**: Finding exposed configurations and credentials

## 🛡️ Ethical Usage

This tool is intended for:
- ✅ Authorized security testing
- ✅ Bug bounty programs
- ✅ Your own domains
- ✅ Educational purposes

**Always ensure you have permission before scanning any target.**

## 📝 Example Output

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

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is open source and available for educational and ethical security testing purposes.

## 👤 Author

**0xMarvul**

## ⭐ Support

If you find this tool useful, please consider giving it a star on GitHub!

## 📚 Resources

- [Subfinder Documentation](https://github.com/projectdiscovery/subfinder)
- [httpx Documentation](https://github.com/projectdiscovery/httpx)
- [Katana Documentation](https://github.com/projectdiscovery/katana)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

## 🔄 Updates

Check the repository regularly for updates and new features!

---

**Note**: This tool aggregates data from multiple sources. Some sources may be temporarily unavailable or return no results. The tool will continue execution and log any failures.
