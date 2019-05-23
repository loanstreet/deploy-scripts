#!/bin/sh

set -e

DEPLOY_SCRIPTS_GIT_REPO=git@git.loanstreet.com.my:loanstreet/deploy-scripts.git
DEPLOY_SCRIPTS_HOME="$HOME/.deploy-scripts"
SCRIPT_PATH=$(dirname $(readlink -f $0))

. $DEPLOY_SCRIPTS_HOME/scripts/util.sh

title "deploy-scripts - update"

if [ ! -d $DEPLOY_SCRIPTS_HOME ]; then
	git clone --single-branch --depth=1 --branch homedir_install $DEPLOY_SCRIPTS_GIT_REPO $DEPLOY_SCRIPTS_HOME | indent
else
	cd $DEPLOY_SCRIPTS_HOME
	git pull origin homedir_install | indent
fi

cd $SCRIPT_PATH

PROJECT_DEPLOY_DIR=$SCRIPT_PATH sh $DEPLOY_SCRIPTS_HOME/scripts/deploy.sh $1
