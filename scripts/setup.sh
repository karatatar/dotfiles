#!/bin/bash

command_exists() {
  type "$1" &> /dev/null ;
}

get_platform() {
  case "$(uname -s)" in
    Darwin)
      echo osx
      ;;
    *)
      if command_exists apt
      then
	echo apt
      fi
      ;;
  esac
}

read_dependencies() {
  echo "$(cat dependencies.txt)\n\n"
}

from_dependencies() {
  for key in "$@"
  do
    echo "$dependencies" | grep -Pzo "^$key:\n(.|\n)*?\n{2}" | tail -n +2 | sed '/^$/d'             	 
  done
}

setup_apt() {

  # Add commons 
  sudo apt-get install software-properties-common

  # Add third-party repositories
  for repository in $(from_dependencies "apt-repositories")
  do
    sudo add-apt-repository $repository -y
    sudo apt-get update -y
    sudo apt-get upgrade -y
  done

  # Install essential commands
  for package in $(from_dependencies "brew-apt" "apt")
  do 
    sudo apt-get install -y $package
  done

}

setup_mac() {

  # Install brew
  if ! command_exists brew ; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # Install essential commands
  for package in $(from_dependencies "brew-apt" "brew")
  do
    brew install $package
  done

}

#Prompt confirmation
echo "This  script is untested. Use it at your own risk!"
read -r -p "Do you want to continue? [Y/n] " response
response=${response,,} 
if [[ $response =~ ^(yes|y| ) ]] || [ -z $response ]; then
  echo "Proceeding with installation..."
else
  exit
fi

# Initial setup
mkdir -p ~/tmp
platform=$(get_platform)
dependencies=$(read_dependencies)
if [[ -z "$system" ]]; then
  echo "Unable to find compatible install commands for your platform"
fi
echo "Detected platform: $platform"

# Invoke platform-specific setup
case $platform in
  osx) setup_mac;;
  apt) setup_apt;;
esac

# Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install tpm
git clone https://github.com/tmux-plugins/tpm --depth=1 ~/.tmux/plugins/tpm

# Instal tmuxinator
gem install tmuxinator

# Setup dot files
git https://github.com/denisidoro/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install

# Cleanup
rm -rf ~/tmp
cd ~
