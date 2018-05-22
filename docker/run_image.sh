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
  g_session_dir="${g_script_dir}/${RANDOM}_publisher_${RANDOM}"
  mkdir -p "${g_session_dir}"

  # exec > "${g_session_dir}/run_image.log"
}

End()
{
  Log "info" "5" "Removing session directory" "${g_session_dir}"
  rm -r "${g_session_dir}"

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
  Log "info" "5" "Script Name" "$(basename "$0")"
  Log "info" "5" "Caller Directory" "${g_caller_dir}"
  Log "info" "5" "Script Directory" "${g_script_dir}"
  Log "info" "5" "Session Directory" "${g_session_dir}"
}

GetConfiguration()
{
  config_options="$@"
  config_log_enabled="0"
  config_log_type="error"
  config_log_level="1"
  config_image="rogersantos/publisher"
}

IsVirtualBox()
{
  # Usage: IsVirtualBox <out:result>

  local result=$1

  local is_virtualbox_provider="$(docker info | grep provider=virtualbox)"
  if [ ${is_virtualbox_provider} = "provider=virtualbox" ]; then
    Log "info" "5" "Docker Server is running on VirtualBox" "${g_session_dir}"
    eval $result=true
    return
  fi

  eval $result=false
}

NormalizeDir()
{
  # Usage: NormalizeDir <out:result> <in:directory> 

  local result=$1
  local directory=$2

  local is_ubuntu_on_windows=$([ -e /proc/version ] && grep -l Microsoft /proc/version || echo "")
  local is_cygwin=$([ -e /proc/version ] && grep -l MINGW /proc/version || echo "")
  # Change the PWD when working in Docker on Windows
  if [ -n "${is_ubuntu_on_windows}" ]; then
    if IsVirtualBox ret && "${ret}" == "true"; then
        # directory=`pwd -P`
        directory=${directory/\/mnt\//}
        directory="/${directory}"
    else
        # directory=`pwd -P`
        directory=${directory/\/mnt\//}
        directory=${directory/\//:\/}
    fi
  elif [ -n "${is_cygwin}" ]; then
      # directory=$PWD
      directory=${directory/\//}
      directory=${directory/\//:\/}
  # else
      # directory=$PWD
  fi

  eval ${result}="${directory}"
}

RunDocker()
{
  # Usage: RunDocker <image_name> <session_dir> <commands>

  local docker_image=$1
  shift 1
  local session_dir=$1
  shift 1

  local container_name="${docker_image/\//-}-${RANDOM}"
  local work_dir="$(pwd -P)"
  NormalizeDir work_dir "${work_dir}"
  NormalizeDir session_dir "${session_dir}"

  local shell_command="docker run -it --rm --name ${container_name} -v "${session_dir}":/session -v "${work_dir}":/work ${docker_image} $@"
  Log "info" "5" "Docker Command" "${shell_command}"
  eval ${shell_command}
  # docker run -it --rm --name ${container_name} -v "${session_dir}":/session -v "${work_dir}":/work ${docker_image} "$@"
}

MainFunction()
{
  local post_execution="${g_session_dir}/exec.sh"
  echo "" > "${post_execution}"

  # exec &> "${g_session_dir}/run_image.log"
  RunDocker "${config_image}" "${g_session_dir}" ${config_options}
  # exec &>/dev/tty

  ${post_execution}
}

set -E
trap 'ErrorHandler $LINENO' ERR

Init
GetConfiguration "$@"
ScriptDetail
MainFunction
End

