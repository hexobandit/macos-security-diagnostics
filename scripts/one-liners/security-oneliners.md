# macOS Security Check One-Liners
## Copy any line below and paste into Terminal

### Quick Complete Scan (saves to Desktop)
```bash
{ echo "=== macOS Security Scan $(date) ==="; echo "Launch Agents:"; ls -la ~/Library/LaunchAgents /Library/LaunchAgents 2>/dev/null; echo "Login Items:"; osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null; echo "Network Listeners:"; lsof -i -P | grep LISTEN; echo "SSH Keys:"; ls -la ~/.ssh 2>/dev/null; } | tee ~/Desktop/security-scan-$(date +%Y%m%d).txt
```

### 1. Check Launch Agents (Auto-start Programs)
```bash
echo "=== LAUNCH AGENTS ===" && ls -la ~/Library/LaunchAgents 2>/dev/null | grep -v "^total" && echo "=== SYSTEM AGENTS ===" && ls -la /Library/LaunchAgents 2>/dev/null | grep -v "^total" && echo "=== DAEMONS ===" && ls -la /Library/LaunchDaemons 2>/dev/null | head -20
```

### 2. Show Non-Apple Launch Agent Contents
```bash
for f in /Library/LaunchAgents/*.plist; do [[ ! "$f" =~ "com.apple" ]] && echo "=== $f ===" && plutil -p "$f" 2>/dev/null | head -20; done
```

### 3. Check Login Items
```bash
osascript -e 'tell application "System Events" to get the name of every login item' && echo "Total login items: $(osascript -e 'tell application "System Events" to get the count of login items')"
```

### 4. Check Loaded Kernel Extensions
```bash
kextstat | grep -v "com.apple" | awk '{print $6}' | sort -u | while read k; do echo "Non-Apple kext: $k"; done
```

### 5. Network Listeners (What's Listening for Connections)
```bash
lsof -i -P | grep LISTEN | awk '{print $1, $2, $3, $9}' | column -t | head -20
```

### 6. Active Network Connections
```bash
netstat -an | grep ESTABLISHED | awk '{print $4, "->", $5}' | grep -v "127.0.0.1" | sort -u | head -20
```

### 7. Check SSH Configuration
```bash
[[ -d ~/.ssh ]] && { echo "SSH Files:"; ls -la ~/.ssh; [[ -f ~/.ssh/authorized_keys ]] && { echo "=== AUTHORIZED KEYS ==="; cat ~/.ssh/authorized_keys; } || echo "No authorized_keys"; } || echo "No SSH directory"
```

### 8. Non-System Processes
```bash
ps aux | grep -v "^root\|^_" | awk '{print $1, $2, $11}' | grep -v "^USER" | head -20
```

### 9. Remote Access Status
```bash
echo "Remote Login: $(systemsetup -getremotelogin 2>&1 | grep -o 'On\|Off')" && echo "Screen Sharing: $([[ $(launchctl list | grep -c screensharing) -gt 0 ]] && echo "On" || echo "Off")"
```

### 10. Firewall Status
```bash
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled" | { read s; echo "Firewall: $s"; }
```

### 11. Configuration Profiles
```bash
profiles list 2>/dev/null | grep -v "There are no" || echo "No configuration profiles installed"
```

### 12. Recently Modified System Files (24h)
```bash
find /Library/Launch* ~/Library/LaunchAgents -type f -mtime -1 -ls 2>/dev/null | awk '{print $11}' | while read f; do echo "Recent: $f ($(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f"))"; done
```

### 13. Check for Suspicious "Wlan.Software"
```bash
find /Library/Launch* ~/Library/LaunchAgents -name "*Wlan*" -o -name "*wlan*" 2>/dev/null | while read f; do echo "SUSPICIOUS: $f"; ls -la "$f"; done
```

### 14. Recent Authentication Events (1 hour)
```bash
log show --predicate 'process == "loginwindow" OR process == "SecurityAgent"' --last 1h 2>/dev/null | grep -E "Authentication|Login" | tail -20
```

### 15. Check System Integrity Protection (SIP)
```bash
csrutil status | grep -o "enabled\|disabled" | { read s; echo "System Integrity Protection: $s"; }
```

### 16. Show All Listening Ports with Process Names
```bash
sudo lsof -i -P | grep LISTEN | awk '{printf "%-15s %-6s %s\n", $1, $2, $9}' | sort -u
```

### 17. Check for Cron Jobs
```bash
{ crontab -l 2>/dev/null || echo "No user crontab"; } && { [[ -d /usr/lib/cron/tabs/ ]] && sudo ls -la /usr/lib/cron/tabs/ 2>/dev/null || echo "No system crontabs"; }
```

### 18. Full Security Report (All Checks)
```bash
bash -c 'echo "=== SECURITY REPORT $(date) ===" && echo -e "\n[LAUNCH AGENTS]" && ls -la /Library/LaunchAgents | grep -v "^total\|com.apple" && echo -e "\n[LOGIN ITEMS]" && osascript -e "tell application \"System Events\" to get the name of every login item" && echo -e "\n[NETWORK]" && lsof -i -P | grep LISTEN | head -10 && echo -e "\n[SSH]" && ls -la ~/.ssh 2>/dev/null && echo -e "\n[FIREWALL]" && /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate && echo -e "\n[SIP]" && csrutil status' | tee ~/Desktop/security-report-$(date +%H%M).txt
```

## How to Use:
1. Copy any command line above
2. Open Terminal (Applications > Utilities > Terminal)
3. Paste and press Enter
4. Review the output

## Red Flags to Look For:
- Files named `Wlan.Software` or similar
- Non-Apple kernel extensions (kexts)
- Unknown programs in Launch Agents
- SSH authorized_keys you didn't add
- Unexpected network listeners
- Remote login enabled when not needed
- Firewall disabled
- SIP disabled without reason