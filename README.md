# 0xMarvul RECON FLOW

![0xMarvul RECON FLOW](New_0xMarvul.png)

A comprehensive bash-based reconnaissance automation tool for bug bounty hunting and security assessments. This tool automates the process of subdomain enumeration, live host discovery, URL gathering, and sensitive file detection.

## 🎯 Features

- **Automated Subdomain Enumeration**: Uses multiple sources (Subfinder, Assetfinder, crt.sh, Shrewdeye)
- **Live Host Detection**: Identifies active web servers using httpx
- **URL Discovery**: Gathers URLs from multiple sources (Gospider, Waybackurls, Katana)
- **Smart Filtering**: Automatically categorizes JavaScript, PHP, JSON, and sensitive files
- **BIGRAC Detection**: Identifies sensitive files like Swagger docs, API endpoints, config files, credentials, etc.
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

7. **jq** - JSON processor
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # macOS
   brew install jq
   
   # Arch Linux
   sudo pacman -S jq
   ```

8. **curl** - Transfer data with URLs (usually pre-installed)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install curl
   
   # macOS
   brew install curl
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
./0xMarvul_RECON_FLOW.sh <domain>
```

Example:
```bash
./0xMarvul_RECON_FLOW.sh example.com
```

The script will:
1. Check for required dependencies
2. Create an output directory named after the target domain
3. Perform reconnaissance across multiple phases
4. Save all results in organized files
5. Display a comprehensive summary

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
├── gospider_output/            # Directory containing Gospider results
├── wayback.txt                 # Historical URLs from Wayback Machine
├── katana.txt                  # URLs discovered by Katana
├── allurls.txt                 # All unique URLs combined
├── javascript.txt              # JavaScript file URLs
├── php.txt                     # PHP file URLs
├── json.txt                    # JSON file URLs
└── BIGRAC.txt                  # Sensitive files (configs, APIs, credentials, etc.)
```

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
| `gospider_output/` | Gospider crawl results | Deep URL discovery |
| `wayback.txt` | Wayback Machine URLs | Historical endpoints |
| `katana.txt` | Katana crawler results | Modern URL discovery |
| `allurls.txt` | All URLs combined | Complete URL list |
| `javascript.txt` | JavaScript files | Find secrets, API keys, endpoints |
| `php.txt` | PHP files | Test for vulnerabilities |
| `json.txt` | JSON files | API responses, configurations |
| `BIGRAC.txt` | Sensitive files | High-value targets (APIs, configs, credentials) |

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
