#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))

VERSION=$(cat $SCRIPT_PATH/.VERSION)

show_ds_usage() {
	printf "Usage:\n\tdeploy-scripts.sh [project directory] [environment name]\n"
	exit 1
}

if [ "$1" = "" ] || [ "$2" = "" ]; then
	show_ds_usage
fi

if [ ! -x "$(command -v docker)" ]; then
	printf "ERROR: Please install docker before executing this script.\n"
	show_ds_usage
fi

docker run -it finology/deploy-scripts:$VERSION -v "$1":/project $2
