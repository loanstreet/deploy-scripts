#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh

PROJECT_FILES_DIR=nextjs-project
SRV_SCRIPT_PID=$(ps -elf | grep 'tmp-webserver.js' | grep -v grep | awk '{print $4}')
if [ "$SRV_SCRIPT_PID" != "" ]; then
  printf "Killing old server.js PID: $SRV_SCRIPT_PID ... "
  kill -9 $SRV_SCRIPT_PID
  success 'done'
fi
copy_deployment_files 'nextjs' $SCRIPT_PATH/resources/$PROJECT_FILES_DIR

title 'TEST - editing configs'

SERVICE_NAME="nextjs-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"

cd $COPY_PROJECT_DIR/$PROJECT_FILES_DIR
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/nextjs-project/deploy"
printf "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/$PROJECT_FILES_DIR\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\nLINKED_DIRS=\n" >> deploy/app-config.sh
printf "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT\nGIT_BRANCH=master\nBUILD=''\nFORMAT=nextjs\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh
cat deploy/environments/default/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
#sh deploy/deploy.sh default
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $TEST_WORKING_DIR/nextjs-deploy-test/default/current
cp $COPY_PROJECT_DIR/$PROJECT_FILES_DIR/package.json.deploy ./package.json
cp $COPY_PROJECT_DIR/$PROJECT_FILES_DIR/tmp-webserver.js ./
cp $COPY_PROJECT_DIR/$PROJECT_FILES_DIR/phantomjs.js ./
# npm init -y
#npm i
npm i connect serve-static phantomjs-prebuilt --save-dev
node tmp-webserver.js $TEST_WORKING_DIR/nextjs-deploy-test/default/current &
# npm run dev-server &
sleep 6
SRV_SCRIPT_PID=$(ps -elf | grep 'tmp-webserver' | grep -v grep | awk '{print $4}')
info "Temp Web Server PID: $SRV_SCRIPT_PID"
title 'TEST - check web application'
export PATH="$TEST_WORKING_DIR/nextjs-deploy-test/default/current/node_modules/phantomjs-prebuilt/lib/phantom/bin:$PATH"
phantomjs phantomjs.js > index.test.html 2>&1
printf 'Checking index page contents ... '
if [ $(grep -c 'Welcome to React Parcel Micro App!' index.test.html) -eq 1 ]; then
  success 'success!'
else
  error 'fail! :('
fi
kill -9 $SRV_SCRIPT_PID
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
