# Exec will open a single terminal so the SSH session disconnects when detatching tmux
if [[ -z "$TMUX" ]] && [[ -n "$SSH_TTY" ]]; then
  exec tmux new-session -A -s $USER
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$PATH:/snap/bin/"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

unsetopt BEEP

# Sudo keep user environment
alias sudo="sudo -E"

# Run lsd if installed
if [ -x "$(command -v lsd)" ]; then
    alias ls="lsd"
    alias la="lsd -la --group-dirs first"
    alias lst="lsd -la --group-dirs first --tree --depth 2"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Distrobox run missing commands in host
if command -v distrobox-host-exec &> /dev/null; then
    command_not_found_handle() {
        # don't run if not in a container
        if [ ! -e /run/.containerenv ] && [ ! -e /.dockerenv ]; then
            exit 127
        fi
        distrobox-host-exec "${@}"
    }
    if [ -n "${ZSH_VERSION-}" ]; then
        command_not_found_handler() {
            command_not_found_handle "$@"
        }
    fi
fi

