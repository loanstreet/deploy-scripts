#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))

cd $SCRIPT_PATH

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

. $SCRIPT_PATH/scripts/util.sh
title "deploy-scripts $(cat $SCRIPT_PATH/.VERSION) - update"
git pull origin $CURRENT_BRANCH | indent

if [ "$PROJECT_DEPLOY_DIR" = "" ]; then
	error "No project directory specified through PROJECT_DEPLOY_DIR variable"
fi
if [ "$1" = "" ]; then
	error "No deployment enviroment supplied"
fi

cd $PROJECT_DEPLOY_DIR
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/scripts/deploy.sh $1
