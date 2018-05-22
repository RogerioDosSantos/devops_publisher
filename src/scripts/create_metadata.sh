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
  cd "$(dirname "$0")"
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
  echo "${g_script_name/.sh/} --<command> [<command_options>]"
  echo " "
  echo "- Commands:"
  echo "--help (h) : Display this command help"
  echo "--log_enable (-le) : Enable log"
  echo "--log_level (-ll) <level>: Define the Log Level (Default: ${config_log_level})"
  echo "--log_type (-lt) <type>: Define the Log Type [Options: all, error, warning, info] (Default: ${config_log_type})"
  echo "--location (-lc) <location_of_metadata>: Define the location from where the metadata will be generated from. (Default: ${config_location})"
  echo "--output (-o) <file_path>: File that the result will be saved. (Default: Does not save)"
  echo " "
}

GetConfiguration()
{
  config_log_enabled="0"
  config_log_level="1"
  config_log_type="all"
  config_location="${g_caller_dir}"
  config_output_file_path=""
  while [[ $# != 0 ]]; do
      case $1 in
          --log_enable|-le)
            config_log_enabled="1"
            Log "info" "1" "Log Enabled" ""
            shift 1
            ;;
          --log_level|-le)
            config_log_level="$2"
            Log "info" "1" "Log Level" "${config_log_level}"
            shift 2
            ;;
          --log_type|-lt)
            config_log_type="$2"
            Log "info" "1" "Log Type" "${config_log_type}"
            shift 2
            ;;
          --location|-lc)
            config_location="$2"
            Log "info" "1" "Location" "${config_location}"
            shift 2
            ;;
          --output|-o)
            config_output_file_path="$2"
            Log "info" "1" "Output" "${config_output_file_path}"
            shift 2
            ;;
          --)
              shift
              break
              ;;
          --help|-h)
              DisplayHelp
              exit
              ;;
          -*)
              Log "error" "1" "Unknown option" "$1"
              DisplayHelp
              exit
              ;;
          *)
              break
              ;;
      esac
  done
}

MainFunction()
{
  Log "info" "1" "Creating the id" ""

  cd "${g_caller_dir}"
  cd "${config_location}"
  config_location="$(pwd)"

  local module_dir="$(git rev-parse --show-toplevel)"
  local name="${module_dir##*/}"
  local version="$(git rev-parse --short HEAD)"
  local commit="$(git rev-parse HEAD)"
  local branch="$(git rev-parse --abbrev-ref HEAD)"
  local timestamp="$(git log -1 --date=iso --pretty=format:%cd)"
  local location="${config_location/${module_dir}/}"

  cd "${module_dir}/.."
  module_dir="$(pwd)"
  echo "$module_dir"

  local upper_module_dir="$(git rev-parse --show-toplevel)"
  local upper_name="${upper_module_dir##*/}"
  local upper_version="$(git rev-parse --short HEAD)"
  local upper_commit="$(git rev-parse HEAD)"
  local upper_branch="$(git rev-parse --abbrev-ref HEAD)"
  local upper_timestamp="$(git log -1 --date=iso --pretty=format:%cd)"
  local upper_location="${module_dir/${upper_module_dir}/}"

  local full_name="${upper_name}-${name}-${location}"
  local full_version="${upper_branch}-${upper_version}-${branch}-${version}"
  full_name=${full_name/\//-}
  full_name=${full_name/--/-}
  full_version=${full_version/--/-}

  json_ret="{ 
  "\"name\"":"\"${name}\"",
  "\"version\"":"\"${version}\"",
  "\"commit\"":"\"${commit}\"",
  "\"branch\"":"\"${branch}\"",
  "\"timestamp\"":"\"${timestamp}\"",
  "\"location\"":"\"${location}\"",
  "\"upperName\"":"\"${upper_name}\"",
  "\"upperVersion\"":"\"${upper_version}\"",
  "\"upperCommit\"":"\"${upper_commit}\"",
  "\"upperBranch\"":"\"${upper_branch}\"",
  "\"upperTimeStamp\"":"\"${upper_timestamp}\"",
  "\"upperLocation\"":"\"${upper_location}\"",
  "\"fullName\"":"\"${full_name}\"",
  "\"fullVersion\"":"\"${full_version}\""
}"

  echo "${json_ret}"
  if [ ${config_output_file_path} != "" ]; then 
    cd "${g_caller_dir}"
    echo "${json_ret}" > ${config_output_file_path}
  fi
}

# Main

set -E
trap 'ErrorHandler $LINENO' ERR

Init
GetConfiguration "$@"
ScriptDetail
MainFunction
End 0

