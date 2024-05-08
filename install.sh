
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

error() {
    echo -e "${Red}error${Color_Off}:" "$@" >&2
    exit 1
}

info() {
    echo -e "${Dim}$@ ${Color_Off}"
}

info_bold() {
    echo -e "${Bold_White}$@ ${Color_Off}"
}

success() {
    echo -e "${Green}$@ ${Color_Off}"
}

if [[ $# -gt 0 ]]; then
    error 'No arguments allowed'
fi

case $(uname -ms) in
'Darwin x86_64')
    target=darwin-x64
    ;;
'Darwin arm64')
    target=darwin-aarch64
    ;;
esac

if [[ $target = darwin-x64 ]]; then
    # Is this process running in Rosetta?
    # redirect stderr to devnull to avoid error message when not running in Rosetta
    if [[ $(sysctl -n sysctl.proc_translated 2>/dev/null) = 1 ]]; then
        target=darwin-aarch64
        info "Your shell is running in Rosetta 2. Downloading nfdk for $target instead"
    fi
fi

GITHUB=${GITHUB-"https://github.com"}

github_repo="$GITHUB/nithinkjoy-tech/nfdk"
exe_name=nfdk

nfdk_uri=$github_repo/releases/latest/download/nfdk.zip

install_env=NFDK_INSTALL
bin_env=\$$install_env/bin

install_dir=${!install_env:-$HOME/.nfdk}
bin_dir=$install_dir/bin
exe=$bin_dir/nfdk

if [[ ! -d $bin_dir ]]; then
    mkdir -p "$bin_dir" ||
        error "Failed to create install directory \"$bin_dir\""
fi

env_github_url="https://raw.githubusercontent.com/nithinkjoy-tech/nfdk/main/scripts/set_env.sh"
env_download_path="$bin_dir/set_env.sh"
touch "$env_download_path"
curl -o "$env_download_path" "$env_github_url"
chmod +x "$env_download_path" ||
    error "Failed to make \"$env_download_path\" executable"

depl_fail_github_url="https://raw.githubusercontent.com/nithinkjoy-tech/nfdk/main/scripts/deployment_fail.sh"
depl_fail_download_path="$bin_dir/deployment_fail.sh"
touch "$depl_fail_download_path"
curl -o "$depl_fail_download_path" "$depl_fail_github_url"
chmod +x "$depl_fail_download_path" ||
    error "Failed to make \"$depl_fail_download_path\" executable"

upgrade_github_url="https://raw.githubusercontent.com/nithinkjoy-tech/nfdk/main/upgrade.sh"
upgrade_download_path="$bin_dir/upgrade.sh"
touch "$upgrade_download_path"
curl -o "$upgrade_download_path" "$upgrade_github_url"
chmod +x "$upgrade_download_path" ||
    error "Failed to make \"$upgrade_download_path\" executable"

curl --fail --location --progress-bar --output "$exe.zip" "$nfdk_uri" ||
    error "Failed to download nfdk from \"$nfdk_uri\""

unzip -oqd "$bin_dir" "$exe.zip" ||
    error 'Failed to extract nfdk'

# mv "$bin_dir/$exe_name" "$exe" ||
#     error 'Failed to move extracted nfdk to destination'

chmod +x "$exe" ||
    error 'Failed to set permissions on nfdk executable'

rm -r "$exe.zip"

tildify() {
    if [[ $1 = $HOME/* ]]; then
        local replacement=\~/

        echo "${1/$HOME\//$replacement}"
    else
        echo "$1"
    fi
}

success "nfdk was installed successfully to $Bold_Green$(tildify "$exe")"

if command -v nfdk >/dev/null; then
    # Install completions, but we don't care if it fails
    IS_NFDK_AUTO_UPDATE=true $exe completions &>/dev/null || :

    echo "Run 'nfdk --help' to get started"
    exit
fi

refresh_command=''

tilde_bin_dir=$(tildify "$bin_dir")
quoted_install_dir=\"${install_dir//\"/\\\"}\"

if [[ $quoted_install_dir = \"$HOME/* ]]; then
    quoted_install_dir=${quoted_install_dir/$HOME\//\$HOME/}
fi

echo

case $(basename "$SHELL") in
fish)
    # Install completions, but we don't care if it fails
    IS_NFDK_AUTO_UPDATE=true SHELL=fish $exe completions &>/dev/null || :

    commands=(
        "set --export $install_env $quoted_install_dir"
        "set --export PATH $bin_env \$PATH"
    )

    fish_config=$HOME/.config/fish/config.fish
    tilde_fish_config=$(tildify "$fish_config")

    #TODO: Create a fish config file if not exist
    if [[ -w $fish_config ]]; then
        {
            echo -e '\n# nfdk'

            for command in "${commands[@]}"; do
                echo "$command"
            done
        } >>"$fish_config"

        info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_fish_config\""

        refresh_command="source $tilde_fish_config"
    else
        echo "Manually add the directory to $tilde_fish_config (or similar):"

        for command in "${commands[@]}"; do
            info_bold "  $command"
        done
    fi
    ;;
zsh)
    # Install completions, but we don't care if it fails
    IS_NFDK_AUTO_UPDATE=true SHELL=zsh $exe completions &>/dev/null || :

    commands=(
        "export $install_env=$quoted_install_dir"
        "export PATH=\"$bin_env:\$PATH\""
    )

    zsh_config=$HOME/.zshrc
    tilde_zsh_config=$(tildify "$zsh_config")

    #TODO: Create a fish zshrc config file if not exist
    if [[ -w $zsh_config ]]; then
        {
            echo -e '\n# nfdk'

            for command in "${commands[@]}"; do
                echo "$command"
            done
        } >>"$zsh_config"

        info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_zsh_config\""

        refresh_command="exec $SHELL"
    else
        echo "Manually add the directory to $tilde_zsh_config (or similar):"

        for command in "${commands[@]}"; do
            info_bold "  $command"
        done
    fi
    ;;
bash)
    # Install completions, but we don't care if it fails
    IS_NFDK_AUTO_UPDATE=true SHELL=bash $exe completions &>/dev/null || :

    commands=(
        "export $install_env=$quoted_install_dir"
        "export PATH=$bin_env:\$PATH"
    )

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

        #TODO: Create a bash config file if not exist
        if [[ -w $bash_config ]]; then
            {
                echo -e '\n# nfdk'

                for command in "${commands[@]}"; do
                    echo "$command"
                done
            } >>"$bash_config"

            info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_bash_config\""

            refresh_command="source $bash_config"
            set_manually=false
            break
        fi
    done

    if [[ $set_manually = true ]]; then
        echo "Manually add the directory to $tilde_bash_config (or similar):"

        for command in "${commands[@]}"; do
            info_bold "  $command"
        done
    fi
    ;;
*)
    echo 'Manually add the directory to ~/.bashrc (or similar):'
    info_bold "  export $install_env=$quoted_install_dir"
    info_bold "  export PATH=\"$bin_env:\$PATH\""
    ;;
esac
