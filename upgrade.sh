
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

# if [[ ! -d $bin_dir ]]; then
#     mkdir -p "$bin_dir" ||
#         error "Failed to create install directory \"$bin_dir\""
# fi

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
