#!/bin/bash

# Function to update Flatpak apps
update_flatpak_apps() {
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Install flatpaks
    flatpak install -y --noninteractive flathub org.mozilla.firefox      
    xdg-settings set default-web-browser org.mozilla.firefox.desktop

    while IFS= read -r flatpak_app; do
        flatpak install -y --noninteractive flathub "$flatpak_app"
    done < <(wget -O - https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/flatpak_apps.txt)

}

# Function to update RPM-OSTree apps
update_rpm_ostree_apps() {
    while IFS= read -r rpm_ostree_app; do
        rpm-ostree install -y "$rpm_ostree_app"
    done < <(wget -O - https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/rpm-ostree_apps.txt)
}

# Update Flatpak apps
update_flatpak_apps

# Update RPM-OSTree apps
update_rpm_ostree_apps
