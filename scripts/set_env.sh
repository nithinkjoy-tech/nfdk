#!/usr/bin/env bash

set -euo pipefail

# Reset
Color_Off=''

# Regular Colors
Red=''
Green=''
Dim='' # White

# Bold
Bold_White=''
Bold_Green=''

if [[ -t 1 ]]; then
    # Reset
    Color_Off='\033[0m' # Text Reset

    # Regular Colors
    Red='\033[0;31m'   # Red
    Green='\033[0;32m' # Green
    Dim='\033[0;2m'    # White

    # Bold
    Bold_Green='\033[1;32m' # Bold Green
    Bold_White='\033[1m'    # Bold White
fi

info() {
    echo -e "${Dim}$@ ${Color_Off}"
}

info_bold() {
    echo -e "${Bold_White}$@ ${Color_Off}"
}

tildify() {
    if [[ $1 = $HOME/* ]]; then
        local replacement=\~/

        echo "${1/$HOME\//$replacement}"
    else
        echo "$1"
    fi
}

case $(basename "$SHELL") in
fish)
    # Install completions, but we don't care if it fails
    # IS_NFDK_AUTO_UPDATE=true SHELL=fish $exe completions &>/dev/null || :
    set -e WEBHOOK_URL
    command="set --export $1 $2"

    fish_config=$HOME/.config/fish/config.fish
    tilde_fish_config=$(tildify "$fish_config")

    #TODO: Create a fish config file if not exist
    if [[ -w $fish_config ]]; then
        {
            unset WEBHOOK_URL
            echo $command
        } >>"$fish_config"

        # info "Added $1 to \$PATH in \"$tilde_fish_config\""

        refresh_command="source $tilde_fish_config"
    else
        echo "Manually add the directory to $tilde_fish_config (or similar):"

        info_bold "  $command"
    fi
    ;;
zsh)
    # Install completions, but we don't care if it fails
    # IS_NFDK_AUTO_UPDATE=true SHELL=zsh $exe completions &>/dev/null || :

    command="export $1=$2"
    unset WEBHOOK_URL
    zsh_config=$HOME/.zshrc
    tilde_zsh_config=$(tildify "$zsh_config")

    #TODO: Create a fish zshrc config file if not exist
    if [[ -w $zsh_config ]]; then
        {
            echo $command
        } >>"$zsh_config"

        # info "Added $1 to \$PATH in \"$tilde_zsh_config\""

        refresh_command="exec $SHELL"
    else
        echo "Manually add the directory to $tilde_zsh_config (or similar):"

        info_bold "  $command"
    fi
    ;;
bash)
    # Install completions, but we don't care if it fails
    # IS_NFDK_AUTO_UPDATE=true SHELL=bash $exe completions &>/dev/null || :

    command="export $1=$2"

    bash_configs=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
    )

    if [[ ${XDG_CONFIG_HOME:-} ]]; then
        bash_configs+=(
            "$XDG_CONFIG_HOME/.bash_profile"
            "$XDG_CONFIG_HOME/.bashrc"
            "$XDG_CONFIG_HOME/bash_profile"
            "$XDG_CONFIG_HOME/bashrc"
        )
    fi

    set_manually=true
    for bash_config in "${bash_configs[@]}"; do
        tilde_bash_config=$(tildify "$bash_config")
        unset WEBHOOK_URL

        #TODO: Create a bash config file if not exist
        if [[ -w $bash_config ]]; then
            {
                echo $command
            } >>"$bash_config"

            # info "Added $1 to \$PATH in \"$tilde_bash_config\""

            refresh_command="source $bash_config"
            set_manually=false
            break
        fi
    done

    if [[ $set_manually = true ]]; then
        echo "Manually add the directory to $tilde_bash_config (or similar):"

        info_bold "  $command"
    fi
    ;;
*)
    echo 'Manually add the directory to ~/.bashrc (or similar):'
    info_bold "  export $1=$2"
    ;;
esac