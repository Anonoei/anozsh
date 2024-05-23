#!/bin/zsh

#set -eu

echo '    ___               _____ __  __'
echo '   /   |  ____  ____ / ___// / / /'
echo '  / /| | / __ \/ __ \\__ \/ /_/ / '
echo ' / ___ |/ / / / /_/ /__/ / __  /  '
echo '/_/  |_/_/ /_/\____/____/_/ /_/   '
ASH_INSTALLING=1
ASH_SRC="https://raw.githubusercontent.com/Anonoei/anosh/main/"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "$0"
    echo " -h|--help     : show this message"
    echo " -r|--reset    : delete anosh/anozsh"
    echo " -p|--plugins  : delete anosh/plugins"
    echo " -c|--common   : delete anosh/common"
    echo " -u|--user     : delete user settings"
    echo " -l|--local    : install from specified path"
    exit
fi

ash_copy() {
    if [[ $ASH_SRC == /* ]]; then
        cp "$1" "$2"
    else
        curl -L -o "$2" "$1"
    fi
}

if [[ "$1" == "-r" || "$1" == "--reset" ]]; then
    rm -rf "${HOME}/.local/anosh/anozsh"
    shift
fi

if [[ "$1" == "-p" || "$1" == "--plugins" ]]; then
    rm -rf "${HOME}/.local/anosh/plugins"
    shift
fi

if [[ "$1" == "-c" || "$1" == "--common" ]]; then
    rm -rf "${HOME}/.local/anosh/common"
    shift
fi

if [[ "$1" == "-u" || "$1" == "--user" ]]; then
    if [ -f "${HOME}/.local/anosh/anozsh/ash_settings.zsh" ]; then
        rm "${HOME}/.local/anosh/anozsh/ash_settings.zsh"
    fi
    if [ -f "${HOME}/.local/anosh/starship.toml" ]; then
        rm  "${HOME}/.local/anosh/starship.toml"
    fi
    shift
fi

if [[ "$1" == "-l" || "$1" == "--local" ]]; then
    ASH_SRC="$2"
    if [[ "$ASH_SRC" == "." ]]; then
        ASH_SRC="$PWD"
    fi
    foldername=${ASH_SRC##*/}
    foldername=${foldername:-/}
    if [[ ! $foldername == "anosh" ]]; then
        echo "Please install from anozsh source, not $foldername"
        exit
    fi
    if [ ! -d "$ASH_SRC" ]; then
        echo "Unable to install from local directory $ASH_SRC"
        exit
    fi
fi

install_package() {
    echo "Installing $1..."
    if  [ -x "$(command -v nala)" ];     then sudo nala install $1
    elif [ -x "$(command -v apt-get)" ]; then sudo apt install $1
    elif [ -x "$(command -v apk)" ];     then sudo apk add --no-cache $1
    elif [ -x "$(command -v dnf)" ];     then sudo dnf install $1
    elif [ -x "$(command -v pacman)" ];  then sudo pacman -Syu $1
    elif [ -x "$(command -v zypper)" ];  then sudo zypper install $1
    elif [ -x "$(command -v brew)" ];    then brew install $1
    else echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $packagesNeeded">&2; fi
}

verify_zsh_installed() {
    local output=$(zsh --version)
    local installed=0
    while IFS= read -r line; do
        if [[ $line == *"zsh "* ]]; then
            installed=1
        fi
    done <<< "$output"

    if [[ $installed == 0 ]]; then
        echo "ZSH is not installed. Installing ZSH..."
        packagesNeeded='zsh'
        install_package "zsh"
    fi
}

verify_zsh_default() {
    if [[ ! $SHELL == *"/bin/zsh"* ]]; then
        echo "ZSH is not the default shell. Setting ZSH to default..."
        chsh -s $(which zsh)
    fi
}

cd "${HOME}"
echo "Installing from $ASH_SRC"

verify_zsh_installed
verify_zsh_default

echo "Installing dependencies"
for pkg in "bat" "tree" "multitail" "fastfetch" "fzf"; do
    install_package $pkg
done

echo "Downloading AnoSH ZSH .zshrc file"
ash_copy "$ASH_SRC/anozsh/.zshrc" "${HOME}/.zshrc"
mv "${HOME}/.zshrc" "${HOME}/.zshrc_tmp"

sed "s|ASH_SRC=.*|ASH_SRC=\"$ASH_SRC\"|g" "${HOME}/.zshrc_tmp" > "${HOME}/.zshrc"
rm "${HOME}/.zshrc_tmp"

if [ ! -d "$HOME/.local/anosh/anozsh" ]; then
    echo 'Creating ~/.local/anosh/anozsh'
    mkdir -p "${HOME}/.local/anosh/anozsh"
else
    echo "Cleaning ~/.local/anosh/anozsh"
    find "${HOME}/.local/anosh/anozsh" -type f -name "ash*.zsh" -not -name 'ash_settings.zsh' -print0 | xargs -0 rm --
fi

echo "Installed! Running AnoSH ZSH"
for _ in "" "" "" "" "" ""; do
    sleep .5
    echo -n "."
done
echo ""
exec zsh
