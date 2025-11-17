# macOS Security Diagnostics Suite

A comprehensive collection of security diagnostic tools for macOS systems, designed to help identify potential security issues, suspicious activities, and system compromises.

## 🚨 Important Notice

These scripts are **READ-ONLY** diagnostic tools. They:
- ✅ Collect system information for security analysis
- ✅ Help identify potential security issues
- ❌ Do NOT modify any system settings
- ❌ Do NOT delete or change any files
- ❌ Do NOT require root/admin access (except for specific deep checks)

## 📁 Repository Structure

```
macos-security-diagnostics/
├── scripts/               # All executable scripts
│   ├── full-diagnostics/  # Complete system scans
│   ├── one-liners/       # Quick command-line checks
│   └── utilities/        # Helper tools and parsers
├── documentation/        # Guides and references
├── examples/            # Sample outputs and case studies
└── tools/              # Automation and analysis tools
```

## 🚀 Quick Start

### Option 1: Full System Scan (GUI-friendly)
1. Navigate to `scripts/full-diagnostics/`
2. Double-click `macos-security-diagnostics.command`
3. Report will be saved to your Desktop

### Option 2: Command Line Full Scan
```bash
cd scripts/full-diagnostics/
bash macos-security-triage.sh
```

### Option 3: Quick One-Liner Checks
See `scripts/one-liners/security-oneliners.md` for individual commands you can copy/paste.

## 📊 What These Scripts Check

### System Persistence Mechanisms
- Launch Agents/Daemons
- Login Items
- Kernel Extensions (kexts)
- Cron jobs

### Network Security
- Active network connections
- Listening ports and services
- Remote access status
- SSH configuration

### System Integrity
- System Integrity Protection (SIP) status
- Gatekeeper status
- FileVault encryption
- Firewall configuration

### Authentication & Access
- SSH keys and authorized_keys
- Recent authentication events
- Configuration profiles
- Screen sharing status

## 🔍 Understanding Results

For detailed information on interpreting scan results, see:
- 📖 [Interpretation Guide](documentation/interpretation-guide.md) - What each section means
- 🚩 [Red Flags Guide](documentation/red-flags.md) - Specific indicators of compromise
- 🛠️ [Remediation Steps](documentation/remediation-steps.md) - How to fix issues

## ⚠️ Common Red Flags

Quick indicators that warrant immediate investigation:

| Finding | Risk Level | Example |
|---------|------------|---------|
| Non-Apple Launch Agents | 🔴 High | `com.Wlan.Software.plist` |
| Unsigned kernel extensions | 🔴 High | Realtek, HoRNDIS drivers |
| Unknown SSH keys | 🔴 High | Unexpected entries in authorized_keys |
| Suspicious network listeners | 🟡 Medium | Unknown services on high ports |
| Modified system files | 🟡 Medium | Recent changes to /Library/Launch* |
| Remote login enabled | 🟡 Medium | When not intentionally configured |

## 📋 Output Files

Scans generate timestamped reports on your Desktop:
- `security-scan-YYYYMMDD-HHMMSS.txt` - Full diagnostic reports
- `security-report-HHMM.txt` - Quick scan summaries

## 🔧 Advanced Features

### Automated Scanning
Set up regular security scans using the included LaunchAgent:
```bash
cp tools/automation/scheduled-scan.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/scheduled-scan.plist
```

### Comparing Scans
Use the diff tool to identify changes between scans:
```bash
tools/analysis/compare-scans.sh scan1.txt scan2.txt
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Test scripts thoroughly on clean systems
2. Document any new checks added
3. Update interpretation guides for new features
4. Ensure scripts remain read-only

## 📜 License

MIT License - See LICENSE file for details

## ⚡ Emergency Response

If you suspect an active compromise:

1. **Disconnect from network** (turn off WiFi/unplug ethernet)
2. **Run full diagnostic** and save results
3. **Document everything** (screenshots, timestamps, symptoms)
4. **Contact IT Security** or appropriate incident response team
5. **Do NOT** attempt to remove suspicious files without guidance

## 📞 Support

- Report issues: [GitHub Issues](https://github.com/yourusername/macos-security-diagnostics/issues)
- Security concerns: Contact your organization's security team

## 🔄 Version History

- v1.1.0 - Reorganized structure, added documentation
- v1.0.0 - Initial release with core diagnostic scripts

---

**Remember**: These tools help identify issues but should be used alongside proper security practices and professional incident response when needed.