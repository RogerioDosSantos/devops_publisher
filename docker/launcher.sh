#!/bin/bash

# Exit on any non-zero status.
trap 'exit' ERR
set -E

# Functions

Log()
{
  # Log <type> <level> <message> <detail>

  if [ "${config_log_enabled}" != "1" ]; then
    return 0
  fi

  local log_type=$1
  local log_level=$2
  local log_message=$3
  local log_detail=$4
  local log_date="$(date '+%Y-%m-%d %H:%M:%S')"
  local log_caller=${FUNCNAME[1]}
  echo "${log_date},${log_type},${log_level},${log_caller},${log_message},${log_detail}"
}

Init()
{
  # Setup - Go to the directory where the bash file is
  g_script_name="$(basename "$0")"
  g_caller_dir=$(pwd)
  cd "$(dirname "$0")"
  g_script_dir=$(pwd)
  cd "$(dirname "$0")"
}

End()
{
  # Setup - Return to the called directory
  cd "${g_caller_dir}"
}

ScriptDetail()
{
  Log "info" "5" "Script Name" "$(basename "$0")"
  Log "info" "5" "Caller Directory" "${g_caller_dir}"
  Log "info" "5" "Script Directory" "${g_script_dir}"
}

DisplayHelp()
{
  echo " "
  echo "Publisher Help"
  echo " "
  echo "publisher <command> [<command_options>]"
  echo " "
  echo "- Commands:"
  echo "help : Display this command help"
  echo " "
  echo "For command special help type:"
  echo "publisher <command> --help"
  echo " "
}

GetConfiguration()
{
  if [[ $# < 1  ]]; then
    DisplayHelp
    exit
  fi

  config_command_name=""
  config_command_options=""
  local command_name=$1
  shift 1
  case ${command_name} in
      help)
          DisplayHelp
          exit
          ;;
      command)
          config_command_name=${command_name}
          config_command_options=$@
          return 0
          ;;
      *)
          Log "error" "1" "Unknown Command" "${command_name}"
          echo "Unknown Command: ${command_name}"
          DisplayHelp
          exit
          ;;
  esac
}

MainFunction()
{
  config_log_enabled="1"
  local session_dir="${g_script_dir}/${RANDOM}_publisher_${RANDOM}"
  Log "info" "1" "Session Directory" "${session_dir}"


  Log "info" "1" "Calling Command" "${config_command_name} ${config_command_options}"
  case ${config_command_name} in
      command)
          ;;
  esac

}

Init
GetConfiguration "$@"
ScriptDetail
MainFunction
End

