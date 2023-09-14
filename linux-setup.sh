#!/usr/bin/bash

cd $HOME

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

################
# Install apps #
################
ApplicationList=(
    "zsh"
    "lsd"
    "tmux"
    "vim"
    "git"
    "curl"
    "unzip"
)

echo "Updating repositories before installing apps"
#sudo apt update

#########################
# Check Package Manager #
#########################

if rpm-ostree status | grep silverblue &> /dev/null; then
    echo "Fedora Silverblue installed"

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

    # rpm-ostreee | set staging config
    sudo sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf

    # rpm-ostree | Enable staging for rpm-ostree + timer service
    sudo systemctl enable rpm-ostreed-automatic.timer --now

    # Set install string for remaineder of script    
    installString="rpm-ostree install -y"

    # Add apps to list to install
    sudo rpm-ostree install -y gnome-tweaks

    # Flathub setup
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Install flatpaks
    flatpak install -y --noninteractive flathub com.github.tchx84.Flatseal         
    flatpak install -y --noninteractive org.mozilla.firefox      
    xdg-settings set default-web-browser org.mozilla.firefox.desktop

elif command -v apt &> /dev/null; then
    echo "Debian-based distro"
    installString="apt-get install -y"
elif command -v yum &> /dev/null; then
    echo "Red Hat-based distro"
    installString="yum install -y"
elif command -v pacman &> /dev/null; then
    echo "Arch-based distro"
    installString="pacman -Syu --noconfirm"
elif command -v dnf &> /dev/null; then
    echo "Fedora-based distro"
    installString="dnf install -y"
else
    echo "Unknown package manager"
    exit 1
fi

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

eval "which zsh" &> /dev/null
if [[ $? -eq 0 ]]; then # Check zsh installed
    if [ -z "$ZSH" ]; then
        # Set ZSH var if running from bash
        ZSH="$HOME/.oh-my-zsh"
    fi

    ################
    # Change shell #
    ################
    # Define the username and desired shell
    username=$(whoami)
    desired_shell="zsh"
    # Get the correct path for the desired shell
    shell_path=$(which "$desired_shell")
    sudo usermod --shell $shell_path $username

    ###################
    # Install ohmyzsh #
    ###################

    # Check if ohmyzsh repo exists in home directory
    ohmyzsh_remote_url=$(git -C ~/.oh-my-zsh remote get-url origin)
    official_remote_url="https://github.com/ohmyzsh/ohmyzsh.git"

    if [[ "$ohmyzsh_remote_url" == "$official_remote_url" ]]; then
        echo "Oh My Zsh - already installed - updating"
        "$ZSH/tools/upgrade.sh"
    else
        echo "Oh My Zsh - new install"
        if [ -d "$ZSH" ]; then
            echo "Removing existing ZSH folder: $ZSH"
            rm -rf "$ZSH"
        fi
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null
    fi

    #######################
    # Clone powerlevel10k #
    #######################
    TARGET_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    REPO="https://github.com/romkatv/powerlevel10k.git"
    BRANCH=$(git ls-remote --heads $REPO | grep -q 'refs/heads/main' && echo 'main' || (git ls-remote --heads $REPO | grep -q 'refs/heads/master' && echo 'master') || echo null)

    if [ -e "${TARGET_DIR}" ]
    then
        pushd $TARGET_DIR
        git fetch
        exists=$(git show-branch $BRANCH > /dev/null 2>&1; echo $?)
        if [ "$exists" == "0" ]
        then
            echo "$TARGET_DIR already up to date."
        else
            git checkout -b $BRANCH origin/$BRANCH
        fi
        popd_if_stack_not_empty
    else
        git clone $REPO $TARGET_DIR
    fi
    popd_if_stack_not_empty

    #################################
    # Clone zsh syntax highlighting #
    #################################
    TARGET_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    BRANCH=$(git ls-remote --heads $REPO | grep -q 'refs/heads/main' && echo 'main' || (git ls-remote --heads $REPO | grep -q 'refs/heads/master' && echo 'master') || echo null)

    if [ -e "${TARGET_DIR}" ]
    then
        pushd $TARGET_DIR
        git fetch
        exists=$(git show-branch $BRANCH > /dev/null 2>&1; echo $?)
        if [ "$exists" == "0" ]
        then
            echo "$TARGET_DIR already up to date."
        else
            git checkout -b $BRANCH origin/$BRANCH
        fi
        popd_if_stack_not_empty
    else
        git clone $REPO $TARGET_DIR
    fi
    popd_if_stack_not_empty

    ###########################
    # Clone zsh auto complete #
    ###########################
    TARGET_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    REPO="https://github.com/zsh-users/zsh-autosuggestions"
    BRANCH=$(git ls-remote --heads $REPO | grep -q 'refs/heads/main' && echo 'main' || (git ls-remote --heads $REPO | grep -q 'refs/heads/master' && echo 'master') || echo null)

    if [ -e "${TARGET_DIR}" ]
    then
        pushd $TARGET_DIR
        git fetch
        exists=$(git show-branch $BRANCH > /dev/null 2>&1; echo $?)
        if [ "$exists" == "0" ]
        then
            echo "$TARGET_DIR already up to date."
        else
            git checkout -b $BRANCH origin/$BRANCH
        fi
        popd_if_stack_not_empty
    else
        git clone $REPO $TARGET_DIR
    fi
    popd_if_stack_not_empty
fi

#################
# Download font #
#################
customFontName="Agave"
customFontFile="$customFontName.zip"
fontURL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.1/$customFontName.zip"
fontDir="${HOME}/.local/share/fonts/$customFontName"

if [[ ! -d $fontDir ]]; then
    curl -L -O $fontURL
    mkdir -p $fontDir
    unzip $customFontFile -d $fontDir
    rm $customFontFile
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
    localFilePath="${HOME}/${fileName}"
    backupDir="${HOME}/config_backups"
    backupCount=5

    # Check if local file and remote file have the same checksum
    if [[ -f "$localFilePath" && $(curl -s "$cloudFile" | md5sum | awk '{print $1}') == $(md5sum "$localFilePath" | awk '{print $1}') ]]; then
        echo "Skipping download of $fileName - Local file and remote file are the same."
    else
        # Create backup directory if it doesn't exist
        if [[ ! -d "$backupDir" ]]; then
            mkdir "$backupDir"
        fi

        # Backup existing file with date timestamp
        timestamp=$(date +%Y%m%d%H%M%S)
        backupFilePath="${backupDir}/${fileName}.${timestamp}"
        cp "$localFilePath" "$backupFilePath"

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
                rm "${sortedBackups[$i]}"
                echo "Removed old backup: ${sortedBackups[$i]}"
            done
        fi
        echo "Downloading $fileName..."
        curl -o "$localFilePath" "$cloudFile"
    fi
done

