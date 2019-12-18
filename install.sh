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
#     env: [$INSTALL_DIR]
# out: stdout: 
#      status: 0 when OK, else 1

  local base_dir=$(dirname $0)

  local user=$(whoami)
  [ $user == "root" ] || (echo "must run as 'root'"; exit 1)
 
  local install_dir=$(get_input "Executables directory: " "/usr/local/bin}")
  [ -e $install_dir ] || ( echo "directory \"$install_dir\" does not exist"; exit 1)
  
  local config_dir=$(get_input "Configurations directory: " "/etc/dbl")
  if [ ! -e $config_dir ]
   then
    mkdir $config_dir || (echo "Cannot create \"$config_dir\""; exit 1)
  fi

  echo cp $base_dir/blacklist_* $install_dir
  echo cp -r $base_dir/etc/* $config_dir

  return 0

}
main
