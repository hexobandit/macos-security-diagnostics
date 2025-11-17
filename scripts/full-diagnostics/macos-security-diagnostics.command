#!/bin/bash

# macOS Security Triage Script - Double-Click Version
# Based on original macos-security-triage.sh
# This is READ-ONLY - it doesn't change anything on your system

OUTPUT_FILE="$HOME/Desktop/security-scan-$(date +%Y%m%d-%H%M%S).txt"

{
echo "==============================="
echo "macOS Security Triage Report"
echo "==============================="
echo "Date: $(date)"
echo "User: $USER"
echo "Hostname: $(hostname)"
echo ""
echo "This is a READ-ONLY scan - nothing will be changed or deleted"
echo "Output will be saved to: $OUTPUT_FILE"
echo ""

echo "==============================="
echo "1. Suspicious Launch Agents"
echo "==============================="
echo "--- User Launch Agents ---"
ls -al ~/Library/LaunchAgents 2>/dev/null || echo "No user launch agents directory"
echo ""
echo "--- System Launch Agents ---"
ls -al /Library/LaunchAgents 2>/dev/null
echo ""
echo "--- System Launch Daemons ---"
ls -al /Library/LaunchDaemons 2>/dev/null
echo ""

echo "----- Showing contents of non-Apple LaunchAgents -----"
for f in /Library/LaunchAgents/*.plist; do
    if [[ -f "$f" ]] && ! grep -q "com.apple" "$f" 2>/dev/null; then
        echo ">> $f"
        cat "$f" 2>/dev/null | head -50
        echo ""
    fi
done

echo "==============================="
echo "2. Loaded kexts (Realtek, HoRNDIS, unsigned)"
echo "==============================="
kextstat 2>/dev/null | grep -Ei "realtek|rtwlan|horndis|unsigned" || echo "No suspicious kexts found"
echo ""

echo "==============================="
echo "3. Persistence via Login Items"
echo "==============================="
osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || echo "Could not retrieve login items"
echo ""

echo "==============================="
echo "4. Suspicious Processes (non-root, non-user)"
echo "==============================="
ps aux | egrep -v "root|$USER" | head -20
echo ""

echo "==============================="
echo "5. Network Listeners"
echo "==============================="
lsof -i -P 2>/dev/null | grep LISTEN || echo "Could not check network listeners"
echo ""

echo "==============================="
echo "6. Active outbound connections"
echo "==============================="
netstat -anvp tcp 2>/dev/null | grep ESTABLISHED | head -30 || echo "No active connections found"
echo ""

echo "==============================="
echo "7. SSH keys + config"
echo "==============================="
if [[ -d ~/.ssh ]]; then
    ls -al ~/.ssh
    echo "--- authorized_keys ---"
    if [[ -f ~/.ssh/authorized_keys ]]; then
        cat ~/.ssh/authorized_keys
    else
        echo "No authorized_keys file found"
    fi
else
    echo "No SSH directory found"
fi
echo ""

echo "==============================="
echo "8. Remote Login / Screen Sharing"
echo "==============================="
systemsetup -getremotelogin 2>/dev/null || echo "Could not check remote login (needs admin rights)"
echo "--- Screen Sharing Status ---"
launchctl list 2>/dev/null | grep -i screensharing && echo "Screen sharing appears to be ENABLED" || echo "Screen sharing appears to be disabled"
echo ""

echo "==============================="
echo "9. Configuration Profiles"
echo "==============================="
profiles list 2>/dev/null || echo "No configuration profiles found"
echo ""

echo "==============================="
echo "10. Recent system modifications (last 48h)"
echo "==============================="
echo "Checking for recently modified files in system locations..."
find /Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents \
    -type f -mtime -2 -exec ls -la {} \; 2>/dev/null | head -50 || \
    echo "Could not check recent modifications"
echo ""

echo "==============================="
echo "11. Recent auth events (last 2h)"
echo "==============================="
log show --last 2h 2>/dev/null | grep -i "auth" | head -200 || echo "Could not retrieve auth logs"
echo ""

echo "==============================="
echo "12. Additional Security Checks"
echo "==============================="
echo "--- Firewall Status ---"
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "Could not check firewall"
echo ""
echo "--- System Integrity Protection ---"
csrutil status 2>/dev/null || echo "Could not check SIP"
echo ""
echo "--- FileVault Status ---"
fdesetup status 2>/dev/null || echo "Could not check FileVault"
echo ""
echo "--- Gatekeeper Status ---"
spctl --status 2>/dev/null || echo "Could not check Gatekeeper"
echo ""

echo "==============================="
echo "13. Summary"
echo "==============================="
echo "Output collected. Review for:"
echo "- Unknown LaunchAgents"
echo "- Realtek/HoRNDIS kexts"
echo "- Unknown processes"
echo "- Unexpected SSH keys"
echo "- Strange network connections"
echo ""
echo "SPECIFICALLY CHECK FOR:"
echo "- Files named 'Wlan.Software' in LaunchAgents"
echo "- Non-Apple .plist files with recent modification dates"
echo "- Unexpected listening ports"
echo "- SSH authorized_keys you didn't add"
echo "- Remote access enabled without your knowledge"
echo ""
echo "Report saved to: $OUTPUT_FILE"

} 2>&1 | tee "$OUTPUT_FILE"

echo ""
echo "==============================="
echo "Scan Complete!"
echo "==============================="
echo "Report has been saved to your Desktop:"
echo "$OUTPUT_FILE"
echo ""
echo "You can:"
echo "1. Review the report for suspicious items"
echo "2. Share it with IT security for analysis"
echo "3. Compare with future scans to detect changes"
echo ""
echo "Opening Desktop folder..."
open "$HOME/Desktop/"