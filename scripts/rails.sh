#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/util.sh

title 'build - rails'

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ "$PROJECT_ENVIRONMENT" = "" ]; then
	echo "No project deploy directory or environment supplied to rails deploy script"
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
cd $PROJECT_DEPLOY_DIR/work/deploy-repo/config
mkdir -p deploy
cd deploy/
PID_PATH=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/pids/$SERVICE_NAME.pid'
SOCKET_PATH='unix://'$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/sockets/$SERVICE_NAME.sock'
if [ "$SERVICE_PORT" = "" ]; then
	COMMAND='$HOME/.rbenv/bin/rbenv exec bundle exec puma -C $DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/config/puma.rb --environment=$PROJECT_ENVIRONMENT --bind=$SOCKET_PATH --pidfile=$PID_PATH --daemon && sleep 3'
else
	COMMAND='$HOME/.rbenv/bin/rbenv exec bundle exec puma -C $DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/config/puma.rb --environment=$PROJECT_ENVIRONMENT -p $SERVICE_PORT --pidfile=$PID_PATH --daemon && sleep 3'
fi
cat $PROJECT_DEPLOY_DIR/app-config.sh $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh > config.sh
#echo 'eval DEPLOYMENT_DIR=$DEPLOYMENT_DIR' >> config.sh
echo "PID_PATH=\"$PID_PATH\"" >> config.sh
echo "SOCKET_PATH=\"$SOCKET_PATH\"" >> config.sh
echo "START_COMMAND=\"$COMMAND\"" >> config.sh
cp $SCRIPT_PATH/run.sh ./

title 'build - rails - prepare-deployment'
cd $PROJECT_DEPLOY_DIR/work/deploy-repo
git init 2>&1 | indent
git config color.ui auto
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git add . 2>&1 | indent
git commit . -m "files for deployment" 2>&1 | indent
