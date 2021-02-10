#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh

DS_DIR="config/deploy-scripts"

PUMA_PID=$(ps -elf | grep ':37566' | grep -v grep | awk '{print $4}')
if [ "$PUMA_PID" != "" ]; then
	printf "Killing old puma PID: $PUMA_PID ... "
	kill -9 $PUMA_PID
	success 'done'
fi
copy_deployment_files 'rails' $SCRIPT_PATH/resources/rails-project

title 'TEST - editing configs'
SERVICE_NAME="rails-deploy-test"
PROJECT_ENVIRONMENT="production"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"

cd $COPY_PROJECT_DIR/rails-project
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/rails-project/$DS_DIR"
mv $DS_DIR/environments/default $DS_DIR/environments/production
echo "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/rails-project\nSERVICE_NAME=$SERVICE_NAME\nBUNDLE_PATH=/tmp/bundle\nLINKED_FILES=\nLINKED_DIRS=\"log tmp/pids tmp/cache tmp/sockets public/system\"" >> $DS_DIR/app-config.sh
echo "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT\nGIT_BRANCH=master\nSERVICE_PORT=37566\n" >> $DS_DIR/environments/production/config.sh
cat $DS_DIR/app-config.sh
cat $DS_DIR/environments/production/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
#sh config/deploy/deploy.sh production
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh production
cd $TEST_WORKING_DIR/rails-deploy-test/production/current
title 'TEST - check web application'
wget localhost:37566
printf 'Checking index page contents ... '
if [ $(grep -c 'Yay! You&rsquo;re on Rails!' index.html) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
sh $DS_DIR/run.sh stop
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
