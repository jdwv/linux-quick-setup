#!/bin/bash

# Function to update the script from Git
self_update() {
    cd $1 || exit
    #git pull origin main
}

# Function to update Flatpak apps
update_flatpak_apps() {
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Install flatpaks
    flatpak install -y --noninteractive flathub org.mozilla.firefox      
    xdg-settings set default-web-browser org.mozilla.firefox.desktop

    while IFS= read -r flatpak_app; do
        flatpak install -y --noninteractive flathub "$flatpak_app"
    #done < "$CONFIG_DIR/flatpak_apps.txt"
    done < $(wget -O - https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/flatpak_apps.txt)

}

# Function to update RPM-OSTree apps
update_rpm_ostree_apps() {
    while IFS= read -r rpm_ostree_app; do
        rpm-ostree install -y "$rpm_ostree_app"
    #done < "$CONFIG_DIR/rpm-ostree_apps.txt"
    done < $(wget -O - https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/rpm-ostree_apps.txt)
}

# Set CONFIG_DIR to the directory where the script is located

MY_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
MY_PATH="$(cd -- "$MY_PATH" && pwd)"
CONFIG_DIR=$MY_PATH

# Perform self-update from Git
#self_update $CONFIG_DIR

# Update Flatpak apps
update_flatpak_apps

# Update RPM-OSTree apps
update_rpm_ostree_apps
