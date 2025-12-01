#!/usr/bin/env bash
# CrackIT — safe, syllabus-friendly John the Ripper wrapper
# Made by NGHTMRE
# Usage: ./crackit.sh
# Note: Only use on files YOU own or have permission to test.

set -euo pipefail

# -----------------------
# Colors (simple)
# -----------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# -----------------------
# Banner / ASCII Art (CrackIT)
# -----------------------
print_banner() {
cat <<'EOF'
 ██████╗██████╗  █████╗  ██████╗██╗  ██╗██╗████████╗
██╔════╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║╚══██╔══╝
██║     ██████╔╝███████║██║     █████╔╝ ██║   ██║   
██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║   
╚██████╗██║  ██║██║  ██║╚██████╗██║  ██╗██║   ██║   
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝   ╚═╝   
              Project: CrackST
              Made by: NGHTMRE
============================================================
EOF
}

# -----------------------
# Simple dependency checks
# -----------------------
require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}[!] Required command '$1' is not installed. Install it and re-run.${RESET}"
        exit 1
    fi
}

require_cmd john
require_cmd zip2john || true   # zip2john may be separate or bundled; we'll check when needed
require_cmd awk
require_cmd sleep


status_ok() {
    echo -e "${GREEN}[+]${RESET} $1"
}
status_warn() {
    echo -e "${YELLOW}[!]${RESET} $1"
}
status_err() {
    echo -e "${RED}[x]${RESET} $1"
}

# -----------------------
# Progress UI
# - Runs while a background PID is alive
# - Shows spinner, animated progress bar, elapsed time
# - This is a visual aid; progress is approximate
# -----------------------
show_progress_while_pid() {
    local pid=$1
    local start_ts=$(date +%s)
    local -a spin=( '|' '/' '-' '\' )
    local spin_idx=0
    local width=40
    local pct=0
    tput civis 2>/dev/null || true   # hide cursor if possible

    while kill -0 "$pid" >/dev/null 2>&1; do
        sleep 0.25
        # spinner
        spin_idx=$(( (spin_idx + 1) % 4 ))
        local s="${spin[spin_idx]}"

        # animated progress: advance and wrap
        pct=$(( (pct + 1) % 101 ))
        local filled=$(( width * pct / 100 ))
        local empty=$(( width - filled ))
        local bar="$(printf '%0.s█' $(seq 1 $filled))$(printf '%0.s-' $(seq 1 $empty))"

        local now_ts=$(date +%s)
        local elapsed=$(( now_ts - start_ts ))
        printf "\r${CYAN} %s ${RESET} |%s| %3s%%  Elapsed: %02ds " "$s" "$bar" "$pct" "$elapsed"
    done

    # ensure final newline and restore cursor
    printf "\r${GREEN} ✓${RESET} %-60s\n" "John finished or stopped."
    tput cnorm 2>/dev/null || true
}

# -----------------------
# Run John with progress UI wrapper
# -----------------------
run_john_with_progress() {
    local john_args=("$@")
    # run john in background, save PID
    "${john_args[@]}" &
    local jpid=$!
    # show progress while john runs
    show_progress_while_pid "$jpid"
    wait "$jpid" || true
}

# -----------------------
# Main menu
# -----------------------
clear
print_banner
echo -e "${BOLD}Welcome to CrackIT — safe demo wrapper for John the Ripper${RESET}"
echo -e "${YELLOW}Only use on files you own or have explicit permission to test.${RESET}"
echo

while true; do
    echo -e "${BLUE}Select an option:${RESET}"
    echo "  1) Crack a hash file with a wordlist"
    echo "  2) Crack a ZIP file with a wordlist (uses zip2john)"
    echo "  3) Help / Usage"
    echo "  4) Exit"
    read -p $'\nEnter choice (1-4): ' choice
    echo

    case "$choice" in
        1)
            read -p "Path to hash file: " hashfile
            if [ ! -f "$hashfile" ]; then
                status_err "Hash file not found: $hashfile"
                continue
            fi
            read -p "Path to wordlist (one password per line): " wordlist
            if [ ! -f "$wordlist" ]; then
                status_err "Wordlist not found: $wordlist"
                continue
            fi

            status_ok "Starting John the Ripper on: $hashfile"
            echo -e "${MAGENTA}Command:${RESET} john --wordlist=${wordlist} ${hashfile}"
            # Run john while showing progress UI
            run_john_with_progress john --wordlist="$wordlist" "$hashfile"

            status_ok "Showing results (john --show):"
            john --show "$hashfile" || status_warn "john --show returned non-zero (may be no cracks)."
            echo
            ;;

        2)
            read -p "Path to ZIP file: " zipfile
            if [ ! -f "$zipfile" ]; then
                status_err "ZIP file not found: $zipfile"
                continue
            fi

            # check zip2john availability now
            if ! command -v zip2john >/dev/null 2>&1; then
                status_err "zip2john is not found on your system. Install John package that provides zip2john."
                continue
            fi

            read -p "Path to wordlist (one password per line): " wordlist
            if [ ! -f "$wordlist" ]; then
                status_err "Wordlist not found: $wordlist"
                continue
            fi

            # Extract hash
            status_ok "Extracting hash from ZIP (zip2john)..."
            ziphash="ziphash_$(date +%s).txt"
            zip2john "$zipfile" > "$ziphash" || { status_err "zip2john failed."; continue; }
            status_ok "Hash saved to $ziphash"

            echo -e "${MAGENTA}Command:${RESET} john --wordlist=${wordlist} ${ziphash}"
            run_john_with_progress john --wordlist="$wordlist" "$ziphash"

            status_ok "Showing results (john --show):"
            john --show "$ziphash" || status_warn "john --show returned non-zero (may be no cracks)."
            echo
            ;;

        3)
            echo -e "${BOLD}Help / Usage:${RESET}"
            echo "- Option 1: Give a hash file (John-format or known format). Provide wordlist."
            echo "- Option 2: Give a ZIP file. The script uses zip2john to get hash, then runs John."
            echo
            echo "Examples:"
            echo "  ./crackit.sh  -> choose option 1 or 2"
            echo "  john --list=formats  # to see formats John supports"
            echo
            echo -e "${YELLOW}Reminder:${RESET} This script is for learning only. Cracking passwords without permission is illegal."
            echo
            ;;

        4)
            echo -e "${GREEN}Goodbye. Use this tool responsibly.${RESET}"
            exit 0
            ;;

        *)
            echo -e "${RED}Invalid choice. Enter 1-4.${RESET}"
            ;;
    esac
done