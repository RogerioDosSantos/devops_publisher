#!/bin/bash

# This is the entrypoint script for the dockerfile. Executed in the
# container at runtime.

if [[ $# == 0 ]]; then
    # The image has been run directly, so help the user get started by outputting an execution script
    cat /docker/run_image.sh /docker/README.md
    exit 0
fi

# If we are running docker natively, we want to create a user in the container
# with the same UID and GID as the user on the host machine, so that any files
# created are owned by that user. Without this they are all owned by root.
# The dockcross script sets the HOST_USER and HOST_GID vars.
if [[ -n $HOST_USER ]] && [[ -n $HOST_GID ]]; then

    groupadd -o -g $HOST_GID $HOST_GROUP 2> /dev/null
    useradd -o -m -g $HOST_GID -u $HOST_USER $HOST_USER 2> /dev/null
    export HOME=/home/${HOST_USER}
    shopt -s dotglob
    cp -r /root/* $HOME/
    chown -R $HOST_USER:$HOST_GID $HOME

    # # Execute project specific pre execution hook
    # if [[ -e /work/.dockcross ]]; then
    #    gosu $HOST_USER:$HOST_GID /work/.dockcross
    # fi

    # Enable passwordless sudo capabilities for the user
    chown root:$HOST_GID $(which gosu)
    chmod +s $(which gosu); sync

    # Run the command as the specified user/group.
    exec gosu $HOST_USER:$HOST_GID "$@"
else
    # Just run the command as root.
    cd /work
    exec "$@"
fi
