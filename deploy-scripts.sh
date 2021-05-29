#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))

VERSION="0.6.0"

show_ds_usage() {
	printf "Usage:\n\tdeploy-scripts.sh [project directory] [environment name]\n"
	exit 1
}

show_installer_usage() {
	printf "Usage:\n\tdeploy-scripts.sh --install [project type] [project directory] [options]\n"
	exit 1
}

if [ "$1" = "" ] || [ "$2" = "" ]; then
	show_ds_usage
fi

if [ ! -x "$(command -v docker)" ]; then
	printf "ERROR: Please install docker before executing this script.\n"
	show_ds_usage
fi

if [ "$1" = "--install" ]; then
	if [ "$3" = "" ]; then
		show_installer_usage
	else
		DIR_PATH=$(realpath "$3")
	fi

	docker run --rm -e CREATE_USER=$USER -e CREATE_USER_ID=$(id -u $USER) -e USER_GROUP_ID=$(id -g $USER) -v "$DIR_PATH":/project -it finology/deploy-scripts:$VERSION --install "$2" "$4" "$5"
	exit 0
fi

if [ "$SSH_KEY" = "" ]; then
	SSH_KEY="id_rsa"
fi

SSH_PUBLIC_KEY="$HOME/.ssh/$SSH_KEY.pub"
SSH_PRIVATE_KEY="$HOME/.ssh/$SSH_KEY"

DIR_PATH=$(realpath "$1")
docker run --rm -v "$SSH_PUBLIC_KEY":/root/.ssh/id_rsa.pub -v "$SSH_PRIVATE_KEY":/root/.ssh/id_rsa -v "$DIR_PATH":/project -it finology/deploy-scripts:$VERSION "$2"
