#!/bin/bash

#colors
RED='\033[0;31m'
NC='\033[0m' #no color
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

#symbols
CHECK_SYMBOL="\033[0;32m\xE2\x9C\x94\033[0m"
WRENCH_SYMBOL="\xE2\x9C\xA8"

#utils
function get_timestamp {
    date +"%l:%M:%S:%3N%p"
}

#postgre
postgres_home=C:/dev-environment/pgsql
postgres_port=5432
postgres_command="./pg_ctl -D $postgres_home/data -l logging_postgresql.log start"

#servers map
declare -A server_map
server_map["postgres-db"]="$postgres_port|$postgres_home/bin|$postgres_command"

is_port_in_use() {
  local server_port=$1
  
  netstat -an | grep LISTEN | grep -q ":$server_port "
  return $?
}

validate_port_and_execute() {
  local port_in_use=$1
  local server_path=$2
  local execution_command=$3
  local server_port=$4

  if [ "$port_in_use" == "1" ]; then
    cd "$server_path" || exit
    eval start "$execution_command"
  else
    echo "$(get_timestamp) .................... port $server_port is currently in use" >> "output.log"
  fi
}

execute_server() {
  local server_name=$1

  IFS='|' read -r server_port server_path execution_command <<< "${server_map[$server_name]}"

  is_port_in_use "$server_port"
  port_in_use=$?

  echo "$(get_timestamp) .......... $server_name .......... $execution_command" >> "output.log"

  validate_port_and_execute "$port_in_use" "$server_path" "$execution_command" "$server_port"
}

list_servers() {
  echo -e "\n########## ${CYAN} Servidores disponibles ${NC}##########\n"
  local index=1
  for server in "${!server_map[@]}"; do
    echo "$index) $server"
    index=$((index + 1))
  done
}

select_server() {
  list_servers
  read -rp "Ingrese un número de servidor: " selection

  if [[ "$selection" =~ ^[0-9]+$ ]]; then
    local server_names=("${!server_map[@]}")
    if ((selection >= 1 && selection <= ${#server_names[@]})); then
      execute_server "${server_names[selection - 1]}"
    else
      echo -e "${RED}No se encontró ningún servidor.${NC}"
    fi
  else
    echo -e "${RED}Opción inválida.${NC}"
  fi
}

select_server
