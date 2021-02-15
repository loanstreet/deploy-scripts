#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/../scripts/util.sh
. $SCRIPT_PATH/../scripts/defaults.sh
. $SCRIPT_PATH/util.sh

cd $SCRIPT_PATH/../projects/
PROJECT_TYPES=$(ls -d *)
cd $SCRIPT_PATH/../

if [ ! -d "$2" ]; then
	error "No such directory: $2"
fi

DS_DIR="deploy"

UNSUPPORTED=1
for i in $PROJECT_TYPES; do
	if [ "$1" = "$i" ]; then
		UNSUPPORTED=0
		break
	fi
done

if [ $UNSUPPORTED -eq 1 ]; then
	error "Project type $1 is unsupported"
fi

INSTALLER_CONFIG="$SCRIPT_PATH/../projects/$1/installer/config.sh"
PROJECT_INSTALLER="$SCRIPT_PATH/../projects/$1/installer/install.sh"

if [ ! -f "$PROJECT_INSTALLER" ]; then
	error "No installer found for project type: $1"
fi

if [ "$INSTALL_ENV" = "" ]; then
	INSTALL_ENV="development"
fi

if [ -f "$INSTALLER_CONFIG" ]; then
	. "$INSTALLER_CONFIG"
fi

. $PROJECT_INSTALLER
info "Installing deploy-scripts in $2"

title "installer: $1"
ds_install $2

if [ "$3" = "--docker" ]; then
	title "installer: docker"
	ds_install_docker $2 $1
fi

if [ "$4" = "--kubernetes" ]; then
	title "installer: kubernetes"
	ds_install_kubernetes $2
fi
