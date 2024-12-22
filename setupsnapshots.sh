#!/usr/bin/bash

# Function to greet the user
greet_user() {
    local username
    username=$(whoami)
    echo "Hello, $username-sama!"
    sleep 1
}

# Detect package manager (Arch or Debian)
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then
        echo "==>> Arch-based system detected."
        PKG_MANAGER="pacman"
        AUR_HELPER="yay"
    elif command -v apt >/dev/null 2>&1; then
        echo "==>> Debian-based system detected."
        PKG_MANAGER="apt"
    else
        echo "==<>Unsupported system. Exiting..."
        exit 1
    fi
}

# Install timeshift if not already installed
get_timeshift() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
        if ! command -v timeshift >/dev/null 2>&1; then
            echo "==>> timeshift is not installed! Installing it now..."
            sudo pacman -Syyu --needed --noconfirm --color=auto timeshift
        else
            echo "==>> timeshift is already installed."
            echo "==<> moving on..."
        fi
    elif [ "$PKG_MANAGER" = "apt" ]; then
        if ! command -v timeshift >/dev/null 2>&1; then
            echo "==>> timeshift is not installed! Installing it now..."
            sudo apt update && sudo apt install -y --no-install-recommends timeshift
        else
            echo "==>> timeshift is already installed."
            echo "==<> moving on..."
        fi
    fi
}

# Enable cronie or cron service
enable_cron_serv() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
        sudo systemctl enable --now cronie.service
	echo "==>> cronie service enabled!"
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo systemctl enable --now cron.service
	echo "==>> cron service enabled!"
    fi
}

# Install timeshift-autosnap and grub-btrfs for Arch or btrfs-progs & snapper, snapper-gui for Debian
get_deps() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
	echo "==>> installing timeshift-autosnap from uar..."
        $AUR_HELPER -S --noconfirm timeshift-autosnap
        sleep 1
	echo "==>> installing grub-btrfs..."
        sudo pacman -S --needed --noconfirm grub-btrfs
    elif [ "$PKG_MANAGER" = "apt" ]; then
        echo "==>> Installing snapper and btrfs-progs..."
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
	echo "==>> Reconfiguring grub.cfg"
	sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# Enable grub-btrfsd service
grub_btrfsd_serv() {
	echo "==>> Enabling grub-btrfsd service..."
    if [ "$PKG_MANAGER" = "pacman" ]; then
        sudo systemctl enable --now grub-btrfsd
    elif [ "$PKG_MANAGER" = "apt" ]; then
        echo "No additional services to enable for snapper."
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

echo "==>> BTRFS snapshot setup completed!"
