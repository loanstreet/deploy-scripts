#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh

kill_server() {
	PHP_SERV_PID=$(ps -elf | grep ':37590' | grep -v grep | awk '{print $4}')
	if [ "$PHP_SERV_PID" != "" ]; then
		printf "Killing old PHP server PID: $PHP_SERV_PID ... "
		kill -9 $PHP_SERV_PID
		success 'done'
	fi
}
kill_server
copy_deployment_files 'html' $SCRIPT_PATH/resources/html-project

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/html-project
SERVICE_NAME="html-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"

PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/html-project/deploy"
DEPLOY_SCRIPTS_HOME="$SCRIPT_PATH/../"
printf "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/html-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\n" >> deploy/app-config.sh
printf "RESTART_COMMAND=\nGIT_BRANCH=master\nSERVICE_PORT=37590\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh deploy/environments/default/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $TEST_WORKING_DIR/html-deploy-test/default/current
title 'TEST - check web application'
php -S localhost:37590 &
sleep 5
wget localhost:37590
printf 'Checking index page contents ... '
if [ $(grep -c 'Example static HTML site!' index.html.1) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
kill_server
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
