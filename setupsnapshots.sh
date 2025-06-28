#!/usr/bin/bash

# Color definitions
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;36m'
NC='\033[0m' # No color

# Function to greet the user
greet_user() {
    local username
    username=$(whoami)
    echo -e "${ORANGE}Hello, $username ${NC}"
}

# Detect package manager (Arch or Debian)
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then
        echo -e "${ORANGE}==>> Arch-based system detected.${NC}"
        PKG_MANAGER="pacman"
        AUR_HELPER="yay"
    elif command -v apt >/dev/null 2>&1; then
        echo -e "${ORANGE}==>> Debian-based system detected.${NC}"
        PKG_MANAGER="apt"
    else
        echo -e "${RED}==<> Unsupported system. Exiting...${NC}"
        exit 1
    fi
}

# Install timeshift if not already installed
get_timeshift() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
        if ! command -v timeshift >/dev/null 2>&1; then
            echo -e "${ORANGE}==>> timeshift is not installed! Installing it now...${NC}"
            sudo pacman -Syyu --needed --noconfirm --color=auto timeshift
        else
            echo -e "${ORANGE}==>> timeshift is already installed.${NC}"
        fi
    elif [ "$PKG_MANAGER" = "apt" ]; then
        if ! command -v timeshift >/dev/null 2>&1; then
            echo -e "${ORANGE}==>> timeshift is not installed! Installing it now...${NC}"
            sudo apt update && sudo apt install -y --no-install-recommends timeshift
        else
            echo -e "${ORANGE}==>> timeshift is already installed.${NC}"
            echo -e "${ORANGE}==<> moving on...${NC}"
        fi
    fi
}

# Enable cronie or cron service
enable_cron_serv() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
        sudo systemctl enable --now cronie.service
        echo -e "${GREEN}==>> cronie service enabled ✓successfully.${NC}"
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo systemctl enable --now cron.service
        echo -e "${GREEN}==>> cron service enabled ✓successfully.${NC}"
    fi
}

# Install timeshift-autosnap and grub-btrfs for Arch or btrfs-progs & snapper, snapper-gui for Debian
get_deps() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
        echo -e "${ORANGE}==>> installing timeshift-autosnap from uar...${NC}"
        $AUR_HELPER -S --noconfirm timeshift-autosnap
        /etc/timeshift-autosnap.conf
        sleep 1
        echo -e "${ORANGE}==>> installing grub-btrfs...${NC}"
        sudo pacman -S --needed --noconfirm grub-btrfs
    elif [ "$PKG_MANAGER" = "apt" ]; then
        echo -e "${ORANGE}==>> Installing snapper and btrfs-progs...${NC}"
        sudo apt install -y --no-install-recommends snapper snapper-gui btrfs-progs
    fi
}

# Modify grub-btrfsd for Arch or configure snapper for Debian
edit_grub_btrfsd() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
        local grub_btrfsd_service="/usr/lib/systemd/system/grub-btrfsd.service"
        sudo cp "$grub_btrfsd_service" "${grub_btrfsd_service}.bak"

        if sudo grep -q '/.snapshots' "$grub_btrfsd_service"; then
            echo "==>> Modifying grub-btrfsd service to use Timeshift auto snapshots..."
            sudo sed -i 's|ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' "$grub_btrfsd_service"
            echo "==>> Modification complete."
        else
            echo "==>> grub-btrfsd service already configured for Timeshift auto snapshots."
            echo "==>> moving on..."
        fi
    elif [ "$PKG_MANAGER" = "apt" ]; then
        echo "==>> Configuring snapper for BTRFS snapshots..."
        sudo snapper -c root create-config /
        echo "==>> Snapper configuration complete."
    fi
}

# Rebuild the grub configuration
rebuild_grub_config() {
	echo -e "${ORANGE}==>> Reconfiguring grub.cfg.${NC}"
	sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# Enable grub-btrfsd service
grub_btrfsd_serv() {
	echo -e "${ORANGE}==>> Enabling grub-btrfsd service...${NC}"
    if [ "$PKG_MANAGER" = "pacman" ]; then
        sudo systemctl enable --now grub-btrfsd
        echo -e "${GREEN}==>> grub-btrfsd service enabled ✓successfully.${NC}"
    elif [ "$PKG_MANAGER" = "apt" ]; then
        echo -e "${RED}==<> No additional services to enable for snapper.${NC}"
    fi
}

# Main script execution
greet_user
detect_package_manager
get_timeshift
enable_cron_serv
get_deps
edit_grub_btrfsd
rebuild_grub_config
grub_btrfsd_serv

echo -e "${YELLOW}==>> BTRFS snapshot setup completed ✓successfully.${NC}"
