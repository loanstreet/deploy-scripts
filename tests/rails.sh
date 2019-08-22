#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh


PUMA_PID=$(ps -elf | grep ':37566' | grep -v grep | awk '{print $4}')
if [ "$PUMA_PID" != "" ]; then
	printf "Killing old puma PID: $PUMA_PID ... "
	kill -9 $PUMA_PID
	success 'done'
fi
copy_deployment_files 'rails' $SCRIPT_PATH/resources/rails-project

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/rails-project
mv config/deploy/environments/default config/deploy/environments/development
echo "\nDEPLOYMENT_DIR=$TEST_WORKING_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SSH_USER=$USER\nGIT_REPO=file://$COPY_PROJECT_DIR/rails-project\nSERVICE_NAME=rails-deploy-test\nLINKED_FILES=\n" >> config/deploy/app-config.sh
echo "PROJECT_ENVIRONMENT=development\nGIT_BRANCH=master\nSERVICE_PORT=37566" >> config/deploy/environments/development/config.sh
cat config/deploy/app-config.sh
cat config/deploy/environments/development/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
sh config/deploy/deploy.sh development
cd $TEST_WORKING_DIR/rails-deploy-test/development/current
title 'TEST - check web application'
wget localhost:37566
printf 'Checking index page contents ... '
if [ $(grep -c 'Yay! You&rsquo;re on Rails!' index.html) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
sh config/deploy/run.sh stop
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
