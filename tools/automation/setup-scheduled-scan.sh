#!/bin/bash

# Setup script for automated security scanning
# This script helps users configure regular security scans

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLIST_TEMPLATE="$SCRIPT_DIR/scheduled-scan.plist"
USER_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.security.diagnostics.scheduled.plist"
PLIST_DEST="$USER_AGENTS_DIR/$PLIST_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [options]

Setup automated security scanning for macOS.

Options:
    -h, --help      Show this help
    -u, --uninstall Uninstall the scheduled scan
    -s, --status    Check if scheduled scan is active
    -t, --test      Run a test scan now
    
Configuration:
    The scan will run every Sunday at 2:00 AM
    Reports are saved to ~/Desktop/security-scan-TIMESTAMP.txt
    
Requirements:
    - macOS user account with admin privileges
    - Security diagnostics scripts in: $REPO_ROOT

Examples:
    $0                  # Install scheduled scan
    $0 --status         # Check if scan is active
    $0 --test           # Run immediate test scan
    $0 --uninstall      # Remove scheduled scan

EOF
}

# Check if LaunchAgent is loaded
is_loaded() {
    launchctl list | grep -q "$PLIST_NAME" 2>/dev/null
}

# Check if LaunchAgent file exists
is_installed() {
    [[ -f "$PLIST_DEST" ]]
}

# Generate the plist file with correct paths
generate_plist() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.security.diagnostics.scheduled</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>cd "$REPO_ROOT" && ./scripts/full-diagnostics/simple-security-check.command</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    
    <key>StandardOutPath</key>
    <string>/tmp/security-scan-scheduled.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/security-scan-scheduled.error</string>
    
    <key>RunAtLoad</key>
    <false/>
    
    <key>WorkingDirectory</key>
    <string>$REPO_ROOT</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>$HOME</string>
    </dict>
    
    <key>LimitLoadToSessionType</key>
    <array>
        <string>Aqua</string>
    </array>
    
    <key>KeepAlive</key>
    <false/>
    
    <key>ServiceDescription</key>
    <string>Automated weekly macOS security diagnostic scan</string>
</dict>
</plist>
EOF
}

# Install the scheduled scan
install_scan() {
    info "Setting up automated security scanning..."
    
    # Check if repo exists
    if [[ ! -d "$REPO_ROOT/scripts/full-diagnostics" ]]; then
        error "Security diagnostics scripts not found at: $REPO_ROOT"
        error "Please ensure you're running this from the correct directory."
        exit 1
    fi
    
    # Create LaunchAgents directory if it doesn't exist
    if [[ ! -d "$USER_AGENTS_DIR" ]]; then
        mkdir -p "$USER_AGENTS_DIR"
        info "Created LaunchAgents directory"
    fi
    
    # Unload existing if loaded
    if is_loaded; then
        info "Unloading existing scheduled scan..."
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
    fi
    
    # Generate and install plist
    info "Installing LaunchAgent..."
    generate_plist "$PLIST_DEST"
    
    # Set proper permissions
    chmod 644 "$PLIST_DEST"
    
    # Load the LaunchAgent
    info "Loading scheduled scan..."
    launchctl load "$PLIST_DEST"
    
    if is_loaded; then
        success "Automated security scanning is now active!"
        echo
        info "Configuration:"
        echo "  • Runs every Sunday at 2:00 AM"
        echo "  • Reports saved to ~/Desktop/"
        echo "  • Logs: /tmp/security-scan-scheduled.log"
        echo "  • Errors: /tmp/security-scan-scheduled.error"
        echo
        info "To check status: $0 --status"
        info "To run test scan: $0 --test"
        info "To uninstall: $0 --uninstall"
    else
        error "Failed to load scheduled scan"
        exit 1
    fi
}

# Uninstall the scheduled scan
uninstall_scan() {
    info "Removing automated security scanning..."
    
    if is_loaded; then
        info "Unloading LaunchAgent..."
        launchctl unload "$PLIST_DEST"
    fi
    
    if is_installed; then
        info "Removing plist file..."
        rm -f "$PLIST_DEST"
    fi
    
    # Clean up log files
    rm -f /tmp/security-scan-scheduled.log
    rm -f /tmp/security-scan-scheduled.error
    
    success "Automated security scanning has been removed"
}

# Check status
check_status() {
    echo "=== Scheduled Security Scan Status ==="
    echo
    
    if is_installed; then
        echo "✅ LaunchAgent file: INSTALLED"
        echo "   Location: $PLIST_DEST"
    else
        echo "❌ LaunchAgent file: NOT INSTALLED"
    fi
    
    if is_loaded; then
        echo "✅ LaunchAgent status: LOADED"
        
        # Get next run time
        local next_run=$(launchctl list "$PLIST_NAME" 2>/dev/null | grep "NextRunDate" || echo "Unknown")
        if [[ "$next_run" != "Unknown" ]]; then
            echo "   $next_run"
        fi
    else
        echo "❌ LaunchAgent status: NOT LOADED"
    fi
    
    echo
    echo "Schedule: Every Sunday at 2:00 AM"
    echo "Last run log: /tmp/security-scan-scheduled.log"
    echo "Error log: /tmp/security-scan-scheduled.error"
    
    # Check if log files exist and show recent entries
    if [[ -f "/tmp/security-scan-scheduled.log" ]]; then
        echo
        echo "=== Recent Log Entries ==="
        tail -5 /tmp/security-scan-scheduled.log
    fi
    
    if [[ -f "/tmp/security-scan-scheduled.error" ]]; then
        echo
        echo "=== Recent Errors ==="
        tail -5 /tmp/security-scan-scheduled.error
    fi
}

# Run test scan
run_test() {
    info "Running test security scan..."
    
    if [[ ! -f "$REPO_ROOT/scripts/full-diagnostics/simple-security-check.command" ]]; then
        error "Security scan script not found!"
        exit 1
    fi
    
    cd "$REPO_ROOT"
    ./scripts/full-diagnostics/simple-security-check.command
    
    success "Test scan completed! Check your Desktop for the report."
}

# Main execution
main() {
    case "${1:-install}" in
        -h|--help)
            usage
            exit 0
            ;;
        -u|--uninstall)
            uninstall_scan
            ;;
        -s|--status)
            check_status
            ;;
        -t|--test)
            run_test
            ;;
        install|"")
            install_scan
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

# Ensure we're running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script only works on macOS"
    exit 1
fi

# Run main function with all arguments
main "$@"