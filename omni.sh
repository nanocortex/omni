#!/usr/bin/env sh
# Omni - A shell script for installing programs and maintaining unix based systems

set -e

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Check if a command is installed
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Determine if the script is being sourced or executed directly
is_sourced() {
  sourced=0
  if [ -n "$ZSH_VERSION" ]; then 
    case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
  elif [ -n "$KSH_VERSION" ]; then
    [ "$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd -- "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}")" ] && sourced=1
  elif [ -n "$BASH_VERSION" ]; then
    (return 0 2>/dev/null) && sourced=1 
  else # All other shells: examine $0 for known shell binary filenames.
    # Detects `sh` and `dash`; add additional shell filenames as needed.
    case ${0##*/} in sh|-sh|dash|-dash) sourced=1;; esac
  fi

  return $sourced
}


# Prompt user to install a program if not installed
ask_install() {
    program="$1"
    purpose="$2"
    install_func="$3"
    
    echo "$program is not installed. Would you like to install it $purpose? (y/n)"
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            if [ -n "$install_func" ]; then
                "$install_func"
            else
                echo "Installing $program..."
                case "$(uname)" in
                    Darwin)
                        brew install "$program"
                        ;;
                    Linux)
                        if is_installed apt; then
                            sudo apt update && sudo apt install -y "$program"
                        elif is_installed dnf; then
                            sudo dnf install -y "$program"
                        elif is_installed pacman; then
                            sudo pacman -S "$program"
                        else
                            echo "Please install $program manually"
                            return 1
                        fi
                        ;;
                esac
            fi
            
            if is_installed "$program"; then
                echo "$program installed successfully!"
                return 0
            else
                echo "Failed to install $program"
                return 1
            fi
            ;;
        *)
            echo "Continuing without $program"
            return 1
            ;;
    esac
}

# Helper function for macOS installation via Homebrew
install_macos_program() {
    program="$1"
    package_name="${2:-$program}"
    package_type="${3:-formula}"  # formula or cask
    
    case "$package_type" in
        "cask")
            brew install --cask "$package_name"
            ;;
        *)
            brew install "$package_name"
            ;;
    esac
}

# Helper function for Linux installation via package managers
install_linux_program() {
    program="$1"
    package_name="${2:-$program}"
    fallback_func="${3:-}"  # Optional fallback function
    
    if is_installed apt; then
        sudo apt update && sudo apt install -y "$package_name"
    elif is_installed dnf; then
        sudo dnf install -y "$package_name"
    elif is_installed pacman; then
        sudo pacman -S "$package_name"
    elif command -v brew >/dev/null 2>&1; then
        brew install "$package_name"
    else
        if [ -n "$fallback_func" ]; then
            echo "Package managers don't have $program, trying fallback installation..."
            "$fallback_func" "$program" "$package_name"
            return $?
        else
            echo "Please install $program manually from your distribution's package manager"
            return 1
        fi
    fi
}

# Helper function for cross-platform program installation
install_program() {
    program="$1"
    macos_package="${2:-$program}"
    linux_package="${3:-$program}"
    package_type="${4:-formula}"  # for macOS: formula or cask
    linux_fallback_func="${5:-}"  # Optional Linux fallback function
    
    if is_installed "$program"; then
        echo "$program is already installed!"
        return 0
    fi
    
    echo "Installing $program..."
    case "$(uname)" in
        Darwin)
            install_macos_program "$program" "$macos_package" "$package_type"
            ;;
        Linux)
            install_linux_program "$program" "$linux_package" "$linux_fallback_func"
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
    echo "$program installation completed!"
}

# Fallback functions for special installation cases
fallback_yt_dlp_pip() {
    program="$1"
    # Try pip installation
    if is_installed pip3; then
        pip3 install --user yt-dlp
    elif is_installed python3; then
        python3 -m pip install --user yt-dlp
    else
        echo "Please install yt-dlp manually"
        return 1
    fi
}

fallback_shfmt_binary() {
    program="$1"
    if is_installed go; then
        go install mvdan.cc/sh/v3/cmd/shfmt@latest
    else
        echo "Installing from GitHub releases..."
        arch=$(uname -m)
        case "$arch" in
            x86_64) arch="amd64" ;;
            aarch64) arch="arm64" ;;
            armv7l) arch="arm" ;;
        esac
        curl -sL "https://github.com/mvdan/sh/releases/latest/download/shfmt_v3.7.0_linux_${arch}" -o /tmp/shfmt
        chmod +x /tmp/shfmt
        sudo mv /tmp/shfmt /usr/local/bin/shfmt
    fi
}

fallback_fastfetch_apt() {
    program="$1"
    sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y
    sudo apt update && sudo apt install -y "$program"
}

fallback_fastfetch_github() {
    program="$1"
    echo "Installing from GitHub releases..."
    curl -sL https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz | tar -xz
    sudo mv fastfetch-linux-amd64/usr/bin/fastfetch /usr/local/bin/
    rm -rf fastfetch-linux-amd64
}

install_ncdu() {
    # PROGRAM: ncdu
    install_program "ncdu"
}

install_htop() {
    # PROGRAM: htop
    install_program "htop"
}

install_ffmpeg() {
    # PROGRAM: FFmpeg
    install_program "ffmpeg"
}

install_mpv() {
    # PROGRAM: mpv
    install_program "mpv"
}

install_ansible() {
    # PROGRAM: ansible
    install_program "ansible"
}

install_go() {
    # PROGRAM: go
    install_program "go"
}

install_helm() {
    # PROGRAM: helm
    install_program "helm"
}

install_duf() {
    # PROGRAM: duf
    install_program "duf"
}

install_lnav() {
    # PROGRAM: lnav
    install_program "lnav"
}

install_ripgrep() {
    # PROGRAM: ripgrep
    install_program "ripgrep"
}

install_speedtest() {
    # PROGRAM: speedtest
    install_program "speedtest"
}

install_speedtest_cli() {
    # PROGRAM: speedtest-cli
    install_program "speedtest-cli" "speedtest" "speedtest-cli"
}

install_lazygit() {
    # PROGRAM: lazygit
    install_program "lazygit"
}

install_yt_dlp() {
    # PROGRAM: yt-dlp
    install_program "yt-dlp" "yt-dlp" "yt-dlp" "formula" "fallback_yt_dlp_pip"
}

fallback_fzf_github() {
    program="$1"
    echo "Installing fzf from GitHub..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
}

install_fzf() {
    # PROGRAM: fzf
    install_program "fzf" "fzf" "fzf" "formula" "fallback_fzf_github"
}

fallback_yazi_cargo() {
    program="$1"
    if is_installed cargo; then
        cargo install --locked yazi-fm yazi-cli
    else
        echo "Please install yazi manually or install Rust/Cargo first"
        return 1
    fi
}

fallback_bat_apt() {
    program="$1"
    sudo apt update && sudo apt install -y "$program"
    # On Ubuntu/Debian, bat is installed as batcat
    if [ ! -L /usr/local/bin/bat ] && [ -f /usr/bin/batcat ]; then
        sudo ln -s /usr/bin/batcat /usr/local/bin/bat
    fi
}

fallback_bat_github() {
    program="$1"
    echo "Installing from GitHub releases..."
    curl -sL https://github.com/sharkdp/bat/releases/latest/download/bat_*_amd64.deb -o bat.deb
    sudo dpkg -i bat.deb
    rm bat.deb
}

fallback_docker_script() {
    program="$1"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker "$USER"
    echo "Please log out and back in for Docker group permissions to take effect"
}

fallback_nodejs_nodesource() {
    program="$1"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
}

fallback_python_apt() {
    program="$1"
    sudo apt update && sudo apt install -y python3 python3-pip
}

fallback_python_yum() {
    program="$1"
    if is_installed yum; then
        sudo yum install -y python3 python3-pip
    elif is_installed dnf; then
        sudo dnf install -y python3 python3-pip
    else
        echo "Unsupported package manager"
        return 1
    fi
}

# Platform-specific operation helper
run_platform_operation() {
    operation_name="$1"
    macos_cmd="$2"
    linux_cmd="$3"
    success_msg="${4:-$operation_name completed}"
    
    printf "${BLUE}%s...${NC}\n" "$operation_name"
    case "$(uname)" in
        Darwin)
            eval "$macos_cmd"
            printf "${GREEN}%s${NC}\n" "$success_msg"
            ;;
        Linux)
            eval "$linux_cmd"
            printf "${GREEN}%s${NC}\n" "$success_msg"
            ;;
        *)
            printf "${RED}Unsupported operating system${NC}\n"
            return 1
            ;;
    esac
}

clear_linux_dns_cache() {
    if command -v systemctl >/dev/null 2>&1; then
        # systemd-resolved
        if systemctl is-active --quiet systemd-resolved; then
            sudo systemctl flush-dns
            echo "systemd-resolved DNS cache cleared"
        fi
        
        # NetworkManager
        if systemctl is-active --quiet NetworkManager; then
            sudo systemctl restart NetworkManager
            echo "NetworkManager restarted"
        fi
    fi
    
    # Clear nscd if available
    if command -v nscd >/dev/null 2>&1; then
        sudo nscd -i hosts
        echo "nscd DNS cache cleared"
    fi
    
    # Clear dnsmasq if available
    if command -v dnsmasq >/dev/null 2>&1 && pgrep dnsmasq >/dev/null; then
        sudo killall -USR1 dnsmasq
        echo "dnsmasq cache cleared"
    fi
}

install_yazi() {
    # PROGRAM: yazi
    install_program "yazi" "yazi" "yazi" "formula" "" "fallback_yazi_cargo"
}

install_nnn() {
    # PROGRAM: nnn
    install_program "nnn"
}

install_shfmt() {
    # PROGRAM: shfmt
    install_program "shfmt" "shfmt" "shfmt" "formula" "fallback_shfmt_binary"
}

install_docker() {
    # PROGRAM: Docker
    case "$(uname)" in
        Darwin)
            # Check if Docker Desktop is already installed
            if [ -d "/Applications/Docker.app" ]; then
                echo "Docker Desktop is already installed at /Applications/Docker.app"
                echo "You can start it from Applications or Launchpad"
                return 0
            fi
            
            # Check if docker command is available
            if command -v docker >/dev/null 2>&1; then
                echo "Docker is already installed and available in PATH"
                docker --version
                return 0
            fi
            
            install_program "docker" "docker" "docker" "cask"
            ;;
        Linux)
            install_program "docker" "docker" "docker" "formula" "fallback_docker_script"
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

clean_trash() {
    # MENU: Clean Trash
    run_platform_operation "Cleaning trash" \
        "sudo rm -rf ~/.Trash/*" \
        "sudo rm -rf ~/.local/share/Trash/*" \
        "Trash cleaned"
}

update_linux_system() {
    if is_installed apt; then
        sudo apt update && sudo apt upgrade -y
    elif is_installed yum; then
        sudo yum update -y
    elif is_installed dnf; then
        sudo dnf upgrade -y
    elif is_installed pacman; then
        sudo pacman -Syu
    else
        echo "Unsupported package manager"
        return 1
    fi
}

update_system() {
    # MENU: Update System
    run_platform_operation "Updating system packages" \
        "brew update && brew upgrade" \
        "update_linux_system" \
        "System update completed"
}

install_nodejs() {
    # PROGRAM: Node.js
    install_program "node" "node" "nodejs" "formula" "fallback_nodejs_nodesource"
}

clean_logs() {
    # MENU: Clean System Logs
    run_platform_operation "Cleaning system logs" \
        "sudo log erase --all" \
        "sudo journalctl --vacuum-time=7d; sudo find /var/log -type f -name '*.log' -exec truncate -s 0 {} \;" \
        "System logs cleaned"
}

install_newsboat() {
    # PROGRAM: Newsboat
    install_program "newsboat"
}

install_python() {
    # PROGRAM: Python
    install_program "python3" "python" "python3" "formula" "fallback_python_apt" "fallback_python_yum"
}

install_fastfetch() {
    # PROGRAM: Fastfetch
    install_program "fastfetch" "fastfetch" "fastfetch" "formula" "fallback_fastfetch_apt" "fallback_fastfetch_github"
}

install_homebrew() {
    # PROGRAM: Homebrew
    echo "Installing Homebrew..."
    case "$(uname)" in
        Darwin)
            if is_installed brew; then
                echo "Homebrew is already installed!"
                return 0
            fi
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            echo "Homebrew installation completed!"
            ;;
        Linux)
            if is_installed brew; then
                echo "Homebrew is already installed!"
                return 0
            fi
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
            echo "Homebrew installation completed!"
            echo "Please restart your shell or run: eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

install_aerc() {
    # PROGRAM: Aerc
    install_program "aerc"
}

install_bat() {
    # PROGRAM: Bat
    install_program "bat" "bat" "bat" "formula" "fallback_bat_apt" "fallback_bat_github"
}

install_neovim() {
    # PROGRAM: Neovim
    install_program "nvim" "neovim" "neovim"
}

install_k9s() {
    # PROGRAM: k9s
    install_program "k9s"
}

install_curl() {
    # PROGRAM: curl
    install_program "curl"
}

install_wget() {
    # PROGRAM: wget
    install_program "wget"
}

install_nmap() {
    # PROGRAM: Nmap
    install_program "nmap"
}

preview_install_program() {
    program_name="$1"
    script_path="${SCRIPT_PATH:-$0}"
    
    # Find the function content
    line_num=$(grep -n "# PROGRAM: $program_name" "$script_path" | cut -d: -f1)
    if [ -n "$line_num" ]; then
        start_line=$((line_num - 1))
        # Find the end of the function by looking for the closing brace
        end_line=$(tail -n +$start_line "$script_path" | grep -n "^}" | head -1 | cut -d: -f1)
        if [ -n "$end_line" ]; then
            end_line=$((start_line + end_line - 1))
            content=$(sed -n "${start_line},${end_line}p" "$script_path")
        else
            content=$(sed -n "${start_line},+30p" "$script_path")
        fi
        
        # Filter content for current OS
        current_os=$(uname)
        if echo "$content" | grep -q "case.*uname"; then
            # Function has OS-specific cases, show only relevant part
            echo "# Program: $program_name (showing $current_os specific code)"
            echo "# PROGRAM: $program_name"
            echo
            
            # Extract the relevant case block
            case "$current_os" in
                Darwin)
                    echo "$content" | sed -n "/Darwin)/,/;;/p" | sed "1d; \$d" | sed "s/^            //"
                    ;;
                Linux)
                    echo "$content" | sed -n "/Linux)/,/;;/p" | sed "1d; \$d" | sed "s/^            //"
                    ;;
                *)
                    echo "$content" | sed -n "/\*)/,/;;/p" | sed "1d; \$d" | sed "s/^            //"
                    ;;
            esac
        else
            # No OS-specific cases, show full function with cleaned indentation
            echo "$content" | sed "s/^        //; s/^    //"
        fi | {
            content=$(cat)
            if command -v shfmt >/dev/null 2>&1; then
                formatted=$(echo "$content" | shfmt -ln=posix -i=4 -ci 2>/dev/null) && echo "$formatted" || echo "$content"
            else
                echo "$content"
            fi
        }
    else
        echo "Program preview for: $program_name"
    fi
}


preview_network_interface() {
    interface="$1"
    
    echo "Interface: $interface"
    echo "=================="
    
    case "$(uname)" in
        Darwin)
            # Show interface configuration
            ifconfig "$interface" 2>/dev/null | head -20
            
            echo
            echo "Interface Statistics:"
            echo "===================="
            netstat -I "$interface" 2>/dev/null | head -5
            
            echo
            echo "Route Information:"
            echo "================"
            route -n get default 2>/dev/null | grep interface | head -3
            
            # Check if interface is wireless
            if ifconfig "$interface" 2>/dev/null | grep -q "media: IEEE 802.11"; then
                echo
                echo "Wireless Information:"
                echo "===================="
                /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | head -10 || echo "Wireless info not available"
            fi
            ;;
        Linux)
            if command -v ip >/dev/null 2>&1; then
                # Show IP configuration
                echo "IP Configuration:"
                echo "-----------------"
                ip addr show "$interface" 2>/dev/null | head -10
                
                echo
                echo "Link Information:"
                echo "----------------"
                ip link show "$interface" 2>/dev/null
                
                echo
                echo "Route Information:" 
                echo "================="
                ip route show dev "$interface" 2>/dev/null | head -5
            else
                # Fallback to ifconfig
                ifconfig "$interface" 2>/dev/null | head -15
            fi
            
            echo
            echo "Interface Statistics:"
            echo "===================="
            if [ -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
                rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null)
                tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null)
                rx_packets=$(cat /sys/class/net/$interface/statistics/rx_packets 2>/dev/null)
                tx_packets=$(cat /sys/class/net/$interface/statistics/tx_packets 2>/dev/null)
                echo "RX Bytes: $rx_bytes"
                echo "TX Bytes: $tx_bytes"
                echo "RX Packets: $rx_packets"
                echo "TX Packets: $tx_packets"
            else
                cat /proc/net/dev 2>/dev/null | grep "$interface" | head -1
            fi
            
            # Check if interface is wireless
            if [ -d "/sys/class/net/$interface/wireless" ]; then
                echo
                echo "Wireless Information:"
                echo "===================="
                if command -v iwconfig >/dev/null 2>&1; then
                    iwconfig "$interface" 2>/dev/null | head -10
                else
                    echo "iwconfig not available"
                fi
            fi
            ;;
    esac
}


show_network_interfaces() {
    # MENU: Show Network Interfaces
    echo "Loading network interfaces..."
    
    case "$(uname)" in
        Darwin)
            echo "Getting network interfaces..."
            interfaces=$(ifconfig -a 2>/dev/null | grep -E "^[a-z]" | cut -d: -f1 | sort)
            if [ -n "$interfaces" ]; then
                echo "$interfaces" | fzf \
                    --prompt="Browse network interfaces (ESC to exit): " \
                    --height=80% \
                    --reverse \
                    --header="Network Interfaces" \
                    --preview "source \"$script_path\" && preview_network_interface {} | bat --language=yaml --style=numbers,grid --color=always" \
                    --preview-window=right:60%:wrap || true
            else
                echo "No network interfaces found"
            fi
            ;;
        Linux)
            echo "Getting network interfaces..."
            if is_installed ip; then
                interfaces=$(ip link show 2>/dev/null | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//' | sort)
            else
                interfaces=$(cat /proc/net/dev 2>/dev/null | awk 'NR>2 {gsub(/:.*/, "", $1); print $1}' | sort)
            fi
            
            if [ -n "$interfaces" ]; then
                echo "$interfaces" | fzf \
                    --prompt="Browse network interfaces (ESC to exit): " \
                    --height=80% \
                    --reverse \
                    --header="Network Interfaces" \
                    --preview "source \"$script_path\" && preview_network_interface {} | bat --language=yaml --style=numbers,grid --color=always" \
                    --preview-window=right:60%:wrap || true
            else
                echo "No network interfaces found"
            fi
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

preview_open_port() {
    line="$1"
    
    case "$(uname)" in
        Darwin)
            # Parse macOS lsof format: COMMAND:PID PORT COMMAND
            pid=$(echo "$line" | cut -d":" -f2 | cut -f1)
            port=$(echo "$line" | cut -f2 | sed "s/->.*//; s/0x[0-9a-f]*//g")
            cmd=$(echo "$line" | cut -f3)
            
            echo "Port Information:"
            echo "================="
            echo "Port: $port"
            echo "Process ID: $pid"
            echo "Command: $cmd"
            echo
            
            if [ -n "$pid" ] && [ "$pid" != "PID" ]; then
                echo "Process Details:"
                echo "================"
                ps -p "$pid" -o pid,ppid,user,command 2>/dev/null || echo "Process not found"
                echo
                
                echo "Network Connections:"
                echo "==================="
                lsof -nP -p "$pid" 2>/dev/null | grep -E "(TCP|UDP)" | sed "s/->0x[0-9a-f]*//g; s/0x[0-9a-f]*//g" | head -10
            fi
            ;;
        Linux)
            # Parse Linux ss format: PORT PID ADDRESS
            port=$(echo "$line" | cut -f1)
            pid=$(echo "$line" | cut -f2)
            addr=$(echo "$line" | cut -f3)
            
            echo "Port Information:"
            echo "================="
            echo "Port: $port"
            echo "Address: $addr"
            echo "Process ID: $pid"
            echo
            
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                echo "Process Details:"
                echo "================"
                ps -p "$pid" -o pid,ppid,user,command 2>/dev/null || echo "Process not found"
                echo
                
                echo "Network Connections:"
                echo "==================="
                ss -p | grep "$pid" 2>/dev/null | head -5
            fi
            ;;
    esac
}

show_open_ports() {
    # MENU: Show Open Ports
    echo "Loading open ports..."
    
    case "$(uname)" in
        Darwin)
            if is_installed lsof; then
                    echo "Getting listening ports..."
                    ports=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {
                        # Clean up the address:port field to show only IP:PORT
                        gsub(/->.*/, "", $9);  # Remove connection info
                        gsub(/\[[0-9a-f:]+\]/, "", $9);  # Remove IPv6 brackets and hex
                        printf "%s:%s\t%s\t%s\n", $1, $2, $9, $1
                    }' | sort -t: -k2 -n)
                    if [ -n "$ports" ]; then
                        script_path="$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")"
                        echo "$ports" | fzf \
                            --prompt="Browse open ports (ESC to exit): " \
                            --height=80% \
                            --reverse \
                            --header="Process:PID    Port    Command" \
                            --preview "source \"$script_path\" && preview_open_port {} | bat --language=yaml --style=numbers --color=always" \
                            --preview-window=right:60%:wrap || true
                    else
                        echo "No listening ports found"
                    fi
            else
                echo "lsof is not available. Using netstat fallback..."
                echo "=== Open Ports (macOS) ==="
                netstat -an | grep LISTEN | head -20
            fi
            ;;
        Linux)
            if is_installed ss; then
                    echo "Getting listening ports..."
                    ports=$(ss -tlnp 2>/dev/null | awk 'NR>1 && $1=="LISTEN" {
                        # Extract port from address field
                        split($4, addr, ":");
                        port = addr[length(addr)];
                        
                        # Clean up address - remove IPv6 brackets and show readable format
                        address = $4;
                        gsub(/\[|\]/, "", address);  # Remove IPv6 brackets
                        gsub(/::ffff:/, "", address);  # Remove IPv6-mapped IPv4 prefix
                        
                        # Extract process info
                        process = $6;
                        gsub(/.*pid=/, "", process);
                        gsub(/,.*/, "", process);
                        if (process == "") process = "-";
                        
                        printf "%s\t%s\t%s\n", port, process, address
                    }' | sort -n)
                    if [ -n "$ports" ]; then
                        script_path="$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")"
                        echo "$ports" | fzf \
                            --prompt="Browse open ports (ESC to exit): " \
                            --height=80% \
                            --reverse \
                            --header="Port    PID    Address" \
                            --preview "source \"$script_path\" && preview_open_port {} | bat --language=yaml --style=numbers --color=always" \
                            --preview-window=right:60%:wrap || true
                    else
                        echo "No listening ports found"
                    fi
            elif is_installed netstat; then
                echo "=== Open Ports (Linux) ==="
                echo "TCP Listening Ports:"
                netstat -tlnp 2>/dev/null | head -20
                echo
                echo "UDP Listening Ports:"
                netstat -ulnp 2>/dev/null | head -10
            else
                echo "Neither ss nor netstat is available"
                return 1
            fi
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

show_system_info() {
    # MENU: Show System Info
    if is_installed fastfetch; then
        printf "${CYAN}System Information${NC}\n"
        printf "${CYAN}==================${NC}\n\n"
        fastfetch
    else
        if ask_install "fastfetch" "for better system information display" "install_fastfetch"; then
            printf "\n"
            fastfetch
        else
            printf "${CYAN}=== System Information ===${NC}\n"
            printf "${BLUE}OS:${NC} %s\n" "$(uname -s)"
            printf "${BLUE}Kernel:${NC} %s\n" "$(uname -r)"
            printf "${BLUE}Architecture:${NC} %s\n" "$(uname -m)"
            printf "${BLUE}Hostname:${NC} %s\n" "$(hostname)"
            printf "${BLUE}Uptime:${NC} %s\n" "$(uptime)"
            printf "${BLUE}Memory:${NC}\n"
            case "$(uname)" in
                Darwin)
                    system_profiler SPHardwareDataType | grep "Memory:"
                    ;;
                Linux)
                    free -h
                    ;;
            esac
            printf "${BLUE}Disk usage:${NC}\n"
            df -h
        fi
    fi
}

preview_installed_font() {
    font_family="$1"
    
    echo "Font variants for: $font_family"
    echo "========================"
    fc-list | grep -i "$font_family" | while IFS=: read -r path family; do
        echo "Family: $family"
        echo "Path: $path"
        echo
    done | head -30
}

show_installed_fonts() {
    # MENU: Show Installed Fonts
    echo "Loading installed fonts..."
    
    if is_installed fc-list; then
        
        # Use fzf to display fonts with preview showing paths and variants
        fonts=$(fc-list : family | sed 's/,.*$//' | sort | uniq)
        echo "$fonts" | fzf \
            --prompt="Browse fonts (ESC to exit): " \
            --height=80% \
            --reverse \
            --preview "source \"$script_path\" && preview_installed_font {} | bat --language=yaml --style=numbers --color=always" \
            --preview-window=right:60%:wrap \
            --header="Font families installed on your system" || true
    else
        case "$(uname)" in
            Darwin)
                echo "=== Installed Fonts (macOS) ==="
                find ~/Library/Fonts /Library/Fonts /System/Library/Fonts -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" 2>/dev/null | sed 's/.*\///' | sort
                echo
                echo "Note: Install fontconfig (brew install fontconfig) for better font listing with fc-list"
                ;;
            Linux)
                echo "fontconfig not installed. Installing it first..."
                if is_installed apt; then
                    sudo apt update && sudo apt install -y fontconfig
                elif is_installed dnf; then
                    sudo dnf install -y fontconfig
                elif is_installed pacman; then
                    sudo pacman -S fontconfig
                else
                    echo "Cannot install fontconfig automatically. Please install it manually."
                    return 1
                fi
                
                if is_installed fc-list; then
                    echo "=== Installed Fonts ==="
                    fc-list : family | sort | uniq
                fi
                ;;
            *)
                echo "Unsupported operating system"
                return 1
                ;;
        esac
    fi
}

preview_installed_program() {
    full_line="$1"
    
    case "$(uname)" in
        Darwin)
            # Extract type and program name from bracketed format
            type=$(echo "$full_line" | sed "s/\[\(.*\)\] .*/\1/")
            prog=$(echo "$full_line" | sed "s/\[.*\] //")
            
            echo "Program: $prog"
            echo "Type: $type"
            echo "========================"
            
            case "$type" in
                "Homebrew")
                    echo "Package Manager: Homebrew (Formula)"
                    if command -v "$prog" >/dev/null 2>&1; then
                        echo "Executable: $(which "$prog")"
                        echo "Version: $("$prog" --version 2>/dev/null | head -1 || echo "Version info not available")"
                    fi
                    echo
                    echo "Package info:"
                    brew info "$prog" 2>/dev/null | head -5
                    ;;
                "Homebrew Cask")
                    echo "Package Manager: Homebrew (Cask)"
                    echo "Type: macOS Application via Homebrew"
                    echo
                    echo "Cask info:"
                    brew info --cask "$prog" 2>/dev/null | head -5
                    ;;
                "App Store")
                    echo "Source: Mac App Store"
                    if [ -d "/Applications/$prog.app" ]; then
                        echo "Location: /Applications/$prog.app"
                        if [ -f "/Applications/$prog.app/Contents/Info.plist" ]; then
                            version=$(plutil -p "/Applications/$prog.app/Contents/Info.plist" 2>/dev/null | grep CFBundleShortVersionString | cut -d'"' -f4)
                            echo "Version: ${version:-Unknown}"
                        fi
                    fi
                    echo
                    if command -v mas >/dev/null 2>&1; then
                        echo "App Store info:"
                        mas_info=$(mas list | grep "$prog" | head -1)
                        if [ -n "$mas_info" ]; then
                            app_id=$(echo "$mas_info" | awk '{print $1}')
                            echo "App ID: $app_id"
                            mas info "$app_id" 2>/dev/null | head -8
                        else
                            echo "App info not found in mas list"
                        fi
                    else
                        echo "Install mas for detailed App Store info"
                    fi
                    ;;
                "System App")
                    echo "Source: System/Manual Installation"
                    echo "Location: /Applications/$prog.app"
                    if [ -f "/Applications/$prog.app/Contents/Info.plist" ]; then
                        version=$(plutil -p "/Applications/$prog.app/Contents/Info.plist" 2>/dev/null | grep CFBundleShortVersionString | cut -d'"' -f4)
                        echo "Version: ${version:-Unknown}"
                        bundle_id=$(plutil -p "/Applications/$prog.app/Contents/Info.plist" 2>/dev/null | grep CFBundleIdentifier | cut -d'"' -f4)
                        echo "Bundle ID: ${bundle_id:-Unknown}"
                    fi
                    ;;
            esac
            ;;
        Linux)
            pkg="$full_line"
            echo "Package: $pkg"
            echo "========================"
            
            if command -v apt >/dev/null 2>&1; then
                apt show "$pkg" 2>/dev/null | head -15
            elif command -v dnf >/dev/null 2>&1; then
                dnf info "$pkg" 2>/dev/null | head -15
            elif command -v pacman >/dev/null 2>&1; then
                pacman -Qi "$pkg" 2>/dev/null | head -15
            elif command -v yum >/dev/null 2>&1; then
                yum info "$pkg" 2>/dev/null | head -15
            else
                echo "Package manager info not available"
            fi
            ;;
    esac
}

show_installed_programs() {
    # MENU: Show Installed Programs
    echo "Loading installed programs..."
    
    case "$(uname)" in
        Darwin)
                # Build grouped list with prefixes
                programs=""
                
                if is_installed brew; then
                    echo "Getting Homebrew packages..."
                    brew_programs=$(brew list --formula 2>/dev/null | sed 's/^/[Homebrew] /' | sort)
                    programs="$programs$brew_programs"
                fi
                
                # Add Homebrew casks
                if is_installed brew; then
                    echo "Getting Homebrew casks..."
                    cask_programs=$(brew list --cask 2>/dev/null | sed 's/^/[Homebrew Cask] /' | sort)
                    if [ -n "$cask_programs" ]; then
                        programs="$programs
$cask_programs"
                    fi
                fi
                
                # Add App Store apps if available
                if is_installed mas; then
                    echo "Getting App Store apps..."
                    app_store_programs=$(mas list 2>/dev/null | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/^/[App Store] /' | sort)
                    if [ -n "$app_store_programs" ]; then
                        programs="$programs
$app_store_programs"
                    fi
                else
                    echo "Note: mas (Mac App Store CLI) not found"
                    if ask_install "mas" "to list App Store applications"; then
                        echo "Getting App Store apps..."
                        app_store_programs=$(mas list 2>/dev/null | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/^/[App Store] /' | sort)
                        if [ -n "$app_store_programs" ]; then
                            programs="$programs
$app_store_programs"
                        fi
                    fi
                fi
                
                # Add system applications
                echo "Getting system applications..."
                system_apps=$(find /Applications -maxdepth 1 -name "*.app" -type d 2>/dev/null | sed 's|/Applications/||; s|.app$||' | sed 's/^/[System App] /' | sort)
                if [ -n "$system_apps" ]; then
                    programs="$programs
$system_apps"
                fi
                
                echo "$programs" | grep -v "^$" | fzf \
                    --prompt="Browse programs (ESC to exit): " \
                    --height=80% \
                    --reverse \
                    --preview "source \"$script_path\" && preview_installed_program {} | bat --language=yaml --style=numbers --color=always" \
                    --preview-window=right:60%:wrap \
                    --header="Installed programs on your macOS system" || true
            ;;
        Linux)
                programs=""
                
                if is_installed apt; then
                    echo "Getting APT packages..."
                    programs=$(apt list --installed 2>/dev/null | grep -v "WARNING" | cut -d'/' -f1 | sort)
                elif is_installed dnf; then
                    echo "Getting DNF packages..."
                    programs=$(dnf list installed 2>/dev/null | awk 'NR>1 {print $1}' | cut -d'.' -f1 | sort)
                elif is_installed pacman; then
                    echo "Getting Pacman packages..."
                    programs=$(pacman -Q 2>/dev/null | awk '{print $1}' | sort)
                elif is_installed yum; then
                    echo "Getting YUM packages..."
                    programs=$(yum list installed 2>/dev/null | awk 'NR>1 {print $1}' | cut -d'.' -f1 | sort)
                else
                    echo "No supported package manager found"
                    return 1
                fi
                
                echo "$programs" | fzf \
                    --prompt="Browse packages (ESC to exit): " \
                    --height=80% \
                    --reverse \
                    --preview "source \"$script_path\" && preview_installed_program {} | bat --language=yaml --style=numbers --color=always" \
                    --preview-window=right:60%:wrap \
                    --header="Installed packages on your Linux system" || true
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

clean_cache() {
    # MENU: Clean Cache
    run_platform_operation "Cleaning system cache" \
        "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; rm -rf ~/Library/Caches/*" \
        "sudo sync && sudo sysctl -w vm.drop_caches=3; rm -rf ~/.cache/*" \
        "Cache cleaned"
}

clean_dns_cache() {
    # MENU: Clean DNS Cache
    run_platform_operation "Clearing DNS cache" \
        "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder" \
        "clear_linux_dns_cache" \
        "DNS cache cleared"
}

check_internet_speed() {
    # MENU: Check Internet Speed
    printf "${CYAN}Internet Speed Test${NC}\n"
    printf "${CYAN}===================${NC}\n\n"
    
    case "$(uname)" in
        Darwin)
            if ! is_installed speedtest; then
                printf "${YELLOW}speedtest is not installed.${NC}\n"
                if ask_install "speedtest" "to test your internet speed" "install_speedtest_cli"; then
                    printf "${GREEN}speedtest installed successfully!${NC}\n"
                else
                    printf "${RED}Cannot check internet speed without speedtest${NC}\n"
                    return 1
                fi
            fi
            
            printf "${BLUE}Testing internet speed...${NC}\n"
            printf "${YELLOW}This may take a moment...${NC}\n\n"
            speedtest
            ;;
        Linux)
            if ! is_installed speedtest-cli; then
                printf "${YELLOW}speedtest-cli is not installed.${NC}\n"
                if ask_install "speedtest-cli" "to test your internet speed" "install_speedtest_cli"; then
                    printf "${GREEN}speedtest-cli installed successfully!${NC}\n"
                else
                    printf "${RED}Cannot check internet speed without speedtest-cli${NC}\n"
                    return 1
                fi
            fi
            
            printf "${BLUE}Testing internet speed...${NC}\n"
            printf "${YELLOW}This may take a moment...${NC}\n\n"
            speedtest-cli
            ;;
        *)
            printf "${RED}Unsupported operating system${NC}\n"
            return 1
            ;;
    esac
}

show_routing() {
    # MENU: Show Routing
    printf "${CYAN}Network Routing Information${NC}\n"
    printf "${CYAN}===========================${NC}\n\n"
    
    case "$(uname)" in
        Darwin)
            printf "${BLUE}Default Route:${NC}\n"
            route get default 2>/dev/null | grep -E "(gateway|interface)" | sed "s/gateway:/$(printf "${GREEN}gateway:${NC}")/" | sed "s/interface:/$(printf "${YELLOW}interface:${NC}")/"
            
            printf "\n${BLUE}Routing Table:${NC}\n"
            netstat -rn | head -20 | while IFS= read -r line; do
                if echo "$line" | grep -q "^default"; then
                    printf "${GREEN}%s${NC}\n" "$line"
                elif echo "$line" | grep -qE "^[0-9]"; then
                    printf "${YELLOW}%s${NC}\n" "$line"
                else
                    printf "%s\n" "$line"
                fi
            done
            ;;
        Linux)
            printf "${BLUE}Default Route:${NC}\n"
            ip route show default 2>/dev/null | sed "s/default/$(printf "${GREEN}default${NC}")/" | sed "s/via/$(printf "${YELLOW}via${NC}")/" | sed "s/dev/$(printf "${CYAN}dev${NC}")/"
            
            printf "\n${BLUE}Routing Table:${NC}\n"
            ip route show | head -20 | while IFS= read -r line; do
                if echo "$line" | grep -q "^default"; then
                    printf "${GREEN}%s${NC}\n" "$line"
                elif echo "$line" | grep -qE "^[0-9]"; then
                    printf "${YELLOW}%s${NC}\n" "$line"
                else
                    printf "%s\n" "$line"
                fi
            done
            ;;
    esac
    
    printf "\n${BLUE}Network Interfaces:${NC}\n"
    case "$(uname)" in
        Darwin)
            ifconfig | grep -E "^[a-z]|inet " | while IFS= read -r line; do
                if echo "$line" | grep -q "^[a-z]"; then
                    printf "${CYAN}%s${NC}\n" "$line"
                else
                    printf "  ${GREEN}%s${NC}\n" "$line"
                fi
            done
            ;;
        Linux)
            ip addr show | grep -E "^[0-9]|inet " | while IFS= read -r line; do
                if echo "$line" | grep -q "^[0-9]"; then
                    printf "${CYAN}%s${NC}\n" "$line"
                else
                    printf "  ${GREEN}%s${NC}\n" "$line"
                fi
            done
            ;;
    esac
}

check_dns() {
    # MENU: Check DNS
    printf "${CYAN}DNS Configuration Check${NC}\n"
    printf "${CYAN}======================${NC}\n"
    
    case "$(uname)" in
        Darwin)
            printf "${BLUE}Current DNS servers:${NC}\n"
            scutil --dns | grep 'nameserver\[[0-9]*\]' | head -10
            
            printf "\n"
            printf "${BLUE}Network service DNS settings:${NC}\n"
            dns_settings=$(networksetup -getdnsservers "Wi-Fi" 2>/dev/null || networksetup -getdnsservers "Ethernet" 2>/dev/null || echo "Could not retrieve DNS settings")
            printf "${YELLOW}%s${NC}\n" "$dns_settings"
            ;;
        Linux)
            printf "${BLUE}Current DNS servers:${NC}\n"
            if [ -f /etc/resolv.conf ]; then
                grep "^nameserver" /etc/resolv.conf
            fi
            
            if command -v systemd-resolve >/dev/null 2>&1; then
                printf "\n"
                printf "${BLUE}systemd-resolved status:${NC}\n"
                systemd-resolve --status | head -20
            elif command -v resolvectl >/dev/null 2>&1; then
                printf "\n"
                printf "${BLUE}resolvectl status:${NC}\n"
                resolvectl status | head -20
            fi
            ;;
    esac
    
    printf "\n"
    printf "${CYAN}Testing DNS resolution...${NC}\n"
    printf "${CYAN}========================${NC}\n"
    
    test_domains="google.com cloudflare.com github.com"
    for domain in $test_domains; do
        printf "Resolving ${YELLOW}%s${NC}: " "$domain"
        if nslookup "$domain" >/dev/null 2>&1; then
            ip=$(nslookup "$domain" 2>/dev/null | awk '/^Address: / { print $2 }' | head -1)
            printf "${GREEN}✓ %s${NC}\n" "$ip"
        else
            printf "${RED}✗ Failed${NC}\n"
        fi
    done
    
    printf "\n"
    printf "${CYAN}DNS response times:${NC}\n"
    printf "${CYAN}===================${NC}\n"
    for domain in $test_domains; do
        printf "${YELLOW}%s${NC}: " "$domain"
        time_result=$( { time nslookup "$domain" >/dev/null 2>&1; } 2>&1 | grep real | awk '{print $2}' || echo "timeout")
        if [ "$time_result" = "timeout" ]; then
            printf "${RED}%s${NC}\n" "$time_result"
        else
            printf "${GREEN}%s${NC}\n" "$time_result"
        fi
    done
}

install_font() {
    font_name="$1"
    font_url="$2"
    
    echo "Installing $font_name..."
    
    case "$(uname)" in
        Darwin)
            temp_dir="/tmp/font_install"
            mkdir -p "$temp_dir"
            cd "$temp_dir"
            
            curl -L "$font_url" -o font.zip
            unzip -q font.zip
            
            font_dir="$HOME/Library/Fonts"
            mkdir -p "$font_dir"
            
            find . -name "*.ttf" -o -name "*.otf" | while read -r font_file; do
                cp "$font_file" "$font_dir/"
            done
            
            cd - >/dev/null
            rm -rf "$temp_dir"
            echo "$font_name installed successfully!"
            ;;
        Linux)
            temp_dir="/tmp/font_install"
            mkdir -p "$temp_dir"
            cd "$temp_dir"
            
            curl -L "$font_url" -o font.zip
            unzip -q font.zip
            
            font_dir="$HOME/.local/share/fonts"
            mkdir -p "$font_dir"
            
            find . -name "*.ttf" -o -name "*.otf" | while read -r font_file; do
                cp "$font_file" "$font_dir/"
            done
            
            fc-cache -fv
            
            cd - >/dev/null
            rm -rf "$temp_dir"
            echo "$font_name installed successfully!"
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

install_programs_menu() {
    # MENU: Install Programs
    # Get all install functions from the script
    script_path="$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")"
    install_functions=$(grep "^[[:space:]]*# PROGRAM:" "$script_path" | sed 's/.*# PROGRAM: //' | sort)
    
    # Add special entries
    programs="$install_functions"

    choice=$(echo "$programs" | fzf \
        --prompt="Select a program to install (ESC to return): " \
        --height=80% \
        --reverse \
        --preview "source \"$script_path\" && SCRIPT_PATH=\"$script_path\" preview_install_program {} | bat --language=bash --style=numbers --color=always" \
        --preview-window=right:50%:wrap) || choice=""
    
    case "$choice" in
        "")
            return 0
            ;;
        *)
            # Find and execute the corresponding install function
            func_name=$(grep -B 1 "^[[:space:]]*# PROGRAM: $choice" "$script_path" | head -1 | cut -d"(" -f1)
            if [ -n "$func_name" ] && command -v "$func_name" >/dev/null 2>&1; then
                "$func_name"
            else
                echo "Invalid selection: $choice"
                return 1
            fi
            ;;
    esac
}

get_nerd_fonts_list() {
    # Fetch the latest release info from GitHub API
    if command -v curl >/dev/null 2>&1; then
        curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | \
            grep '"browser_download_url".*\.zip"' | \
            sed 's/.*"\(https:\/\/github\.com\/ryanoasis\/nerd-fonts\/releases\/download\/[^"]*\/\([^"]*\)\.zip\)".*/\2|\1/' | \
            grep -v '\.(tar\.xz|tar\.gz)$' | \
            sort
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | \
            grep '"browser_download_url".*\.zip"' | \
            sed 's/.*"\(https:\/\/github\.com\/ryanoasis\/nerd-fonts\/releases\/download\/[^"]*\/\([^"]*\)\.zip\)".*/\2|\1/' | \
            grep -v '\.(tar\.xz|tar\.gz)$' | \
            sort
    else
        echo "Neither curl nor wget is available to fetch the latest font list."
        echo
        if ask_install "curl" "to fetch the latest Nerd Fonts list from GitHub" "install_curl"; then
            # Retry with newly installed curl
            curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | \
                grep '"browser_download_url".*\.zip"' | \
                sed 's/.*"\(https:\/\/github\.com\/ryanoasis\/nerd-fonts\/releases\/download\/[^"]*\/\([^"]*\)\.zip\)".*/\2|\1/' | \
                grep -v '\.(tar\.xz|tar\.gz)$' | \
                sort
        elif ask_install "wget" "as an alternative to fetch the latest Nerd Fonts list from GitHub" "install_wget"; then
            # Retry with newly installed wget
            wget -qO- "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | \
                grep '"browser_download_url".*\.zip"' | \
                sed 's/.*"\(https:\/\/github\.com\/ryanoasis\/nerd-fonts\/releases\/download\/[^"]*\/\([^"]*\)\.zip\)".*/\2|\1/' | \
                grep -v '\.(tar\.xz|tar\.gz)$' | \
                sort
        else
            echo "Error: Cannot fetch font list without curl or wget."
            echo "Font installation requires one of these tools to download from GitHub."
            return 1
        fi
    fi
}

preview_nerd_font() {
    font_name="$1"
    
    echo "Nerd Font: $font_name"
    echo "========================"
    echo "Repository: https://github.com/ryanoasis/nerd-fonts"
    echo "License: MIT License"
    echo
    echo "Description:"
    echo "Nerd Fonts is a project that patches developer targeted fonts"
    echo "with a high number of glyphs (icons). Specifically to add a high"
    echo "number of extra glyphs from popular 'iconic fonts'."
    echo
    echo "Features:"
    echo "• Over 3,600+ glyphs/icons combined"
    echo "• Includes icons from Font Awesome, Devicons, Octicons and more"
    echo "• Monospaced (fixed-width) fonts for terminal/editor use"
    echo "• Available in multiple weights and styles"
    echo
    echo "Installation will:"
    echo "1. Download the font ZIP file"
    echo "2. Extract fonts to system font directory"
    echo "3. Refresh font cache (if available)"
    echo
    echo "Font file: $font_name.zip"
    
    # Show if font is already installed
    if is_installed fc-list && fc-list | grep -qi "$font_name"; then
        echo
        echo "Status: ✓ Already installed"
        echo "Installed variants:"
        fc-list | grep -i "$font_name" | head -5
    else
        echo
        echo "Status: Not installed"
    fi
}

install_font_menu() {
    # MENU: Install Fonts
    echo "Fetching latest Nerd Fonts list..."
    
    fonts_data=$(get_nerd_fonts_list)
    if [ -z "$fonts_data" ]; then
        echo "Error: Could not fetch font list. Please check your internet connection."
        return 1
    fi
    
    # Check installation status and format list
    echo "Checking font installation status..."
    fonts_with_status=""
    
    while IFS='|' read -r font_name font_url; do
        if [ -n "$font_name" ]; then
            if is_installed fc-list && fc-list | grep -qi "$font_name"; then
                fonts_with_status="$fonts_with_status$font_name \033[32m[INSTALLED]\033[0m
"
            else
                fonts_with_status="$fonts_with_status$font_name
"
            fi
        fi
    done << EOF
$fonts_data
EOF
    
    script_path="$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")"
    
    choice=$(echo "$fonts_with_status" | grep -v '^$' | fzf \
        --prompt="Select a Nerd Font to install (✓=installed, ESC to return): " \
        --height=80% \
        --reverse \
        --ansi \
        --preview "source \"$script_path\" && preview_nerd_font \$(echo {} | sed 's/ \\033\[32m\\[INSTALLED\\]\\033\[0m//') | bat --language=yaml --style=numbers --color=always" \
        --preview-window=right:50%:wrap) || return 0
    
    if [ -n "$choice" ]; then
        # Clean the choice to get the font name
        clean_choice=$(echo "$choice" | sed 's/ \033\[32m\[INSTALLED\]\033\[0m//')
        
        # Check if font is already installed
        if echo "$choice" | grep -q "\[INSTALLED\]"; then
            echo "Font '$clean_choice' is already installed."
            printf "Do you want to reinstall it? (y/N): "
            read -r confirm
            case "$confirm" in
                y|Y|yes|Yes)
                    echo "Proceeding with reinstallation..."
                    ;;
                *)
                    echo "Installation cancelled."
                    return 0
                    ;;
            esac
        fi
        
        # Get the URL for the selected font
        font_url=$(echo "$fonts_data" | grep "^$clean_choice|" | cut -d'|' -f2)
        if [ -n "$font_url" ]; then
            install_font "$clean_choice Nerd Font" "$font_url"
        else
            echo "Error: Could not find download URL for $clean_choice"
            return 1
        fi
    fi
}

preview_menu_item() {
    menu_item="$1"
    script_path="${SCRIPT_PATH:-$0}"
    
    if [ "$menu_item" = "Exit" ]; then
        echo "Exit the Omni tool"
    else
        # Find the function content
        line_num=$(grep -n "# MENU: $menu_item" "$script_path" | cut -d: -f1)
        if [ -n "$line_num" ]; then
            start_line=$((line_num - 1))
            # Find the end of the function by looking for the closing brace
            end_line=$(tail -n +$start_line "$script_path" | grep -n "^}" | head -1 | cut -d: -f1)
            if [ -n "$end_line" ]; then
                end_line=$((start_line + end_line - 1))
                content=$(sed -n "${start_line},${end_line}p" "$script_path")
            else
                content=$(sed -n "${start_line},+30p" "$script_path")
            fi
            
            # Filter content for current OS
            current_os=$(uname)
            if echo "$content" | grep -q "case.*uname"; then
                # Function has OS-specific cases, show only relevant part
                echo "# Function: $menu_item (showing $current_os specific code)"
                echo "# MENU: $menu_item"
                echo
                
                # Extract the relevant case block
                case "$current_os" in
                    Darwin)
                        echo "$content" | sed -n "/Darwin)/,/;;/p" | sed "1d; \$d" | sed "s/^            //"
                        ;;
                    Linux)
                        echo "$content" | sed -n "/Linux)/,/;;/p" | sed "1d; \$d" | sed "s/^            //"
                        ;;
                    *)
                        echo "$content" | sed -n "/\*)/,/;;/p" | sed "1d; \$d" | sed "s/^            //"
                        ;;
                esac
            else
                # No OS-specific cases, show full function with cleaned indentation
                echo "$content" | sed "s/^        //; s/^    //"
            fi | {
                content=$(cat)
                if command -v shfmt >/dev/null 2>&1; then
                    formatted=$(echo "$content" | shfmt -ln=posix -i=4 -ci 2>/dev/null) && echo "$formatted" || echo "$content"
                else
                    echo "$content"
                fi
            }
        else
            echo "Function preview for: $menu_item"
        fi
    fi
}


main_menu() {
    while true; do
        script_path="$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || echo "$0")"
        functions=$(grep "^[[:space:]]*# MENU:" "$script_path" | sed 's/.*# MENU: //' | sort)
        functions="$functions
Exit"

        choice=$(echo "$functions" | fzf \
            --prompt="Select a function: " \
            --reverse \
            --preview "source \"$script_path\" && SCRIPT_PATH=\"$script_path\" preview_menu_item {} | bat --language=bash --style=numbers --color=always" \
            --preview-window=right:50%:wrap)
        
        case "$choice" in
            "Exit")
                exit 0
                ;;
            "")
                # ESC pressed in main menu, continue loop (don't exit)
                continue
                ;;
            *)
                # Find and execute function based on menu choice
                func_name=$(grep -B 1 "# MENU: $choice" "$script_path" | head -1 | sed 's/() {.*//' | awk '{print $1}')
                if [ -n "$func_name" ] && command -v "$func_name" >/dev/null 2>&1; then
                    "$func_name"
                    
                    # Don't prompt for "Press Enter" for viewing functions that use fzf
                    case "$func_name" in
                        show_installed_programs|show_installed_fonts|show_network_interfaces|show_open_ports|font_menu|install_programs_menu)
                            # These functions handle their own interaction, don't prompt
                            ;;
                        *)
                            # Regular functions that perform actions need confirmation
                            echo
                            printf "Press Enter to continue or Ctrl+C to exit..."
                            read -r
                            ;;
                    esac
                else
                    echo "Invalid selection: $choice"
                fi
                ;;
        esac
    done
}

check_dependencies() {
    # Check for Homebrew on macOS (required for many installations)
    if [ "$(uname)" = "Darwin" ] && ! is_installed brew; then
        if ! ask_install "Homebrew" "as it is required for installing most tools on macOS" "install_homebrew"; then
            echo "Homebrew is required for this tool to function properly on macOS. Exiting."
            exit 1
        fi
        echo
    fi
    
    if ! is_installed fzf; then
        if ! ask_install "fzf" "as it is required for this tool to work" "install_fzf"; then
            echo "fzf is required for this tool to function. Exiting."
            exit 1
        fi
        echo
    fi
    
    if ! is_installed bat; then
        if ! ask_install "bat" "as it is required for enhanced syntax-highlighted previews" "install_bat"; then
            echo "bat is required for this tool to function properly. Exiting."
            exit 1
        fi
        echo
    fi
    
    if ! is_installed shfmt; then
        ask_install "shfmt" "for shell script formatting and POSIX compliance checking" "install_shfmt"
        echo
    fi
}


main() {
    # echo "Welcome to Omni - System Management Tool"
    # echo "========================================"
    
    check_dependencies
    
    main_menu
}

if ! is_sourced; then
    main "$@"
fi

