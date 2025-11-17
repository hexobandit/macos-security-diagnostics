#!/bin/bash
#
# macOS Security Triage Script (Read-Only)
# ----------------------------------------
# Collects system info for compromise analysis.
# Safe to run. Does NOT delete or change anything.
# Output is grouped so an AI can parse it easily.
#

echo "==============================="
echo "1. Suspicious Launch Agents"
echo "==============================="
ls -al ~/Library/LaunchAgents
ls -al /Library/LaunchAgents
ls -al /Library/LaunchDaemons
echo

echo "----- Showing contents of non-Apple LaunchAgents -----"
grep -L "Apple" /Library/LaunchAgents/* 2>/dev/null | while read f; do
    echo ">> $f"
    cat "$f"
    echo
done

echo "==============================="
echo "2. Loaded kexts (Realtek, HoRNDIS, unsigned)"
echo "==============================="
kextstat | grep -Ei "realtek|rtwlan|horndis|unsigned"
echo

echo "==============================="
echo "3. Persistence via Login Items"
echo "==============================="
osascript -e 'tell application "System Events" to get the name of every login item'
echo

echo "==============================="
echo "4. Suspicious Processes (non-root, non-user)"
echo "==============================="
ps aux | egrep -v "root|$USER" | head
echo

echo "==============================="
echo "5. Network Listeners"
echo "==============================="
lsof -i -P | grep LISTEN
echo

echo "==============================="
echo "6. Active outbound connections"
echo "==============================="
netstat -anvp tcp | grep ESTABLISHED
echo

echo "==============================="
echo "7. SSH keys + config"
echo "==============================="
ls -al ~/.ssh
echo "--- authorized_keys ---"
cat ~/.ssh/authorized_keys 2>/dev/null
echo

echo "==============================="
echo "8. Remote Login / Screen Sharing"
echo "==============================="
systemsetup -getremotelogin
echo "--- ARD RemoteManagement plist ---"
sudo defaults read /Library/Preferences/com.apple.RemoteManagement.plist 2>/dev/null
echo

echo "==============================="
echo "9. Configuration Profiles"
echo "==============================="
profiles list
echo

echo "==============================="
echo "10. Recent system modifications (last 48h)"
echo "==============================="
sudo find / -type f -mtime -2 -maxdepth 6 2>/dev/null | head -n 50
echo

echo "==============================="
echo "11. Recent auth events (last 2h)"
echo "==============================="
log show --last 2h | grep -i "auth" | head -n 200
echo

echo "==============================="
echo "12. Summary"
echo "==============================="
echo "Output collected. Review for:"
echo "- Unknown LaunchAgents"
echo "- Realtek/HoRNDIS kexts"
echo "- Unknown processes"
echo "- Unexpected SSH keys"
echo "- Strange network connections"
echo