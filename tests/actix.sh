#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh


BIN_PID=$(ps -elf | grep '=8080' | grep -v grep | awk '{print $4}')
if [ "$BIN_PID" != "" ]; then
	printf "Killing old actix PID: $BIN_PID ... "
	kill -9 $BIN_PID
	success 'done'
fi
copy_deployment_files 'rust' $SCRIPT_PATH/resources/actix-project

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/rust-project
SERVICE_NAME="rust-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"

PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/rust-project/deploy"
DEPLOY_SCRIPTS_HOME="$SCRIPT_PATH/../"
printf "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/rust-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\n" >> deploy/app-config.sh
printf "GIT_BRANCH=master\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh deploy/environments/default/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR

if [ "$CI" = "true" ]; then
	mkdir -p "deploy/environments/$PROJECT_ENVIRONMENT/scripts"
	printf "ds_pre() {\n    echo 'Symlink target dir to cache in CI ... '\n    ln -sf /tmp/target $DS_BUILD_DIR/repo/target\n    pwd\n    echo $DS_BUILD_DIR\n     ls -al ../../../.build/repo\n}\n" > "deploy/environments/$PROJECT_ENVIRONMENT/scripts/build.sh"
fi

PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $TEST_WORKING_DIR/rust-deploy-test/default/current
title 'TEST - check web application'
sleep 5
wget localhost:8080
printf 'Checking index page contents ... '
if [ $(grep -c 'Hello, world!' index.html) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
sh deploy/run.sh stop
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
