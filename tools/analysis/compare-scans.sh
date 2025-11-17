#!/bin/bash

# macOS Security Scan Comparison Tool
# Compares two security scan outputs and highlights differences
# Usage: ./compare-scans.sh scan1.txt scan2.txt

set -euo pipefail

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    cat << EOF
Usage: $SCRIPT_NAME <scan1.txt> <scan2.txt> [options]

Compare two macOS security scan outputs and highlight differences.

Arguments:
    scan1.txt    First (baseline) security scan file
    scan2.txt    Second (comparison) security scan file

Options:
    -h, --help       Show this help message
    -v, --version    Show version
    -o, --output     Output file for comparison report
    -s, --summary    Show summary only (no detailed diff)
    -q, --quiet      Suppress progress messages
    --html           Generate HTML output (requires output file)

Examples:
    $SCRIPT_NAME baseline-scan.txt current-scan.txt
    $SCRIPT_NAME scan1.txt scan2.txt -o comparison-report.txt
    $SCRIPT_NAME old.txt new.txt --summary --html -o report.html

EOF
}

# Initialize variables
SCAN1=""
SCAN2=""
OUTPUT_FILE=""
SUMMARY_ONLY=false
QUIET=false
HTML_OUTPUT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            echo "$SCRIPT_NAME version $VERSION"
            exit 0
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -s|--summary)
            SUMMARY_ONLY=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --html)
            HTML_OUTPUT=true
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [[ -z "$SCAN1" ]]; then
                SCAN1="$1"
            elif [[ -z "$SCAN2" ]]; then
                SCAN2="$1"
            else
                echo "Too many arguments" >&2
                usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$SCAN1" || -z "$SCAN2" ]]; then
    echo "Error: Both scan files are required" >&2
    usage >&2
    exit 1
fi

if [[ ! -f "$SCAN1" ]]; then
    echo "Error: File $SCAN1 not found" >&2
    exit 1
fi

if [[ ! -f "$SCAN2" ]]; then
    echo "Error: File $SCAN2 not found" >&2
    exit 1
fi

if [[ "$HTML_OUTPUT" == true && -z "$OUTPUT_FILE" ]]; then
    echo "Error: HTML output requires an output file (-o option)" >&2
    exit 1
fi

# Progress function
progress() {
    if [[ "$QUIET" != true ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

# Warning function
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

# Critical function
critical() {
    echo -e "${RED}[CRITICAL]${NC} $1" >&2
}

# Good news function
good() {
    echo -e "${GREEN}[GOOD]${NC} $1" >&2
}

# Extract section from scan file
extract_section() {
    local file="$1"
    local section="$2"
    local temp_file=$(mktemp)
    
    awk "
    /^===============================$/ { 
        getline; 
        if (\$0 ~ \"^$section\") { 
            in_section = 1; 
            print \$0; 
            next 
        } 
    }
    in_section && /^===============================/ { 
        exit 
    }
    in_section { 
        print \$0 
    }
    " "$file" > "$temp_file"
    
    echo "$temp_file"
}

# Compare Launch Agents
compare_launch_agents() {
    progress "Comparing Launch Agents..."
    
    local agents1=$(extract_section "$SCAN1" "1\. Suspicious Launch Agents")
    local agents2=$(extract_section "$SCAN2" "1\. Suspicious Launch Agents")
    
    # Extract plist file names
    local files1=$(mktemp)
    local files2=$(mktemp)
    
    grep -o "/[^[:space:]]*.plist" "$agents1" 2>/dev/null | sort -u > "$files1" || true
    grep -o "/[^[:space:]]*.plist" "$agents2" 2>/dev/null | sort -u > "$files2" || true
    
    # Find new files
    local new_files=$(comm -13 "$files1" "$files2")
    local removed_files=$(comm -23 "$files1" "$files2")
    
    if [[ -n "$new_files" ]]; then
        critical "NEW Launch Agents detected:"
        echo "$new_files" | while read -r file; do
            echo "  + $file"
        done
    fi
    
    if [[ -n "$removed_files" ]]; then
        good "Launch Agents removed:"
        echo "$removed_files" | while read -r file; do
            echo "  - $file"
        done
    fi
    
    if [[ -z "$new_files" && -z "$removed_files" ]]; then
        echo "  No changes in Launch Agents"
    fi
    
    # Cleanup
    rm -f "$agents1" "$agents2" "$files1" "$files2"
}

# Compare Network Listeners
compare_network() {
    progress "Comparing Network Listeners..."
    
    local network1=$(extract_section "$SCAN1" "5\. Network Listeners")
    local network2=$(extract_section "$SCAN2" "5\. Network Listeners")
    
    # Extract listening ports
    local ports1=$(mktemp)
    local ports2=$(mktemp)
    
    grep "LISTEN" "$network1" 2>/dev/null | awk '{print $9}' | sort -u > "$ports1" || true
    grep "LISTEN" "$network2" 2>/dev/null | awk '{print $9}' | sort -u > "$ports2" || true
    
    # Find differences
    local new_listeners=$(comm -13 "$ports1" "$ports2")
    local removed_listeners=$(comm -23 "$ports1" "$ports2")
    
    if [[ -n "$new_listeners" ]]; then
        warning "NEW Network Listeners:"
        echo "$new_listeners" | while read -r port; do
            echo "  + $port"
        done
    fi
    
    if [[ -n "$removed_listeners" ]]; then
        echo "Network Listeners removed:"
        echo "$removed_listeners" | while read -r port; do
            echo "  - $port"
        done
    fi
    
    if [[ -z "$new_listeners" && -z "$removed_listeners" ]]; then
        echo "  No changes in Network Listeners"
    fi
    
    # Cleanup
    rm -f "$network1" "$network2" "$ports1" "$ports2"
}

# Compare SSH Keys
compare_ssh() {
    progress "Comparing SSH Configuration..."
    
    local ssh1=$(extract_section "$SCAN1" "7\. SSH keys")
    local ssh2=$(extract_section "$SCAN2" "7\. SSH keys")
    
    # Extract SSH key fingerprints
    local keys1=$(mktemp)
    local keys2=$(mktemp)
    
    grep "^ssh-" "$ssh1" 2>/dev/null | awk '{print $2}' | sort > "$keys1" || true
    grep "^ssh-" "$ssh2" 2>/dev/null | awk '{print $2}' | sort > "$keys2" || true
    
    # Find differences
    local new_keys=$(comm -13 "$keys1" "$keys2")
    local removed_keys=$(comm -23 "$keys1" "$keys2")
    
    if [[ -n "$new_keys" ]]; then
        critical "NEW SSH Keys detected:"
        echo "$new_keys" | while read -r key; do
            echo "  + $key"
        done
    fi
    
    if [[ -n "$removed_keys" ]]; then
        echo "SSH Keys removed:"
        echo "$removed_keys" | while read -r key; do
            echo "  - $key"
        done
    fi
    
    if [[ -z "$new_keys" && -z "$removed_keys" ]]; then
        echo "  No changes in SSH Keys"
    fi
    
    # Cleanup
    rm -f "$ssh1" "$ssh2" "$keys1" "$keys2"
}

# Compare Processes
compare_processes() {
    progress "Comparing Process List..."
    
    local procs1=$(extract_section "$SCAN1" "4\. Suspicious Processes")
    local procs2=$(extract_section "$SCAN2" "4\. Suspicious Processes")
    
    # Extract process names
    local proc_names1=$(mktemp)
    local proc_names2=$(mktemp)
    
    tail -n +2 "$procs1" 2>/dev/null | awk '{print $11}' | sort -u > "$proc_names1" || true
    tail -n +2 "$procs2" 2>/dev/null | awk '{print $11}' | sort -u > "$proc_names2" || true
    
    # Find differences
    local new_procs=$(comm -13 "$proc_names1" "$proc_names2")
    local removed_procs=$(comm -23 "$proc_names1" "$proc_names2")
    
    if [[ -n "$new_procs" ]]; then
        warning "NEW Processes detected:"
        echo "$new_procs" | while read -r proc; do
            echo "  + $proc"
        done
    fi
    
    if [[ -n "$removed_procs" ]]; then
        echo "Processes no longer running:"
        echo "$removed_procs" | while read -r proc; do
            echo "  - $proc"
        done
    fi
    
    if [[ -z "$new_procs" && -z "$removed_procs" ]]; then
        echo "  No significant changes in Processes"
    fi
    
    # Cleanup
    rm -f "$procs1" "$procs2" "$proc_names1" "$proc_names2"
}

# Compare Security Settings
compare_security_settings() {
    progress "Comparing Security Settings..."
    
    local settings1=$(extract_section "$SCAN1" "Additional Security Checks")
    local settings2=$(extract_section "$SCAN2" "Additional Security Checks")
    
    # Extract key security settings
    local sip1=$(grep -o "System Integrity Protection status: [a-z]*" "$settings1" 2>/dev/null || echo "unknown")
    local sip2=$(grep -o "System Integrity Protection status: [a-z]*" "$settings2" 2>/dev/null || echo "unknown")
    
    local fw1=$(grep -o "Firewall is [a-z]*" "$settings1" 2>/dev/null || echo "unknown")
    local fw2=$(grep -o "Firewall is [a-z]*" "$settings2" 2>/dev/null || echo "unknown")
    
    local fv1=$(grep -o "FileVault is [A-Za-z]*" "$settings1" 2>/dev/null || echo "unknown")
    local fv2=$(grep -o "FileVault is [A-Za-z]*" "$settings2" 2>/dev/null || echo "unknown")
    
    # Compare settings
    if [[ "$sip1" != "$sip2" ]]; then
        if [[ "$sip2" == *"disabled"* ]]; then
            critical "System Integrity Protection DISABLED: $sip1 → $sip2"
        else
            good "System Integrity Protection ENABLED: $sip1 → $sip2"
        fi
    fi
    
    if [[ "$fw1" != "$fw2" ]]; then
        if [[ "$fw2" == *"disabled"* ]]; then
            warning "Firewall DISABLED: $fw1 → $fw2"
        else
            good "Firewall ENABLED: $fw1 → $fw2"
        fi
    fi
    
    if [[ "$fv1" != "$fv2" ]]; then
        if [[ "$fv2" == *"Off"* ]]; then
            warning "FileVault DISABLED: $fv1 → $fv2"
        else
            good "FileVault ENABLED: $fv1 → $fv2"
        fi
    fi
    
    if [[ "$sip1" == "$sip2" && "$fw1" == "$fw2" && "$fv1" == "$fv2" ]]; then
        echo "  No changes in Security Settings"
    fi
    
    # Cleanup
    rm -f "$settings1" "$settings2"
}

# Generate HTML report
generate_html() {
    local output="$1"
    
    cat > "$output" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Scan Comparison Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
        .header { background: #f5f5f7; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #007AFF; }
        .critical { border-left-color: #FF3B30; background: #FFF5F5; }
        .warning { border-left-color: #FF9500; background: #FFFBF5; }
        .good { border-left-color: #34C759; background: #F5FFF5; }
        .added { color: #34C759; font-weight: bold; }
        .removed { color: #FF3B30; font-weight: bold; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
        .timestamp { color: #8E8E93; font-size: 0.9em; }
    </style>
</head>
<body>
EOF

    echo "<div class='header'>" >> "$output"
    echo "<h1>🔍 Security Scan Comparison Report</h1>" >> "$output"
    echo "<p class='timestamp'>Generated: $(date)</p>" >> "$output"
    echo "<p><strong>Baseline:</strong> $SCAN1</p>" >> "$output"
    echo "<p><strong>Comparison:</strong> $SCAN2</p>" >> "$output"
    echo "</div>" >> "$output"
    
    # Add comparison results (this would need to be captured from the comparison functions)
    echo "<div class='section'>" >> "$output"
    echo "<h2>Comparison Complete</h2>" >> "$output"
    echo "<p>See console output for detailed comparison results.</p>" >> "$output"
    echo "</div>" >> "$output"
    
    echo "</body></html>" >> "$output"
}

# Main comparison function
main() {
    progress "Starting security scan comparison..."
    progress "Baseline: $SCAN1"
    progress "Current:  $SCAN2"
    echo
    
    # Perform comparisons
    compare_launch_agents
    echo
    compare_network
    echo
    compare_ssh
    echo
    compare_processes
    echo
    compare_security_settings
    echo
    
    # Generate summary
    if [[ "$SUMMARY_ONLY" != true ]]; then
        echo "=== DETAILED DIFFERENCES ==="
        echo
        progress "Generating detailed diff..."
        diff -u "$SCAN1" "$SCAN2" | head -50 || true
        echo
        echo "(Showing first 50 lines of diff. Use 'diff -u $SCAN1 $SCAN2' for complete output)"
    fi
    
    # Output to file if specified
    if [[ -n "$OUTPUT_FILE" ]]; then
        if [[ "$HTML_OUTPUT" == true ]]; then
            generate_html "$OUTPUT_FILE"
            good "HTML report saved to: $OUTPUT_FILE"
        else
            exec > >(tee "$OUTPUT_FILE")
            good "Report saved to: $OUTPUT_FILE"
        fi
    fi
    
    echo
    good "Comparison complete!"
}

# Run main function
main