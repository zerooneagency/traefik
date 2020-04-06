#!/bin/sh
#
# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik-setup.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik-setup.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik-setup.sh
#   ./traefik-setup.sh
#

set -e

# utilities
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

function title {
  echo ""
  echo "${green}${1}${reset}"
  echo ""
}

function warn {
  echo "${yellow}[WARN] ${1}${reset}"
}

function setup {
  # Install Homebrew
  title "Installing Homebrew..."
  if [ ! -x "$(command -v brew)" ]
  then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  else
    echo "Homebrew already installed."
  fi

  # install Docker and other dependencies
  title "Installing Docker and other dependencies..."
  brew bundle --no-lock --file=- <<-EOS
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/core"
tap "homebrew/services"
brew "mkcert"
brew "nss"
brew "dnsmasq"
brew "yarn"
brew "awscli"
cask "docker"
EOS

  title "Installing Watch CLI..."
  if [ ! -x "$(command -v watch)" ]
  then
    yarn global add watch-cli
  else
    echo "Watch already installed."
  fi

  # get Traefik repo
  title "Installing Traefik..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik) $@"

  # setup DNS
  title "Setting up DNSMasq..."
  dnsmasq_restart_needed=""

  # Copy the default configuration file.
  dnsmasq_file="/usr/local/etc/dnsmasq.conf"
  if [ ! -f "$dnsmasq_file" ]
  then
    echo "Creating DNSMasq configuration file $dnsmasq_file..."
    cp $(brew list dnsmasq | grep /dnsmasq.conf.example$) $dnsmasq_file
    dnsmasq_restart_needed="true"
  fi

  # Add the "*.test" top level domain to your DNS
  dnsmasq_entry="address=/test/127.0.0.1"
  if ! grep -q "$dnsmasq_entry" $dnsmasq_file
  then
    echo "Adding the *.test top level domain to DNSMasq..."
    sudo echo "$dnsmasq_entry" >> $dnsmasq_file
    dnsmasq_restart_needed="true"
  fi

  # Copy the daemon configuration file into place.
  dnsmasq_plist_file="homebrew.mxcl.dnsmasq.plist"
  launch_deamons_dir="/Library/LaunchDaemons"
  if [ ! -f "$launch_deamons_dir/$dnsmasq_plist_file" ]
  then
    echo "Setting up auto-launch file homebrew.mxcl.dnsmasq.plist..."
    sudo cp $(brew list dnsmasq | grep /$dnsmasq_plist_file) $launch_deamons_dir/

    # Start Dnsmasq automatically.
    sudo launchctl load $launch_deamons_dir/$dnsmasq_plist_file
    dnsmasq_restart_needed="true"
  fi

  # Create resolver file
  resolver_file="/etc/resolver/test"
  if [ ! -f "$resolver_file" ]
  then
    echo "Creating 'test' resolver file at $resolver_file..."
    sudo mkdir -p "$(dirname $resolver_file)"
    sudo touch $resolver_file
    dnsmasq_restart_needed="true"
  fi

  # set local nameserver
  resolver_entry="nameserver 127.0.0.1"
  if ! grep -q "$resolver_entry" $resolver_file
  then
    sudo echo "$resolver_entry" >> $resolver_file
    dnsmasq_restart_needed="true"
  fi

  if [ "$dnsmasq_restart_needed" = "true" ]
  then
    echo "Restarting DNSMasq..."
    # start and stop DNS
    sudo launchctl stop homebrew.mxcl.dnsmasq
    sudo launchctl start homebrew.mxcl.dnsmasq

    echo "DNSMasq configured."
    echo ""
    warn "You now need to restart your computer and re-run this script to finish the setup."
  else
    echo "DNSMasq already configured"

    # get Traefik repo
    title "Installing Traefik..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik) $@"
  fi
}

setup $@