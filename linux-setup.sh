#!/usr/bin/bash

# Super bad it, don't do this. I wrote this file, therefore I trust it.
# wget -O - https://thisfile.sh | bash

# Install apps
ApplicationList=(
    "zsh"
    "tmux"
    "vim"
    "git"
    "curl"
    "timewarrior"
    "taskwarrior"
)
echo "Updating repositories before installing apps"
sudo apt update
for app in ${ApplicationList[@]}; do 
    echo "Checking $app"
    dpkg -s "$app" &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo "${app} not installed"
        sudo apt install -y $app
    else
        echo "${app} already installed - skipping"
    fi
done

# Change shell
sudo chsh -s $(which zsh) $(whoami)

# Install ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Clone powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Backup config files in $HOME
configFileList=(
    ".zshrc"
    ".p10k.zsh"    
)
for configFile in ${configFileList[@]}; do 
    configFilePath="${HOME}/${configFile}"
    if [[ -f "${configFilePath}" ]]; then 
        echo "${configFilePath} exists - backing up"
        backupTimeStamp=`date +"%Y%m%d-%H%M%S"`
        newConfigFileName="${configFilePath}.${backupTimeStamp}.bak"
        mv configFilePath newConfigFileName
    else
        echo "${configFilePath} does not exist - skipping backup"
    fi
done

# Download config files from git repo
configDownloadList=(
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/.zshrc"
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/.p10k.zsh"
)
for cloudFile in ${configDownloadList[@]}; do 
    cd $HOME
    curl -O $cloudFile
done
