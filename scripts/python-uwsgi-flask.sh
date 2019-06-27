#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/util.sh

title 'build - python uwsgi flask'

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ "$PROJECT_ENVIRONMENT" = "" ]; then
	echo "No project deploy directory or environment supplied to python deploy script"
	exit
fi

. $PROJECT_DEPLOY_DIR/app-config.sh
. $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
        DEPLOYMENT_DIR='$HOME/sites'
fi

mkdir -p $PROJECT_DEPLOY_DIR/work/deploy-repo
cd $PROJECT_DEPLOY_DIR/work/repo
git --work-tree=../deploy-repo --git-dir=.git checkout -f 2>&1 | indent
cd $PROJECT_DEPLOY_DIR/work/deploy-repo/
mkdir -p deploy
cd deploy/
PID_PATH=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/pids/$SERVICE_NAME.pid'
SOCKET_PATH=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/sockets/$PROJECT_ENVIRONMENT.sock'
COMMAND='cd $DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current'
cat $PROJECT_DEPLOY_DIR/app-config.sh $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh > config.sh
echo "PID_PATH=\"$PID_PATH\"" >> config.sh
echo "SOCKET_PATH=\"$SOCKET_PATH\"" >> config.sh
echo "START_COMMAND=\"$COMMAND && /bin/bash -c 'source venv/bin/activate && uwsgi --ini deploy/uwsgi.ini -s $SOCKET_PATH --pidfile $PID_PATH &' && sleep 5\"" >> config.sh
cp $SCRIPT_PATH/run.sh ./

title 'build - python - prepare-deployment'
cd $PROJECT_DEPLOY_DIR/work/deploy-repo
git init 2>&1 | indent
git config color.ui auto
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git add . 2>&1 | indent
git commit . -m "files for deployment" 2>&1 | indent
