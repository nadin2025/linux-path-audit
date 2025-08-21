
#!/bin/bash

# PATH Security Audit Script with Logging and Email Report
# Author: YourName
# Date: $(date)
# Description: Performs basic security audit of the PATH variable, logs results, and sends a report via email.

# === Config ===
EMAIL="admin@example.com"  # <- SET YOUR EMAIL HERE
LOGFILE="/var/log/path_audit.log"
TMP_REPORT="/tmp/path_audit_report.txt"

# === Start report ===
echo "[*] PATH Security Audit Report - $(date)" > "$TMP_REPORT"
echo "--------------------------------------------------" >> "$TMP_REPORT"

IFS=':' read -ra PATH_DIRS <<< "$PATH"

for dir in "${PATH_DIRS[@]}"; do
    echo "[*] Checking: $dir" >> "$TMP_REPORT"

    # Directory writable by current user
    if [ -w "$dir" ]; then
        echo "[-] WARNING: Directory $dir is writable. Risk of privilege escalation." >> "$TMP_REPORT"
    fi

    # Is directory current directory ('.')
    if [[ "$dir" == "." ]]; then
        echo "[-] CRITICAL: '.' is in PATH. Allows executing scripts from current directory." >> "$TMP_REPORT"
    fi

    # Non-absolute paths
    if [[ "$dir" != /* ]]; then
        echo "[-] WARNING: Non-absolute path: $dir. Always use absolute paths." >> "$TMP_REPORT"
    fi

    # Directory exists
    if [ ! -d "$dir" ]; then
        echo "[-] WARNING: $dir does not exist." >> "$TMP_REPORT"
    fi

    # Directory permissions (group/world writable)
    if [ -d "$dir" ]; then
        perms=$(stat -c "%A" "$dir" 2>/dev/null)
        if [[ "$perms" =~ .w. ]] || [[ "$perms" =~ ....w. ]]; then
            echo "[-] WARNING: $dir has group/other write permissions ($perms)." >> "$TMP_REPORT"
        fi
    fi
done

# Append recommendation
echo >> "$TMP_REPORT"
echo "[+] Recommended Secure PATH:" >> "$TMP_REPORT"
echo "    /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "$TMP_REPORT"

# === Output to log ===
cat "$TMP_REPORT" >> "$LOGFILE"

# === Send email (if mail or sendmail is configured) ===
if command -v mail > /dev/null; then
    mail -s "PATH Security Audit Report - $(hostname)" "$EMAIL" < "$TMP_REPORT"
elif command -v sendmail > /dev/null; then
    {
        echo "Subject: PATH Security Audit Report - $(hostname)"
        echo "To: $EMAIL"
        echo
        cat "$TMP_REPORT"
    } | sendmail "$EMAIL"
else
    echo "[!] No mail/sendmail found. Email not sent." >> "$TMP_REPORT"
fi

# === Cleanup ===
rm -f "$TMP_REPORT"

echo "[✓] Audit complete. Report saved to $LOGFILE"
