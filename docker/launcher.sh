#!/bin/bash

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
}

End()
{
  Log "info" "5" "Returning to caller directory" "${g_caller_dir}"
  cd "${g_caller_dir}"
}

ErrorHandler()
{
  # Usage: ErrorHandler <last_line>
  local last_line=$1
  Log "error" "1" "Last line executed" "${last_line}"
  End
  exit 1
}

ScriptDetail()
{
  Log "info" "5" "Script Name" "${g_script_name}"
  Log "info" "5" "Caller Directory" "${g_caller_dir}"
  Log "info" "5" "Script Directory" "${g_script_dir}"
}

DisplayHelp()
{
  echo "publisher <command> [<command_options>]"
  echo " "
  echo "- Commands:"
  echo "help : Display this command help"
  echo "bash : Run the bash inside the machine"
  echo "create_metadata : Create publishing metadata information"
  echo " "
  echo "For command special help type:"
  echo "publisher <command> --help"
}

RunCommand()
{
  # Usage: RunCommand <command_name> <parameters>

  if [[ $# == 0 ]]; then
    Log "error" "1" "Command not informed" ""
    DisplayHelp
    return 0
  fi

  local command_name=$1
  shift 1

  if [ "${command_name}" = "help" ]; then
    DisplayHelp
    return 0
  fi

  if [ "${command_name}" = "bash" ]; then
    cd ${g_caller_dir}
    bash "$@"
    return 0
  fi

  local command_file_path="${g_script_dir}/../src/scripts/${command_name}.sh"
  # command_file_path=$(realpath ${command_file_path})
  Log "info" "1" "Command File" "${command_file_path}"
  if [ -f "${command_file_path}"  ]; then
    cd ${g_caller_dir}
    ${command_file_path} "$@"
  else
    Log "error" "1" "Invalid Command" "${command_name}"
    echo "Invalid command: ${command_name}"
    DisplayHelp
    return 0
  fi
}

# Main

set -E
trap 'ErrorHandler $LINENO' ERR

config_log_enabled="0"
Init
ScriptDetail
RunCommand "$@"
End 0

