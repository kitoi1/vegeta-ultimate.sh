#!/bin/bash
#====================================================================#
# Vegeta Ultimate Stress Tester - Enhanced Edition                   #
# Created by: Kasau                    #
# GitHub: https://github.com/kasau/vegeta-ultimate                   #
#====================================================================#

# ANSI Color Codes
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ASCII Art Banner
function show_banner() {
    clear
    echo -e "${PURPLE}"
    echo ' __      __          _              _         _____ _        _         '
    echo ' \ \    / /         | |            | |       / ____| |      (_)        '
    echo '  \ \  / /__ _ __ __| |_ __ _ _ __| |_     | (___ | |_ __ _ _ _ __    '
    echo '   \ \/ / _ \ '"'"'__/ _'"'"' | '"'"'__| '"'"'_ \ __|     \___ \| __/ _'"'"' | | '"'"'_ \   '
    echo '    \  /  __/ | | (_| | |  | | | |_      ____) | || (_| | | | | | |  '
    echo '     \/ \___|_|  \__,_|_|  |_| |_|\__|   |_____/ \__\__,_|_|_| |_|  '
    echo -e "${NC}"
    echo -e "${CYAN}                  Enhanced HTTP Load Testing Tool${NC}"
    echo -e "${YELLOW}               Based on original by Kasau (GitHub)${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

# Dependency Check
function check_dependencies() {
    if ! command -v go &> /dev/null; then
        echo -e "${RED}[!] Go (Golang) not found. Installing...${NC}"
        sudo apt update && sudo apt install -y golang-go || {
            echo -e "${RED}[!] Failed to install Go. Please install manually.${NC}"
            exit 1
        }
    fi

    if ! command -v vegeta &> /dev/null; then
        echo -e "${YELLOW}[*] Installing Vegeta...${NC}"
        go install github.com/tsenart/vegeta@latest
        export PATH=$PATH:$(go env GOPATH)/bin
    fi

    if ! command -v vegeta &> /dev/null; then
        echo -e "${RED}[!] Vegeta installation failed. Please check your Go environment.${NC}"
        exit 1
    fi
}

# Progress Bar
function show_progress() {
    local duration=${1:-2}
    echo -ne "${GREEN}["
    for ((i=0; i<20; i++)); do
        echo -ne "#"
        sleep $(echo "$duration / 20" | bc -l)
    done
    echo -e "]${NC}"
}

# Main Attack Function
function launch_attack() {
    local method=$1
    local target=$2
    local rate=$3
    local duration=$4
    local headers=$5
    local proxy=$6
    local timestamp=$(date +%Y%m%d%H%M%S)
    local target_file=$(mktemp)

    echo -e "\n${BLUE}[*] Preparing attack...${NC}"

    echo "$method $target" > "$target_file"
    [[ -n $headers ]] && echo "$headers" >> "$target_file"

    echo -e "\n${GREEN}[+] Attack starting...${NC}"

    # Build vegeta command
    local cmd="vegeta attack -rate=${rate} -duration=${duration} -targets=${target_file}"
    [[ -n $proxy ]] && cmd="$cmd -proxy=$proxy"

    # Run attack
    eval "$cmd" | tee results.bin | vegeta report -type=text | while read -r line; do
        echo -e "${PURPLE}$line${NC}"
    done

    # Reports
    echo -e "\n${GREEN}[+] Generating reports...${NC}"
    vegeta report -type=json < results.bin > "report-$timestamp.json"
    vegeta report -type=text < results.bin > "report-$timestamp.txt"
    vegeta plot < results.bin > "plot-$timestamp.html"

    echo -e "${CYAN}[*] Reports generated:${NC}"
    echo -e "${GREEN}  - report-$timestamp.txt${NC}"
    echo -e "${GREEN}  - report-$timestamp.json${NC}"
    echo -e "${GREEN}  - plot-$timestamp.html${NC}"

    # Cleanup
    rm -f "$target_file" results.bin
}

# ======= Main Execution =======
show_banner
check_dependencies

# Input
echo -e "\n${BLUE}[*] Attack Configuration${NC}"
read -rp "$(echo -e "${CYAN}Target URL (e.g., https://example.com): ${NC}")" TARGET
read -rp "$(echo -e "${CYAN}Rate (requests/sec): ${NC}")" RATE
read -rp "$(echo -e "${CYAN}Duration (e.g., 30s, 1m): ${NC}")" DURATION
read -rp "$(echo -e "${CYAN}HTTP Method (GET/POST/PUT/DELETE) [default: GET]: ${NC}")" METHOD
read -rp "$(echo -e "${CYAN}Custom headers? (e.g., Header: value) or leave blank: ${NC}")" HEADERS
read -rp "$(echo -e "${CYAN}Proxy (http://host:port) or leave blank: ${NC}")" PROXY

METHOD=${METHOD:-GET}

# Target Check
echo -e "\n${YELLOW}[*] Checking target...${NC}"
if curl --output /dev/null --silent --head --fail "$TARGET"; then
    echo -e "${GREEN}[âœ“] Target is accessible${NC}"
else
    echo -e "${RED}[!] Target not accessible. Check the URL.${NC}"
    exit 1
fi

# Summary
echo -e "\n${PURPLE}================== Attack Summary ==================${NC}"
echo -e "${BLUE}Target:    ${NC}$TARGET"
echo -e "${BLUE}Rate:      ${NC}$RATE requests/sec"
echo -e "${BLUE}Duration:  ${NC}$DURATION"
echo -e "${BLUE}Method:    ${NC}$METHOD"
[[ -n $HEADERS ]] && echo -e "${BLUE}Headers:   ${NC}$HEADERS"
[[ -n $PROXY ]] && echo -e "${BLUE}Proxy:     ${NC}$PROXY"
echo -e "${PURPLE}===============================================${NC}"

show_progress 2
launch_attack "$METHOD" "$TARGET" "$RATE" "$DURATION" "$HEADERS" "$PROXY"

echo -e "\n${GREEN}[âœ“] Stress test complete!${NC}"
echo -e "${BLUE}Thank you for using Vegeta Ultimate by Kasau (Enhanced)${NC}"
