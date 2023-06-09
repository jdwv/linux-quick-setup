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
    "exa"
    "tmux"
    "vim"
    "git"
    "curl"
    "distrobox"
)
echo "Updating repositories before installing apps"
#sudo apt update

#########################
# Check Package Manager #
#########################

rpmOSTree=$(rpm-ostree status | grep silverblue > /dev/null; echo $?)
if [[ rpmOSTree -eq 0 ]]; then
    echo "Fedora Silverblue installed"
    installString="rpm-ostree install -y"
elif command -v apt &> /dev/null; then
    echo "Debian-based distro"
    installString="apt install -y"
elif command -v yum &> /dev/null; then
    echo "Red Hat-based distro"
elif command -v pacman &> /dev/null; then
    echo "Arch-based distro"
elif command -v dnf &> /dev/null; then
    echo "Fedora-based distroo"
    installString="dnf install -y"
else
    echo "Unknown package manager"
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

################
# Change shell #
################
sudo chsh -s $(which zsh) $(whoami)

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
    #git reset --hard origin/$BRANCH
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
    #git reset --hard origin/$BRANCH
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
    #git reset --hard origin/$BRANCH
    popd_if_stack_not_empty
else
    git clone $REPO $TARGET_DIR
fi
popd_if_stack_not_empty

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

