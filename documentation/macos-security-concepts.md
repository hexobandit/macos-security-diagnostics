# macOS Security Concepts

Understanding the security architecture and concepts of macOS is essential for effective security monitoring and incident response.

## Core Security Features

### System Integrity Protection (SIP)
**What it is:** A security feature that prevents modification of critical system files and directories, even by root.

**Protected Areas:**
- `/System/`
- `/usr/` (except `/usr/local/`)
- `/bin/`, `/sbin/`
- Applications bundled with macOS

**Why it matters:** Disabled SIP is a major red flag as it's required for some rootkits to function.

**Check status:**
```bash
csrutil status
```

### Gatekeeper
**What it is:** Verifies downloaded applications before they run.

**Protection levels:**
- **App Store only** - Only Mac App Store apps
- **App Store and identified developers** - Default setting
- **Anywhere** - No verification (dangerous)

**Bypass methods attackers use:**
- Code signing with stolen certificates
- Right-click "Open" to bypass warnings
- Social engineering to disable Gatekeeper

### FileVault
**What it is:** Full-disk encryption for macOS.

**Security benefits:**
- Protects data if device is stolen
- Prevents offline attacks on user passwords
- Required for secure hibernation

**Considerations:**
- Must be enabled before compromise
- Password/key recovery is critical

### Secure Boot
**What it is:** Ensures only trusted software loads during boot process.

**Components:**
- **Boot ROM** - Apple's immutable code
- **iBoot** - Secondary bootloader
- **Kernel** - Verified macOS kernel

**Why it matters:** Prevents bootkit/rootkit persistence at boot level.

## Authentication & Authorization

### User Account Types

#### Standard User
- Limited administrative privileges
- Cannot install system-wide software
- Cannot modify system settings
- **Best practice:** Daily use should be standard user

#### Administrator
- Can install software
- Can modify system settings
- Can add/remove users
- **Risk:** Full system access if compromised

#### Root User
- Disabled by default on modern macOS
- Unrestricted access to everything
- **Major red flag:** Enabled root user without justification

### Keychain
**What it is:** Encrypted storage for passwords and certificates.

**Types:**
- **Login keychain** - User's passwords
- **System keychain** - System certificates
- **iCloud keychain** - Synced across devices

**Security implications:**
- Malware may attempt to access stored passwords
- Keychain dumps are valuable to attackers
- Two-factor authentication adds protection

## Code Signing & Notarization

### Code Signing
**Purpose:** Verifies the identity of software developers.

**Process:**
1. Developer signs app with certificate
2. macOS verifies signature before execution
3. Warning shown for unsigned apps

**Bypass techniques:**
- Stolen certificates
- Ad-hoc signing
- Self-signed certificates

### Notarization
**What it is:** Apple's malware scanning service.

**Process:**
1. Developer submits app to Apple
2. Apple scans for malware
3. Apple issues notarization ticket
4. macOS checks ticket online

**Why it matters:** Additional layer beyond code signing.

## Network Security

### Application Firewall
**What it is:** Controls network access for applications.

**Modes:**
- **Off** - No restrictions
- **On** - Blocks unauthorized incoming connections
- **Stealth mode** - Doesn't respond to probes

**Best practices:**
- Enable firewall
- Review application exceptions
- Enable stealth mode

### Network Location Services
**What it is:** Automatically configures network settings based on location.

**Security considerations:**
- Can expose network configurations
- May auto-join known networks
- Useful for detecting unauthorized network changes

## System Extensions & Kernel

### Kernel Extensions (kexts)
**What they are:** Kernel-level drivers and extensions.

**Security evolution:**
- **Legacy kexts** - Full kernel access (high risk)
- **System Extensions** - Modern, sandboxed alternative
- **User space drivers** - Safest option

**Common legitimate kexts:**
- Virtualization software
- Security tools
- Hardware drivers

**Common malicious kexts:**
- Realtek drivers (often fake)
- HoRNDIS (USB tethering)
- Generic/unsigned drivers

### System Extensions (Modern)
**Advantages:**
- Run in user space
- Sandboxed
- Can be disabled by user
- Better crash isolation

**Types:**
- **Network extensions** - VPN, content filtering
- **Endpoint security** - Antivirus, monitoring
- **Driver kit** - Hardware drivers

## Persistence Mechanisms

### Launch Services
**Components:**
- **LaunchAgents** - User context, runs when user logs in
- **LaunchDaemons** - System context, runs at boot
- **Login Items** - Applications that auto-start

**Locations by priority:**
1. `~/Library/LaunchAgents/` - User-specific
2. `/Library/LaunchAgents/` - System-wide, user context
3. `/Library/LaunchDaemons/` - System-wide, root context
4. `/System/Library/LaunchAgents/` - Apple's agents
5. `/System/Library/LaunchDaemons/` - Apple's daemons

**Key plist properties:**
- `RunAtLoad` - Start immediately when loaded
- `KeepAlive` - Restart if process dies
- `StartInterval` - Run every N seconds
- `StartCalendarInterval` - Run at specific times

### Cron Jobs
**What they are:** Time-based job scheduler (Unix legacy).

**Locations:**
- `/etc/crontab` - System crontab
- `/usr/lib/cron/tabs/` - User crontabs
- `crontab -l` - Current user's crontab

**Modern alternatives:**
- LaunchDaemons with `StartCalendarInterval`
- More reliable than cron on macOS

## File System Security

### Extended Attributes
**What they are:** Metadata attached to files.

**Security-relevant attributes:**
- `com.apple.quarantine` - Downloaded files
- `com.apple.metadata:kMDItemWhereFroms` - Download source
- `com.apple.security.cs.allow-jit` - JIT compilation

**Forensic value:**
- Track file origins
- Identify quarantine bypass
- Understand file modification history

### File Permissions
**Standard Unix permissions:**
- Read, write, execute for user/group/other
- Special permissions (setuid, setgid, sticky bit)

**macOS additions:**
- **ACLs** - Access Control Lists
- **File flags** - Additional attributes
- **SIP protection** - System file protection

### Spotlight & Metadata
**What it is:** System-wide file indexing and search.

**Security implications:**
- Indexes file content (privacy concern)
- Can reveal hidden files in search
- Metadata useful for forensics
- Can be disabled for privacy

## Privacy & Permissions

### Privacy Database (TCC)
**What it is:** Transparency, Consent, and Control framework.

**Protected resources:**
- Contacts, Calendar, Photos
- Camera, Microphone
- Location Services
- Full Disk Access

**Database location:**
- `/Library/Application Support/com.apple.TCC/TCC.db`

**Security relevance:**
- Malware may request excessive permissions
- Social engineering to grant access
- Unexpected permission requests are red flags

### Sandboxing
**What it is:** Restricts application access to system resources.

**Types:**
- **App Sandbox** - Mac App Store requirement
- **Container** - Isolated file system view
- **XPC** - Inter-process communication

**Benefits:**
- Limits malware damage
- Isolates applications
- Prevents unauthorized system access

## Logging & Monitoring

### Unified Logging
**What it is:** Centralized logging system introduced in macOS Sierra.

**Key commands:**
```bash
log show --last 1h               # Last hour of logs
log stream                       # Live log stream
log show --predicate 'process == "sshd"'  # Filter by process
```

**Log categories:**
- **Security** - Authentication, authorization
- **Network** - Network activity
- **Process** - Process creation/termination
- **File system** - File access (if enabled)

### Traditional Logs
**Locations:**
- `/var/log/` - System logs
- `~/Library/Logs/` - User application logs
- `/Library/Logs/` - System application logs

**Key log files:**
- `auth.log` - Authentication events
- `system.log` - General system messages
- `kernel.log` - Kernel messages

## Security Monitoring Best Practices

### Baseline Establishment
1. **Clean system scan** - Establish normal state
2. **Regular monitoring** - Weekly/monthly scans
3. **Change detection** - Compare against baseline
4. **Update baseline** - After legitimate changes

### Key Indicators to Monitor
1. **Persistence mechanisms** - New launch agents/daemons
2. **Network activity** - Unexpected connections
3. **Process behavior** - High CPU/memory usage
4. **File system changes** - New executables in system paths
5. **Permission changes** - New TCC grants

### Response Procedures
1. **Immediate isolation** - Disconnect network if compromise suspected
2. **Evidence preservation** - Save logs and system state
3. **Investigation** - Determine scope and impact
4. **Containment** - Stop malicious activity
5. **Eradication** - Remove malicious artifacts
6. **Recovery** - Restore normal operations
7. **Lessons learned** - Improve detection/prevention

## Threat Landscape

### Common Attack Vectors
1. **Phishing emails** - Malicious attachments/links
2. **Software vulnerabilities** - Unpatched applications
3. **Supply chain attacks** - Compromised software updates
4. **Social engineering** - Trick users into installing malware
5. **Physical access** - Direct system compromise

### Malware Types
1. **Adware** - Unwanted advertisements (OSX/Shlayer)
2. **Cryptocurrency miners** - Resource theft
3. **Backdoors** - Remote access tools
4. **Information stealers** - Password/data theft
5. **Ransomware** - File encryption for payment

### Advanced Persistent Threats (APTs)
**Characteristics:**
- Long-term presence
- Stealthy operation
- Targeted objectives
- Multiple attack stages
- Sophisticated techniques

**Detection strategies:**
- Behavioral analysis
- Network monitoring
- Regular system audits
- Threat intelligence integration

Remember: Security is a process, not a product. Regular monitoring and quick response are key to maintaining system security.