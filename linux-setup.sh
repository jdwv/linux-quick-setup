#!/usr/bin/bash

cd $HOME

# Super bad it, don't do this. I wrote this file, therefore I trust it.
# wget -O - https://thisfile.sh | bash

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

rpmOSTree=$(rpm-ostree -status | grep silverblue > /dev/null; echo $?)
if [[ rpmOSTree == 0 ]]; then
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
    dpkg -s "$app" &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo "${app} not installed"
        sudo $installString $app
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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null
if [[ $? == 1 ]]; then
    echo "Oh My Zsh - already installed - updating"
    "$ZSH/tools/upgrade.sh"
else
    echo "Oh My Zsh - new install"
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
    popd
else
    git clone $REPO $TARGET_DIR
fi
popd

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
    popd
else
    git clone $REPO $TARGET_DIR
fi
popd

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
    popd
else
    git clone $REPO $TARGET_DIR
fi
popd

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

################################
# Backup config files in $HOME #
################################
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
        echo "Removing the following files"
        /usr/bin/ls -t ${configFile}.*.bak | tail -n +3 
        # Find all backups of current config file
        #  - Keep only 2 that are older than 10 days
        /usr/bin/find $HOME/${configFile}.*.bak -type f -mtime +10  -printf '%T+ %p\n' | sort -r | awk '{print $NF}' | tail -n +3 | xargs rm --
    else
        echo "${configFilePath} does not exist - skipping backup"
    fi
done

#######################################
# Download config files from git repo #
#######################################
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
