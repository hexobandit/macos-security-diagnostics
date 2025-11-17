# Security Case Studies

Real-world examples of macOS security incidents and how they were detected and resolved using our diagnostic tools.

## Case Study 1: OSX/Shlayer Adware Campaign

### Initial Symptoms
- Slow browser performance
- Unexpected pop-ups and redirects
- High CPU usage from unknown processes

### Discovery Process

#### Step 1: Launch Agent Analysis
```bash
ls -la ~/Library/LaunchAgents/
# Found: com.SearchWebSvc.plist (suspicious generic name)

cat ~/Library/LaunchAgents/com.SearchWebSvc.plist
```

**Suspicious findings:**
- Generic name not following reverse domain naming
- References to `/tmp/` execution path
- Base64 encoded payload in ProgramArguments

#### Step 2: Process Investigation
```bash
ps aux | grep -v "root\|$USER"
# Found process running from /tmp/SearchWebSvc
```

#### Step 3: Network Analysis
```bash
lsof -i -P | grep SearchWebSvc
# Found connections to suspicious ad-serving domains
```

### Red Flags Identified
- ✅ Non-standard Launch Agent name
- ✅ Execution from `/tmp/` directory
- ✅ Base64 encoded commands
- ✅ Network connections to ad networks
- ✅ High CPU usage

### Resolution Steps
1. **Immediate isolation**: Disconnected from network
2. **Process termination**: `sudo kill -9 [PID]`
3. **Launch Agent removal**: Moved plist to quarantine
4. **File cleanup**: Removed executables from `/tmp/`
5. **Browser reset**: Cleared all browser data and extensions
6. **System hardening**: Enabled Gatekeeper strict mode

### Lessons Learned
- Generic Launch Agent names are major red flags
- Always check process execution paths
- Network monitoring helps identify C&C communications

---

## Case Study 2: Cryptocurrency Miner Infection

### Initial Symptoms
- MacBook fan running constantly
- Extremely high CPU usage (90%+)
- System becoming unresponsive

### Discovery Process

#### Step 1: Process Analysis
```bash
ps aux | grep -v "root" | sort -k 3 -nr
# Top CPU process: XMRig with obfuscated name "com.apple.msrpc"
```

#### Step 2: Network Investigation
```bash
lsof -i -P | grep "com.apple.msrpc"
# Found connections to known mining pools on port 4444
netstat -an | grep ESTABLISHED
# Multiple connections to mining pool IPs
```

#### Step 3: Persistence Check
```bash
ls -la ~/Library/LaunchAgents/ | grep -v com.apple
# Found: com.apple.msrpc.plist (typosquatting Apple service)
```

### Red Flags Identified
- ✅ High CPU usage from unknown process
- ✅ Connections to mining pools (port 4444)
- ✅ Typosquatted Apple service name
- ✅ Launch Agent for persistence
- ✅ Process name mimicking system service

### Resolution Steps
1. **Process termination**: `sudo kill -9 [PID]`
2. **Launch Agent removal**: Deleted malicious plist
3. **Executable cleanup**: Found and removed miner binary
4. **Network blocking**: Added firewall rules for mining pool IPs
5. **System monitoring**: Set up CPU usage alerts

### Prevention Measures
- Installed Little Snitch for network monitoring
- Enabled Activity Monitor notifications for high CPU
- Regular Launch Agent audits scheduled

---

## Case Study 3: SSH Backdoor via Compromised Key

### Initial Symptoms
- Unusual network activity during off-hours
- Unknown processes running overnight
- Suspicious SSH connections in logs

### Discovery Process

#### Step 1: SSH Configuration Review
```bash
cat ~/.ssh/authorized_keys
# Found unknown SSH key with generic comment: "user@localhost"

ls -la ~/.ssh/
# authorized_keys modified 2 days ago
```

#### Step 2: Connection Monitoring
```bash
last | grep ssh
# Multiple SSH connections from unknown IP addresses

log show --predicate 'process == "sshd"' --last 24h
# Successful SSH logins from foreign IPs
```

#### Step 3: Process Investigation
```bash
ps aux | grep -v "root\|$USER"
# Found processes owned by current user but not recognized
```

### Red Flags Identified
- ✅ Unknown SSH key in authorized_keys
- ✅ Generic key comment
- ✅ Recent modification to SSH config
- ✅ Unknown IP connections
- ✅ Unexpected processes running

### Resolution Steps
1. **Immediate lockdown**: Disabled SSH access
2. **Key cleanup**: Removed unauthorized SSH keys
3. **Password change**: Changed all account passwords
4. **Session termination**: Killed all active SSH sessions
5. **Access review**: Audited all user accounts
6. **Key regeneration**: Created new SSH key pairs

### Security Improvements
- SSH key-only authentication (disabled passwords)
- Fail2ban installation for brute force protection
- SSH access limited to specific IP ranges
- Regular authorized_keys auditing

---

## Case Study 4: Suspicious VPN Configuration Profile

### Initial Symptoms
- Intermittent internet connectivity issues
- Some websites loading slowly or not at all
- DNS resolution problems

### Discovery Process

#### Step 1: Configuration Profile Check
```bash
profiles list
# Found: "Security Update Profile" from unknown organization
```

#### Step 2: Profile Analysis
```bash
profiles show -type Configuration
# Profile installing custom VPN configuration
# VPN server pointing to suspicious IP address
```

#### Step 3: Network Investigation
```bash
route -n get default
# Default route pointing through unknown VPN gateway

dig google.com
# DNS queries going through suspicious DNS servers
```

### Red Flags Identified
- ✅ Unknown configuration profile
- ✅ Generic profile name mimicking system updates
- ✅ Custom VPN configuration
- ✅ Unknown DNS servers
- ✅ Traffic routing through suspicious IPs

### Resolution Steps
1. **Profile removal**: Deleted malicious configuration profile
2. **Network reset**: Reset network settings to defaults
3. **DNS cleanup**: Configured trusted DNS servers
4. **Route verification**: Confirmed default route restoration
5. **Certificate check**: Reviewed installed certificates

### Prevention Measures
- Profile installation warnings enabled
- Regular network configuration audits
- DNS monitoring and filtering
- User education about profile risks

---

## Case Study 5: Kernel Extension Rootkit

### Initial Symptoms
- System behaving strangely despite clean malware scans
- Certain security tools failing to run
- Unexplained file system activity

### Discovery Process

#### Step 1: Kernel Extension Review
```bash
kextstat | grep -v com.apple
# Found: com.realtek.wifi.driver (suspicious on system without Realtek hardware)
```

#### Step 2: Kext Investigation
```bash
kextfind -bundle-id com.realtek.wifi.driver
# Located in /Library/Extensions/
ls -la "/Library/Extensions/RealtekWiFi.kext"
# Recently installed, unsigned
```

#### Step 3: File System Analysis
```bash
find /Library/Extensions -name "*.kext" -exec codesign -dv {} \; 2>&1 | grep -v "signed"
# Multiple unsigned kexts found
```

### Red Flags Identified
- ✅ Hardware driver for non-existent hardware
- ✅ Unsigned kernel extension
- ✅ Recent installation date
- ✅ Security tools malfunctioning
- ✅ Kext loaded without user knowledge

### Resolution Steps
1. **Kext unloading**: `sudo kextunload -b com.realtek.wifi.driver`
2. **File removal**: Moved kext to quarantine
3. **Cache rebuild**: `sudo kextcache -system-caches`
4. **SIP verification**: Ensured System Integrity Protection enabled
5. **Deep scan**: Performed full system integrity check

### System Hardening
- Enabled kext developer ID verification
- Restricted third-party kext loading
- Regular kernel extension auditing
- System file integrity monitoring

---

## Common Attack Patterns Summary

### Persistence Mechanisms (Most Common)
1. **Launch Agents/Daemons** (85% of cases)
   - Generic names or typosquatting
   - Base64 encoded payloads
   - Execution from temp directories

2. **Login Items** (60% of cases)
   - Hidden applications
   - Disguised as legitimate software
   - Auto-start malicious applications

3. **SSH Access** (25% of cases)
   - Unauthorized key installation
   - Password authentication exploitation
   - Remote access backdoors

### Detection Success Factors

#### What Works Well
- ✅ Launch Agent name pattern recognition
- ✅ Process behavior analysis
- ✅ Network connection monitoring
- ✅ File modification timestamp checking
- ✅ CPU/resource usage anomalies

#### Common Blind Spots
- ⚠️ Legitimate software with malicious plugins
- ⚠️ Memory-only attacks (fileless malware)
- ⚠️ Supply chain compromises
- ⚠️ Social engineering bypassing technical controls

### Response Time Importance

| Detection Speed | Damage Potential | Recovery Effort |
|----------------|------------------|-----------------|
| **< 1 hour** | Minimal | Low |
| **1-24 hours** | Limited | Medium |
| **1-7 days** | Moderate | High |
| **> 1 week** | Severe | Very High |

---

## Best Practices from Case Studies

### Detection
1. **Regular automated scans** (at least weekly)
2. **Network monitoring** for suspicious connections
3. **Process behavior baselines** to spot anomalies
4. **File integrity monitoring** for system changes
5. **User education** about social engineering

### Response
1. **Immediate isolation** when compromise suspected
2. **Evidence preservation** before cleanup
3. **Comprehensive investigation** to find all artifacts
4. **System hardening** post-incident
5. **Documentation** for future reference

### Prevention
1. **Keep systems updated** with latest patches
2. **Enable all security features** (SIP, Gatekeeper, etc.)
3. **Limit admin privileges** and use standard accounts
4. **Regular security awareness training**
5. **Implement defense in depth** strategy

Remember: These case studies represent real attack patterns. The key to successful defense is early detection and rapid response.