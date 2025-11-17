# macOS Security Diagnostics - Interpretation Guide

This guide explains how to interpret the output from the security diagnostic scripts and identify potential security issues.

## Table of Contents
1. [Launch Agents & Daemons](#1-launch-agents--daemons)
2. [Kernel Extensions (kexts)](#2-kernel-extensions-kexts)
3. [Login Items](#3-login-items)
4. [Process Analysis](#4-process-analysis)
5. [Network Connections](#5-network-connections)
6. [SSH Configuration](#6-ssh-configuration)
7. [Remote Access](#7-remote-access)
8. [Configuration Profiles](#8-configuration-profiles)
9. [System Modifications](#9-system-modifications)
10. [Authentication Logs](#10-authentication-logs)
11. [Security Settings](#11-security-settings)

---

## 1. Launch Agents & Daemons

### What They Are
- **LaunchAgents**: Programs that run when a user logs in
- **LaunchDaemons**: System-level programs that run at boot

### Where to Find Them
```
~/Library/LaunchAgents     (User-specific)
/Library/LaunchAgents      (System-wide, user context)
/Library/LaunchDaemons     (System-wide, root context)
/System/Library/Launch*    (Apple's built-in - usually safe)
```

### What's Normal
✅ Files starting with `com.apple.*`
✅ Known software you installed (Adobe, Microsoft, Google)
✅ Backup software (Time Machine, Backblaze, CrashPlan)
✅ Development tools (Docker, Homebrew)

### Red Flags
🔴 **Critical**
- Files named `com.Wlan.Software.plist` or variants
- Generic names like `com.test.plist`, `com.update.plist`
- Misspelled Apple services (`com.appl.update`)
- Base64 encoded program arguments
- Programs running from `/tmp`, `/var/tmp`, or user Downloads

🟡 **Suspicious**
- Recently modified files (check timestamps)
- Files with unusual permissions (not owned by root or current user)
- Programs with `RunAtLoad` set to true that you don't recognize
- Hidden file references (paths starting with `.`)

### Example Analysis
```xml
<!-- SUSPICIOUS: Generic name, runs at load, executes from tmp -->
<key>Label</key>
<string>com.updater.service</string>
<key>ProgramArguments</key>
<array>
    <string>/tmp/updater</string>
</array>
<key>RunAtLoad</key>
<true/>
```

---

## 2. Kernel Extensions (kexts)

### What They Are
Low-level drivers that extend the kernel's functionality.

### What's Normal
✅ Apple kexts (`com.apple.*`)
✅ Virtualization software (VMware, Parallels, VirtualBox)
✅ Security software (legitimate antivirus)
✅ Hardware drivers from known manufacturers

### Red Flags
🔴 **Critical**
- `Realtek` or `RTWLAN` drivers (often malicious)
- `HoRNDIS` (USB tethering driver, often exploited)
- Unsigned kexts on modern macOS
- Kexts loaded from user directories

🟡 **Suspicious**
- Any non-Apple kext you didn't explicitly install
- Kexts with generic names
- Multiple similar kexts (could indicate persistence)

### How to Check
```bash
kextstat | grep -v "com.apple"
```

---

## 3. Login Items

### What They Are
Applications that launch automatically when you log in.

### What's Normal
✅ Apps you use daily (Slack, Spotify, Dropbox)
✅ Menu bar utilities you installed
✅ Cloud storage clients
✅ Password managers

### Red Flags
🔴 **Critical**
- Items you don't recognize at all
- Command-line tools (not typical GUI apps)
- Items with generic names like "Updater" or "Helper"

🟡 **Suspicious**
- Multiple entries for the same app
- Hidden applications (names starting with `.`)
- Apps launching from unusual locations

---

## 4. Process Analysis

### What to Look For
The script shows processes not owned by root or the current user.

### What's Normal
✅ System users starting with `_` (e.g., `_spotlight`, `_mdnsresponder`)
✅ Processes for other logged-in users (in multi-user systems)

### Red Flags
🔴 **Critical**
- Processes running as `nobody` or `daemon` that aren't system services
- Cryptocurrency miners (high CPU usage, names like `xmrig`, `minerd`)
- Processes with suspicious names trying to look legitimate

🟡 **Suspicious**
- Unusually high number of processes for a single non-system user
- Processes with very long or obfuscated names
- Multiple instances of the same unusual process

---

## 5. Network Connections

### Listening Ports (LISTEN)

#### Common Legitimate Ports
```
Port 22    - SSH (if you use remote access)
Port 80    - HTTP server
Port 443   - HTTPS server
Port 3306  - MySQL
Port 5432  - PostgreSQL
Port 5900  - Screen Sharing/VNC
Port 8080  - Alternative HTTP
```

#### What's Normal
✅ Development servers (localhost/127.0.0.1)
✅ Known applications (Spotify, Discord, Slack)
✅ System services on standard ports

#### Red Flags
🔴 **Critical**
- Services listening on ALL interfaces (0.0.0.0) that shouldn't be
- High numbered ports (>10000) with unknown services
- Known backdoor ports (4444, 4445, 31337)

### Established Connections

#### What's Normal
✅ Connections to known services (iCloud, Google, Microsoft)
✅ CDN addresses (Cloudflare, Akamai)
✅ Your organization's servers

#### Red Flags
🔴 **Critical**
- Connections to IP addresses (not domains) in unusual countries
- Multiple connections to the same unknown IP
- Connections on non-standard ports to unknown hosts

🟡 **Suspicious**
- Excessive number of connections from a single process
- Connections to recently registered domains
- IRC connections (ports 6667, 6697) if you don't use IRC

---

## 6. SSH Configuration

### authorized_keys File

#### What's Normal
✅ Your own public keys (you should recognize the comment at the end)
✅ Keys from your other devices
✅ IT department keys (in corporate environments)

#### Red Flags
🔴 **Critical**
- Keys you don't recognize at all
- Keys with no identifying comment
- Keys added recently that you didn't add
- Multiple suspicious keys

🟡 **Suspicious**
- Very old keys you may have forgotten
- Keys with generic comments like "user@localhost"

### SSH Config Files

Check for:
- Unexpected `ProxyCommand` entries
- Unknown `IdentityFile` entries
- Suspicious `RemoteForward` or `LocalForward` rules

---

## 7. Remote Access

### Remote Login Status

#### What's Normal
✅ "Remote Login: Off" (most common for personal Macs)
✅ "Remote Login: On" if you specifically use SSH

#### Red Flags
🔴 **Critical**
- Remote Login enabled without your knowledge
- Screen Sharing enabled without your knowledge
- Remote Management configured unexpectedly

---

## 8. Configuration Profiles

### What They Are
System configurations installed by organizations or MDM software.

### What's Normal
✅ Profiles from your employer (on work computers)
✅ Profiles from schools/universities
✅ Profiles you installed for VPN or email

### Red Flags
🔴 **Critical**
- Profiles you don't recognize
- Profiles with generic names
- Profiles that can't be removed
- Profiles installing certificates

---

## 9. System Modifications

### Recent File Changes

The script checks for files modified in the last 48 hours in system directories.

#### What's Normal
✅ System updates from Apple
✅ App updates you performed
✅ Your own configuration changes

#### Red Flags
🔴 **Critical**
- New files in `/Library/LaunchAgents` or `/Library/LaunchDaemons`
- Modifications to system binaries
- New or modified files in `/usr/local/bin`

🟡 **Suspicious**
- Large number of changes without corresponding system/app updates
- Hidden files (starting with `.`) in system directories

---

## 10. Authentication Logs

### What to Look For
- Failed login attempts
- Successful logins at unusual times
- Authentication from unknown sources

### What's Normal
✅ Your regular login times
✅ Password prompts from legitimate apps
✅ System authentication for updates

### Red Flags
🔴 **Critical**
- Multiple failed login attempts followed by success
- Logins during times you weren't using the computer
- Authentication requests from unknown processes

---

## 11. Security Settings

### System Integrity Protection (SIP)

#### Normal State
✅ **Enabled** - This is the default and recommended setting

#### Red Flags
🔴 **Disabled** - Only if you didn't disable it yourself for development

### Firewall

#### Normal State
✅ **Enabled** - Recommended for all users
⚠️ **Disabled** - Acceptable only on trusted networks

### FileVault

#### Normal State
✅ **Enabled** - Recommended for laptop users
⚠️ **Disabled** - Acceptable for desktops in secure locations

### Gatekeeper

#### Normal State
✅ **Enabled** - Default and recommended

#### Red Flags
🔴 **Disabled** - Significantly reduces security

---

## Severity Levels Explained

### 🔴 Critical (Immediate Action Required)
- Strong indicators of compromise
- Known malware signatures
- Unauthorized remote access
- Suspicious kernel modifications

### 🟡 Warning (Investigation Needed)
- Unusual but possibly legitimate
- Unknown software from uncertain sources
- Configuration changes you don't remember
- Anomalies that need verification

### ✅ Normal (Expected Behavior)
- Known software and services
- Standard system configurations
- Your regular usage patterns

---

## Next Steps

If you find suspicious items:

1. **Document Everything**
   - Screenshot the findings
   - Save the diagnostic output
   - Note when you first noticed issues

2. **Don't Panic**
   - Not all unknown items are malicious
   - Some may be legitimate but poorly documented software

3. **Investigate Further**
   - Google unknown process/file names
   - Check file creation dates
   - Look for associated files

4. **Get Help if Needed**
   - See [Remediation Steps](remediation-steps.md) for fixing issues
   - Contact IT security for corporate machines
   - Consider professional help for confirmed malware

---

## Quick Reference Checklist

When reviewing diagnostic output, check for:

- [ ] Non-Apple items in LaunchAgents/Daemons
- [ ] Unsigned or suspicious kernel extensions
- [ ] Unknown login items
- [ ] Processes you don't recognize
- [ ] Services listening on unusual ports
- [ ] Established connections to unknown IPs
- [ ] SSH keys you didn't add
- [ ] Remote access enabled unexpectedly
- [ ] Unknown configuration profiles
- [ ] Recent system file modifications
- [ ] Unusual authentication events
- [ ] Disabled security features

Remember: When in doubt, investigate further before taking action.