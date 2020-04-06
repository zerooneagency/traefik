#!/bin/sh
#
# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/zerooneagency/traefik/master/bin/traefik.sh
#   ./traefik.sh
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

function setup_traefik {
  traefik_path="${CODE_DIR:-$HOME}/.traefik"
  domains_file_path=$traefik_path/.domains

  # clone repository
  if [ ! -d $traefik_path ]
  then
    title "Cloning Traefik repository to $traefik_path"
    mkdir -p $traefik_path
    git clone https://github.com/zerooneagency/traefik.git $traefik_path
  fi

  # Add new domains to file
  touch $domains_file_path
  generate_cert=""
  for domain in "$@"
  do
    title "Setting up domains..."
    if ! grep -Fxq "$domain" $domains_file_path
    then
      echo "Adding $domain domain"
      echo "$domain" >> $domains_file_path
      generate_cert="true"
    fi
  done

  # generate certificates
  if [[ ! -z "$generate_cert" ]] || [[ ! -f $traefik_path/certs/localhost.pem ]]; then
    title "Generating SSL certificate..."
    hosts="localhost 127.0.0.1 ::1"

    while IFS= read -r host;
    do
      if [[ ! -z "$host" ]]; then
        hosts="$hosts $host *.$host"
      fi
    done < $domains_file_path

    mkcert -cert-file $traefik_path/certs/localhost.pem -key-file $traefik_path/certs/localhost-key.pem $hosts

    # install root certificate
    title "Installing root certificate..."
    mkcert -install

    # restart docker
    title "Restarting Traefik..."
    docker-compose -f $traefik_path/docker-compose.yml down
  fi

  # start docker
  docker-compose -f $traefik_path/docker-compose.yml up -d
}

setup_traefik $@
