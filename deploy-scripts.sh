#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))

show_version() {
	printf "deploy-scripts version 0.6.0\n"
}

show_ds_usage() {
	show_version
	printf "\nUsage:\n\tdeploy-scripts.sh [project directory] [environment name]\n"
	exit 1
}

show_installer_usage() {
	show_version
	printf "\nUsage:\n\tdeploy-scripts.sh --install [project type] [project directory] [options]\n\nThe values for [project type] can be\n\tjava\n\trails\n\tpython\n\treactjs\n\thtml\n\tnode\n"
	exit 1
}

show_error() {
	printf "ERROR: $1\n"
	exit 1
}

show_debug() {
	printf "DEBUG: $1\n"
}

if [ "$1" = "" ] || [ "$2" = "" ]; then
	show_ds_usage
fi

if [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
	show_version
	exit 0
fi

if [ ! -x "$(command -v docker)" ]; then
	printf "ERROR: Please install docker before executing this script.\n"
	show_ds_usage
fi

if [ "$1" = "--install" ]; then
	if [ "$3" = "" ] || [ "$2" = "--help" ]; then
		show_installer_usage
	else
		DIR_PATH=$(realpath "$3")
	fi

	docker run --rm -e CREATE_USER=$USER -e CREATE_USER_ID=$(id -u $USER) -e USER_GROUP_ID=$(id -g $USER) -v "$DIR_PATH":/project -it finology/deploy-scripts:latest --install "$2" "$4" "$5"
	exit 0
fi

if [ "$SSH_KEY" = "" ]; then
	SSH_KEY="id_rsa"
fi

SSH_PUBLIC_KEY="$HOME/.ssh/$SSH_KEY.pub"
SSH_PRIVATE_KEY="$HOME/.ssh/$SSH_KEY"

DIR_PATH=$(realpath "$1")
MOUNTS=""

if [ "$3" != "--no-auto-mounts" ]; then
	APP_CONFIG_PATH=$(find "$DIR_PATH" -name "app-config.sh")
	if [ "$APP_CONFIG_PATH" = "" ] || [ ! -f "$APP_CONFIG_PATH" ]; then
		show_error "No app-config.sh found. Is $1 configured with deploy-scripts?"
	fi
	DEPLOY_DIR=$(dirname $APP_CONFIG_PATH)
	CONFIG_PATH="$DEPLOY_DIR/environments/$2/config.sh"
	if [ ! -f "$CONFIG_PATH" ]; then
		show_error "No config.sh found for environment $1"
	fi

	. $APP_CONFIG_PATH
	. $CONFIG_PATH

	if [ "$TYPE" = "java" ]; then
		if [ -d "$HOME/.m2" ]; then
			VOLUMES="$VOLUMES $HOME/.m2:/root/.m2"
		fi
	fi

	if [ "$PACKAGE" = "docker" ]; then
		if [ -d "$HOME/.docker" ]; then
			VOLUMES="$VOLUMES $HOME/.docker:/root/.docker"
		fi
	fi

	if [ "$POST_PUSH" = "kubernetes" ]; then
		if [ -d "$HOME/.kube" ]; then
			VOLUMES="$VOLUMES $HOME/.kube:/root/.kube"
		fi
	fi

	if [ "$DOCKER_ADD_SSH_KEY" != "" ]; then
		DOCKER_ADD_SSH_PUBLIC_KEY="$DOCKER_ADD_SSH_KEY.pub"

		if [ -f "$DOCKER_ADD_SSH_KEY" ] && [ -f "$DOCKER_ADD_SSH_PUBLIC_KEY" ]; then
			PRIV_KEY_FILE=$(basename $DOCKER_ADD_SSH_KEY)
			PUB_KEY_FILE=$(basename $DOCKER_ADD_SSH_PUBLIC_KEY)
			VOLUMES="$VOLUMES $DOCKER_ADD_SSH_KEY:/root/.ssh/$PRIV_KEY_FILE $DOCKER_ADD_SSH_PUBLIC_KEY:/root/.ssh/$PUB_KEY_FILE"
		fi
	fi
fi

if [ "$VOLUMES" != "" ]; then
	VOLUME_LIST=$(echo $VOLUMES | cut -d";" -f1)
	for i in $VOLUME_LIST; do
		MOUNTS="$MOUNTS -v $i"
	done
fi

DEPLOY_COMMAND="docker run --rm $MOUNTS -v \"$SSH_PUBLIC_KEY\":/root/.ssh/id_rsa.pub -v \"$SSH_PRIVATE_KEY\":/root/.ssh/id_rsa -v /var/run/docker.sock:/var/run/docker.sock -v \"$DIR_PATH\":/project -it finology/deploy-scripts:latest \"$2\""
if [ "$DS_DEBUG" = true ]; then
	show_debug "$DEPLOY_COMMAND"
fi
sh -c "$DEPLOY_COMMAND"
