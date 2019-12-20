#!/bin/bash

function get_input() {
# prompts message and get user input
# in: params: prompt [default_value]
#     env:
# out: stdout: user_input
#      status: 

  local input="" 
  local prompt=$1
  local value=$2

  read -p "$prompt" -ei "$value" input
  echo ${input:-$value} 
}

function main() {
# in: params: 
#     env: 
# out: stdout: 
#      status: 0 when OK, else 1

  local base_dir="" 
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
   then
    base_dir=$(dirname $0)
   else
    base_dir="$(dirname ${BASH_SOURCE[0]})"
  fi

  local user=${BATS_USER:-$(whoami)}	# BATS_USER: for test manupilation
  [ $user == "root" ] || { echo "must run as 'root'"; exit 1; }

  # restore terminal state after ctrl-c on get_input
  local original_tty_state=$(stty -g)
  trap "{ stty $original_tty_state; exit 0 }"  INT
 
  local install_dir=$(get_input "Executables directory: " "/usr/local/bin")
  if [ ! -e $install_dir ] 
   then
    mkdir -p $install_dir || { echo "directory \"$install_dir\" does not exist"; exit 1; }
  fi
  
  local config_dir=$(get_input "Configurations directory: " "/etc/dbl")
  if [ ! -e $config_dir ]
   then
    mkdir $config_dir || { echo "Cannot create \"$config_dir\""; exit 1; }
  fi

  cp $base_dir/bin/* $install_dir || exit 1
  cp -r $base_dir/cfg/dbl.cfg $base_dir/cfg/get_ip.awk $base_dir/cfg/whitelist $base_dir/cfg/dbl.d  $config_dir || exit 1

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  main
fi
