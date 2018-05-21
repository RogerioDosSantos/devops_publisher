#!/bin/bash

config_repository_user="rogersantos"
config_repository_image="publisher"

DisplayError() {
    echo -e >&2 ERROR: $@\\n
}

DisplayErrorAndExist() {
    DisplayError $@
    exit 1
}

Log(){
  # Log <message>
  if [ ! -z "${config_debug}" ]; then
    echo "$@"
  fi
} 

HasCommand() {
    # eg. HasCommand command update
    local kind=$1
    local name=$2

    type -t $kind:$name | grep -q function
}

IsVirtualBox(){
  local result=$1
  local is_virtualbox_provider="$(docker info | grep provider=virtualbox)"
  if [ ${is_virtualbox_provider} = "provider=virtualbox" ]; then
    Log "Docker Server is running on VirtualBox"
    eval $result=true
    # eval $result=false
    return
  fi

  eval $result=false
}

command:update-image() {
    docker pull $FINAL_IMAGE
}

help:update-image() {
    echo Pull the latest $FINAL_IMAGE .
}

command:update-script() {
    if cmp -s <( docker run --rm $FINAL_IMAGE ) $0; then
        echo $0 is up to date
    else
        echo -n Updating $0 '... '
        docker run --rm $FINAL_IMAGE > $0 && echo ok
    fi
}

help:update-image() {
    echo Update $0 from $FINAL_IMAGE .
}

command:update() {
    command:update-image
    command:update-script
}

help:update() {
    echo Pull the latest $FINAL_IMAGE, and then update $0 from that.
}

command:help() {
    if [[ $# != 0 ]]; then
        if ! HasCommand command $1; then
            DisplayError \"$1\" is not supported command
            command:help
        elif ! HasCommand help $1; then
            DisplayError No help found for \"$1\"
        else
            help:$1
        fi
    else
        cat >&2 <<ENDHELP
Usage: dockcross [options] [--] command [args]

By default, run the given *command* in an dockcross Docker container.

The *options* can be one of:

    --args|-a           Extra args to the *docker run* command
    --config|-c         Bash script to source before running this script
    --debug|-d          Display the docker command being used

Additionally, there are special update commands:

    update-image
    update-script
    update

For update command help use: $0 help <command>
ENDHELP
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Option processing
#
special_update_command=''
while [[ $# != 0 ]]; do
    case $1 in

        --)
            shift
            break
            ;;

        --debug|-d)
            config_debug="1"
            shift 1
            ;;

        --args|-a)
            ARG_ARGS="$2"
            shift 2
            ;;

        --config|-c)
            ARG_CONFIG="$2"
            shift 2
            ;;

        update|update-image|update-script)
            special_update_command=$1
            break
            ;;
        -*)
            DisplayError Unknown option \"$1\"
            command:help
            exit
            ;;

        *)
            break
            ;;

    esac
done

# The precedence for options is:
# 1. command-line arguments
# 2. environment variables
# 3. defaults

# Source the config file if it exists
DEFAULT_DOCKCROSS_CONFIG=~/.dockcross
FINAL_CONFIG=${ARG_CONFIG-${DOCKCROSS_CONFIG-$DEFAULT_DOCKCROSS_CONFIG}}

[[ -f "$FINAL_CONFIG" ]] && source "$FINAL_CONFIG"

# Set the docker image
FINAL_IMAGE="${config_repository_user}/${config_repository_image}"

# Handle special update command
if [ "$special_update_command" != "" ]; then
    case $special_update_command in

        update)
            command:update
            exit $?
            ;;

        update-image)
            command:update-image
            exit $?
            ;;

        update-script)
            command:update-script
            exit $?
            ;;

    esac
fi

# Set the docker run extra args (if any)
FINAL_ARGS=${ARG_ARGS-${DOCKCROSS_ARGS}}

# Bash on Ubuntu on Windows
UBUNTU_ON_WINDOWS=$([ -e /proc/version ] && grep -l Microsoft /proc/version || echo "")
# MSYS, Git Bash, etc.
MSYS=$([ -e /proc/version ] && grep -l MINGW /proc/version || echo "")

if [ -z "$UBUNTU_ON_WINDOWS" -a -z "$MSYS" ]; then
    USER_IDS="-e BUILDER_UID=$( id -u ) -e BUILDER_GID=$( id -g ) -e BUILDER_USER=$( id -un ) -e BUILDER_GROUP=$( id -gn )"
fi

# Change the PWD when working in Docker on Windows
if [ -n "$UBUNTU_ON_WINDOWS" ]; then
  if IsVirtualBox ret && "${ret}" == "true"; then
      HOST_PWD=`pwd -P`
      HOST_PWD=${HOST_PWD/\/mnt\//}
      HOST_PWD="/${HOST_PWD}"
  else
      HOST_PWD=`pwd -P`
      HOST_PWD=${HOST_PWD/\/mnt\//}
      HOST_PWD=${HOST_PWD/\//:\/}
  fi
elif [ -n "$MSYS" ]; then
    HOST_PWD=$PWD
    HOST_PWD=${HOST_PWD/\//}
    HOST_PWD=${HOST_PWD/\//:\/}
else
    HOST_PWD=$PWD
fi

# Mount Additional Volumes
if [ -z "$SSH_DIR" ]; then
    SSH_DIR="$HOME/.ssh"
fi

HOST_VOLUMES=
if [ -e "$SSH_DIR" ]; then
    HOST_VOLUMES+="-v $SSH_DIR:/home/$(id -un)/.ssh"
fi

#------------------------------------------------------------------------------
# Now, finally, run the command in a container
#
tty -s && TTY_ARGS=-ti || TTY_ARGS=
CONTAINER_NAME="${config_repository_image}_${RANDOM}"

Log "Equivalent Docker command: docker run --rm ${TTY_ARGS} --name ${CONTAINER_NAME} -v \"${HOST_PWD}\":/work ${HOST_VOLUMES} ${USER_ID} ${FINAL_ARGS} ${FINAL_IMAGE} \"$@\""


docker run $TTY_ARGS --name $CONTAINER_NAME \
    -v "$HOST_PWD":/work \
    $HOST_VOLUMES \
    $USER_IDS \
    $FINAL_ARGS \
    $FINAL_IMAGE "$@"
run_exit_code=$?

# Attempt to delete container
rm_output=$(docker rm -f $CONTAINER_NAME 2>&1)
rm_exit_code=$?
if [[ $rm_exit_code != 0 ]]; then
  if [[ "$CIRCLECI" == "true" ]] && [[ $rm_output == *"Driver btrfs failed to remove"* ]]; then
    : # Ignore error because of https://circleci.com/docs/docker-btrfs-error/
  else
    echo "$rm_output"
    exit $rm_exit_code
  fi
fi

exit $run_exit_code



































