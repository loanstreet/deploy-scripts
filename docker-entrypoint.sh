#!/bin/sh

set -e

. $HOME/.profile

DEPLOY_SCRIPTS_HOME="$HOME/.deploy-scripts"
VERSION=$(cat $DEPLOY_SCRIPTS_HOME/.VERSION)

show_usage() {
	printf "Usage:\n\tdocker run -it deploy-scripts:$VERSION -v [project directory path]:/project [environment name]\n"
	exit 1
}

if [ "$1" = "" ] || [ "$1" = "--help" ]; then
	show_usage
fi

APP_CONFIG_PATH=$(find /project -name "app-config.sh")

if [ "$APP_CONFIG_PATH" = "" ]; then
	printf "ERROR: No deploy-scripts config dir found in project. Project directory not mounted to /project?\n\n"
	show_usage
fi

DEPLOY_DIRECTORY_PATH=$(dirname $APP_CONFIG_PATH)

if [ ! -d "$DEPLOY_DIRECTORY_PATH/environments/$1" ]; then
	printf "ERROR: No environment $1 found at $DEPLOY_DIRECTORY_PATH/environments/$1\n\n"
	show_usage
fi

PROJECT_DEPLOY_DIR="$DEPLOY_DIRECTORY_PATH" sh $DEPLOY_SCRIPTS_HOME/deploy.sh "$1"
