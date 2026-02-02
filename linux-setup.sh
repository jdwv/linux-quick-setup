#!/usr/bin/bash

# Set home dir to sudo user
username=$(whoami)
user_home=$(getent passwd "$username" | cut -d: -f6)

cd $user_home

# Super bad it, don't do this. I wrote this file, therefore I trust it.
# wget -O - https://thisfile.sh | bash

# Funtions
popd_if_stack_not_empty() {
    # Check if the directory stack has more than one entry
    if [[ $(dirs -p | wc -l) -gt 1 ]]; then
        # Run popd only if the stack is not empty
        popd
    fi
}

install_gui_apps() {
    echo "Trying flatpaks - $XDG_SESSION_TYPE - $DISPLAY"
    if xhost >& /dev/null; then
        echo "Trying flatpaks - $installString"
        #if pgrep -x "gnome-shell" > /dev/null; then
            #echo "GNOME is installed - installing gnome-tweaks"
            # Install gnome-tweaks
            #eval "sudo $installString gnome-tweaks"
        #fi

        #################
        # Flatpak stuff #
        #################
        if ! command -v flatpak &>/dev/null; then
            echo "Flatpak is not installed. Installing Flatpak..."
            eval "sudo $installString flatpak"
            #if lsb_release -si | grep -E -i 'debian|ubuntu' > /dev/null; then
                # Install gnome plugin for debian/ubuntu distros
                #eval "sudo $installString gnome-software-plugin-flatpak"
            #fi            
        fi

        # flatpak | Download flatpak service files
        flatpakDownloadList=(
            "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/etc/systemd/system/flatpak-automatic.service"
            "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/etc/systemd/system/flatpak-automatic.timer"
        )
    
        for cloudFile in "${flatpakDownloadList[@]}"; do 
            fileName=$(basename "$cloudFile")
            localFilePath="/etc/systemd/system/${fileName}"
            backupDir="/etc/systemd/system/config_backups"
            backupCount=2
    
            # Check if local file and remote file have the same checksum
            if [[ -f "$localFilePath" && $(curl -s "$cloudFile" | md5sum | awk '{print $1}') == $(md5sum "$localFilePath" | awk '{print $1}') ]]; then
                echo "Skipping download of $fileName - Local file and remote file are the same."
            else
                # Create backup directory if it doesn't exist
                if [[ ! -d "$backupDir" ]]; then
                    sudo mkdir "$backupDir"
                fi
    
                # Backup existing file with date timestamp
                timestamp=$(date +%Y%m%d%H%M%S)
                backupFilePath="${backupDir}/${fileName}.${timestamp}"
                sudo cp "$localFilePath" "$backupFilePath"
    
                echo "Existing $fileName backed up to $backupFilePath"
    
                # Delete old backups, keeping only the most recent $backupCount
                backups=("$backupDir/${fileName}".*)
                backupCount=$((${#backups[@]} - $backupCount))
    
                if [[ $backupCount -gt 0 ]]; then
                    # Sort backups by modification time, oldest first
                    IFS=$'\n' sortedBackups=($(ls -t "${backups[@]}"))
                    unset IFS
    
                    # Remove oldest backups
                    for ((i = 0; i < backupCount; i++)); do
                        sudo rm "${sortedBackups[$i]}"
                        echo "Removed old backup: ${sortedBackups[$i]}"
                    done
                fi
                echo "Downloading $fileName..."
                sudo curl -o "$localFilePath" "$cloudFile"
            fi
        done
    
        # flatpak | Reload daemon before enabling new service
        sudo systemctl daemon-reload
    
        # flatpak | Copy + enable flatpak service/timer
        sudo systemctl enable --now flatpak-automatic.timer
    
        # flatpak | Enable flatpak home/host restrictions
        flatpak override --user --nofilesystem=home
        flatpak override --user --nofilesystem=host
    
        # Flathub setup
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

		flatpak remote-delete fedora
		flatpak remote-delete fedora-testing
    
        # Install flatpaks
        flatpak install -y --noninteractive flathub com.github.tchx84.Flatseal         
        flatpak install -y --noninteractive flathub org.mozilla.firefox
        
        if [ $? -eq 0 ]; then
            echo "Removing built in firefox in favour of flatpak"
            eval "sudo $removeString firefox"
        fi
        xdg-settings set default-web-browser org.mozilla.firefox.desktop

        # Loop over all flatpaks
        while IFS= read -r flatpak_app; do
            flatpak install -y --noninteractive flathub "$flatpak_app"
        done < <(wget -O - https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/flatpak_apps.txt)        
    fi
    echo "flatpak function done"
}

################
# Install apps #
################
ApplicationList=(
    "zsh"
    "tmux"
    "vim"
    "git"
    "curl"
    "unzip"
)

#########################
# Check Package Manager #
#########################

if rpm-ostree status &> /dev/null | grep silverblue &> /dev/null; then
    echo "Fedora Silverblue installed"
    # Set install string for remaineder of script    
    #installString="rpm-ostree install -y"
    #removeString="rpm-ostree remove -y"

elif command -v apt &> /dev/null; then
    echo "Debian-based distro"
    installString="apt-get install -y"
    removeString="apt-get remove -y"
    
    # Default to snap first with backup to apt
    if command -v snap &> /dev/null; then
        installString=""
        removeString=""
        for app in ${ApplicationList[@]}; do 
            # Get Ubuntu version
            ubuntu_version=$(lsb_release -rs)
            
            # Check if the version is 22.04
            if [ "$ubuntu_version" = "22.04" ]; then
                echo "Ubuntu 22.04 detected."
                # Remove lsd
                
                # Item to remove
                item_to_remove="lsd"
                
                # Loop through the array indices
                for i in "${!ApplicationList[@]}"; do
                    if [ "${ApplicationList[i]}" == "$item_to_remove" ]; then
                        unset my_array[i]  # Remove the item by unsetting its value
                    fi
                done
                # Display the modified array
                echo "Modified array: ${ApplicationList[@]}"
            fi
        
            echo "Checking $app"
            eval "which $app" &> /dev/null
            if [[ $? -ne 0 ]]; then
        	    echo "${app} not installed"
        	    eval "sudo snap install $app"
                if [[ $? -ne 0 ]]; then
                    eval "sudo apt-get install -y $app"
                fi
            else
        	    echo "${app} already installed - skipping"
            fi
        done
    fi
elif command -v pacman &> /dev/null; then
    echo "Arch-based distro"
    installString="pacman -Syu --noconfirm"cd
elif command -v dnf &> /dev/null; then
    echo "Fedora-based distro"
    installString="dnf install -y"
    removeString="dnf remove -y"
else
    echo "Unknown package manager"
    exit 1
fi

# Install flatpaks - checks if GUI
install_gui_apps

# Install CLI apps
# empty install string to skip this for Ubuntu
if [ ! -z "$installString" ]; then
    echo "installString is set: >>$installString<<"
    for app in ${ApplicationList[@]}; do 
        echo "Checking $app"
        eval "which $app" &> /dev/null
        if [[ $? -ne 0 ]]; then
    	    echo "${app} not installed"
    	    eval "sudo $installString $app"
        else
    	    echo "${app} already installed - skipping"
        fi
    done
else
    echo "installString empty: bypassed for custom install"
fi

eval "which zsh" &> /dev/null
if [[ $? -eq 0 ]]; then # Check zsh installed
    
    if [ -z "$ZSH" ]; then
        # Set ZSH var if running from bash
        echo "zsh running from bash - setting ZSH to ${user_home}/.oh-my-zsh"
        ZSH="${user_home}/.oh-my-zsh"
    fi

    ################
    # Change shell #
    ################
    # Define the username and desired shell
    desired_shell="zsh"
    # Get the correct path for the desired shell
    shell_path=$(which "$desired_shell")
    sudo usermod --shell $shell_path $username

    ###################
    # Install ohmyzsh #
    ###################
    if [ -d "$ZSH" ]; then
    	echo "$ZSH is a directory and exists"
	    # Check if ohmyzsh repo exists in home directory
	    ohmyzsh_remote_url=$(sudo -u $username git -C ~/.oh-my-zsh remote get-url origin)
	    official_remote_url="https://github.com/ohmyzsh/ohmyzsh.git"
	if [[ "$ohmyzsh_remote_url" == "$official_remote_url" ]]; then
	    echo "Oh My Zsh - already installed - updating"
        "$ZSH/tools/upgrade.sh"
	else 
	    echo "Removing existing ZSH folder: $ZSH"
	    rm -rf "$ZSH"
	fi
    else
        echo "Oh My Zsh - new install"
        sudo -u $username sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null
    fi

    #######################
    # Clone powerlevel10k #
    #######################
    TARGET_DIR="${ZSH_CUSTOM:-$user_home/.oh-my-zsh/custom}/themes/powerlevel10k"
    REPO="https://github.com/romkatv/powerlevel10k.git"
    BRANCH=$(git ls-remote --heads $REPO | grep -q 'refs/heads/main' && echo 'main' || (git ls-remote --heads $REPO | grep -q 'refs/heads/master' && echo 'master') || echo null)

    if [ -e "${TARGET_DIR}" ]
    then
        pushd $TARGET_DIR
        sudo -u $username git fetch
        exists=$(sudo -u $username git show-branch $BRANCH > /dev/null 2>&1; echo $?)
        if [ "$exists" == "0" ]
        then
            echo "$TARGET_DIR already up to date."
        else
            sudo -u $username git checkout -b $BRANCH origin/$BRANCH
        fi
        popd_if_stack_not_empty
    else
        sudo -u $username git clone $REPO $TARGET_DIR
    fi
    popd_if_stack_not_empty

    #################################
    # Clone zsh syntax highlighting #
    #################################
    TARGET_DIR="${ZSH_CUSTOM:-$user_home/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    BRANCH=$(sudo -u $username git ls-remote --heads $REPO | grep -q 'refs/heads/main' && echo 'main' || (sudo -u $username git ls-remote --heads $REPO | grep -q 'refs/heads/master' && echo 'master') || echo null)

    if [ -e "${TARGET_DIR}" ]
    then
        pushd $TARGET_DIR
        sudo -u $username git fetch
        exists=$(sudo -u $username git show-branch $BRANCH > /dev/null 2>&1; echo $?)
        if [ "$exists" == "0" ]
        then
            echo "$TARGET_DIR already up to date."
        else
            sudo -u $username git checkout -b $BRANCH origin/$BRANCH
        fi
        popd_if_stack_not_empty
    else
        sudo -u $username git clone $REPO $TARGET_DIR
    fi
    popd_if_stack_not_empty

    ###########################
    # Clone zsh auto complete #
    ###########################
    TARGET_DIR="${ZSH_CUSTOM:-$user_home/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    REPO="https://github.com/zsh-users/zsh-autosuggestions"
    BRANCH=$(sudo -u $username git ls-remote --heads $REPO | grep -q 'refs/heads/main' && echo 'main' || (sudo -u $username git ls-remote --heads $REPO | grep -q 'refs/heads/master' && echo 'master') || echo null)

    if [ -e "${TARGET_DIR}" ]
    then
        pushd $TARGET_DIR
        sudo -u $username git fetch
        exists=$(sudo -u $username git show-branch $BRANCH > /dev/null 2>&1; echo $?)
        if [ "$exists" == "0" ]
        then
            echo "$TARGET_DIR already up to date."
        else
            sudo -u $username git checkout -b $BRANCH origin/$BRANCH
        fi
        popd_if_stack_not_empty
    else
        sudo -u $username git clone $REPO $TARGET_DIR
    fi
    popd_if_stack_not_empty
fi

#################
# Download font #
#################
customFontName="Agave"
customFontFile="$customFontName.zip"
fontURL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.1/$customFontName.zip"
fontDir="${user_home}/.local/share/fonts/$customFontName"

if [[ ! -d $fontDir ]]; then
    sudo -u $username curl -L -O $fontURL
    sudo -u $username mkdir -p $fontDir
    sudo -u $username unzip $customFontFile -d $fontDir
    sudo -u $username rm $customFontFile
else
    echo "Font '$customFontName' already installed - skipping"
fi

#######################################
# Download config files from git repo #
#######################################
configDownloadList=(
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.zshrc"
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.p10k.zsh"
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.vimrc"
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.tmux.conf"
)

for cloudFile in "${configDownloadList[@]}"; do 
    fileName=$(basename "$cloudFile")
    localFilePath="${user_home}/${fileName}"
    backupDir="${user_home}/config_backups"
    backupCount=5

    # Check if local file and remote file have the same checksum
    if [[ -f "$localFilePath" && $(curl -s "$cloudFile" | md5sum | awk '{print $1}') == $(md5sum "$localFilePath" | awk '{print $1}') ]]; then
        echo "Skipping download of $fileName - Local file and remote file are the same."
    else
        # Create backup directory if it doesn't exist
        if [[ ! -d "$backupDir" ]]; then
            sudo -u $username mkdir "$backupDir"
        fi

        # Backup existing file with date timestamp
        timestamp=$(date +%Y%m%d%H%M%S)
        backupFilePath="${backupDir}/${fileName}.${timestamp}"
        sudo -u $username cp "$localFilePath" "$backupFilePath"

        echo "Existing $fileName backed up to $backupFilePath"

        # Delete old backups, keeping only the most recent $backupCount
        backups=("$backupDir/${fileName}".*)
        backupCount=$((${#backups[@]} - $backupCount))

        if [[ $backupCount -gt 0 ]]; then
            # Sort backups by modification time, oldest first
            IFS=$'\n' sortedBackups=($(ls -t "${backups[@]}"))
            unset IFS

            # Remove oldest backups
            for ((i = 0; i < backupCount; i++)); do
                sudo -u $username rm "${sortedBackups[$i]}"
                echo "Removed old backup: ${sortedBackups[$i]}"
            done
        fi
        echo "Downloading $fileName..."
        sudo -u $username curl -o "$localFilePath" "$cloudFile"
    fi
done
