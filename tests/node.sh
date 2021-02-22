#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh


NODE_PID=$(ps -elf | grep 'app.js' | grep -v grep | awk '{print $4}')
if [ "$NODE_PID" != "" ]; then
	printf "Killing old node PID: $NODE_PID ... "
	kill -9 $NODE_PID
	success 'done'
fi
copy_deployment_files 'node' $SCRIPT_PATH/resources/node-project

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/node-project
SERVICE_NAME="node-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"

PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/node-project/deploy"
DEPLOY_SCRIPTS_HOME="$SCRIPT_PATH/../"
printf "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/node-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\nNODE_SCRIPT=build/bin/www\n" >> deploy/app-config.sh
cat deploy/app-config.sh deploy/environments/$PROJECT_ENVIRONMENT/config.sh

rm -rf $TEST_WORKING_DIR
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $TEST_WORKING_DIR/node-deploy-test/$PROJECT_ENVIRONMENT/current
title 'TEST - check web application'
sleep 5
wget localhost:3000
printf 'Checking index page contents ... '
if [ $(grep -c 'Welcome to Express' index.html) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
sh deploy/run.sh stop
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
