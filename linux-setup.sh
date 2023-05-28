#!/usr/bin/bash

# Super bad it, don't do this. I wrote this file, therefore I trust it.
# wget -O - https://thisfile.sh | bash

# Install apps
ApplicationList=(
    "zsh"
    "exa"
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
if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "ohmyzsh already installed - skipping"
fi

# Clone powerlevel10k
if [[ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo "powerlevel10k already installed - skipping"
fi

# Clone zsh syntax highlighting
if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
    echo "zsh syntax highlighting already installed - skipping"
fi

# Clone zsh auto complete
if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
    echo "zsh autocomplete already installed - skipping"
fi

# Backup config files in $HOME
configFileList=(
    ".zshrc"
    ".p10k.zsh" 
    ".vimrc"
    ".tmux.conf"
)
for configFile in ${configFileList[@]}; do 
    configFilePath="${HOME}/${configFile}"
    if [[ -f "${configFilePath}" ]]; then 
        echo "${configFilePath} exists - backing up"
        backupTimeStamp=`date +"%Y%m%d-%H%M%S"`
        newConfigFileName="${configFilePath}.${backupTimeStamp}.bak"
        mv $configFilePath $newConfigFileName
    else
        echo "${configFilePath} does not exist - skipping backup"
    fi
done

# Download config files from git repo
configDownloadList=(
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.zshrc"
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.p10k.zsh"
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.vimrc"
    "https://raw.githubusercontent.com/jdwv/linux-quick-setup/main/config/.tmux.conf"
)
for cloudFile in ${configDownloadList[@]}; do 
    cd $HOME
    curl -O $cloudFile
done
