#!/bin/bash

wait-ostree() {
    # Wait until rpm-ostree is idle
    while ! rpm-ostree status | grep -q "State: idle"; do
        echo "⏳ rpm-ostree not idle yet..."
        sleep 5
    done

    # Only allow rpm-ostree or ostree commands
    case "$1" in
        rpm-ostree|ostree)
            echo "✅ rpm-ostree is idle, running: $*"
            sudo "$@"
            ;;
        *)
            echo "❌ Error: command must start with 'rpm-ostree' or 'ostree'"
            return 1
            ;;
    esac
}

flatpak_auto_update(){
    # flatpak | Download flatpak service files
    flatpakDownloadList=(
        "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/etc/systemd/system/flatpak-automatic.service"
        "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/etc/systemd/system/flatpak-automatic.timer"
    )

    for fileURL in "${flatpakDownloadList[@]}"; do
        fileName=$(basename "$fileURL")
        if [[ ! -f "/etc/systemd/system/$fileName" ]]; then
            sudo wget -O "/etc/systemd/system/$fileName" "$fileURL"
            sudo systemctl daemon-reload
            sudo systemctl enable "$fileName" --now
        else
            echo "File '$fileName' already exists - skipping download"
        fi
    done
}


# Function to update Flatpak apps
install_flatpak_apps() {

	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Install flatpaks
    flatpak install -y --noninteractive flathub org.mozilla.firefox      
    xdg-settings set default-web-browser org.mozilla.firefox.desktop

    while IFS= read -r flatpak_app; do
        # Skip empty lines and lines starting with #
        [[ -z "$flatpak_app" || "$flatpak_app" =~ ^[[:space:]]*# ]] && continue
        flatpak install -y --noninteractive flathub "$flatpak_app"
    done < <(wget -O - https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/flatpak_apps.txt)

    # Update all flatpaks
    flatpak update -y --noninteractive

}

# Function to update RPM-OSTree apps
rpm_ostree_config() {
    # rpm-ostreee | set staging config
    sudo sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf

    # rpm-ostree | Enable staging for rpm-ostree + timer service
    sudo systemctl enable rpm-ostreed-automatic.timer --now

    # Remove firefox - replaced by flatpak
    wait-ostree rpm-ostree override remove firefox firefox-langpacks

    wait-ostree ostree remote add tailscale https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    wait-ostree rpm-ostree install tailscale

    # now register the device into the tailnet
    echo "Tailscale - Reboot and run the following commands:"
    echo ">>>> sudo systemctl enable --now tailscaled"
    echo ">>>> sudo tailscale up"
}

flatpak_auto_update

# Update Flatpak apps
install_flatpak_apps

# Update RPM-OSTree apps
rpm_ostree_config

# Download font 
customFontName="FiraCode"
customFontFile="$customFontName.zip"
fontURL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$customFontName.zip"
fontDir="${user_home}/.local/share/fonts/$customFontName"

if [[ ! -d $fontDir ]]; then
    sudo -u $username -- curl -L -O $fontURL
    sudo -u $username -- mkdir -p $fontDir
    sudo -u $username -- unzip $customFontFile -d $fontDir
    sudo -u $username -- rm $customFontFile
else
    echo "Font '$customFontName' already installed - skipping"
fi

