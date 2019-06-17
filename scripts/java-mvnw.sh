#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/util.sh
title 'build - java maven wrapper'

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ "$PROJECT_ENVIRONMENT" = "" ]; then
	echo "No project deploy directory supplied to java deploy script"
	exit
fi

. $PROJECT_DEPLOY_DIR/app-config.sh
. $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh

cd $PROJECT_DEPLOY_DIR/work/repo
./mvnw package -Dmaven.test.skip=true 2>&1 | indent
title 'build - java - prepare-deployment'
cd target/
WARFILE=$(ls *SNAPSHOT.war | head -n1)
echo "WARFILE=$WARFILE" > deploy-config.sh
PATH_TO_JAR=$DEPLOYMENT_DIR
LOG_DIR='$DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/logs'
PATH_TO_JAR=$PATH_TO_JAR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/$WARFILE

echo "PATH_TO_JAR=\"$PATH_TO_JAR\"" >> deploy-config.sh
echo "LOG_DIR=\"$LOG_DIR\"" >> deploy-config.sh
COMMAND='nohup java -Dspring.profiles.active=$PROJECT_ENVIRONMENT -jar $PATH_TO_JAR --server.port=$SERVICE_PORT /tmp 2>> $LOG_DIR/stderr.log >> $LOG_DIR/stdout.log'
echo "START_COMMAND=\"$COMMAND\"" >> deploy-config.sh
mkdir -p $PROJECT_DEPLOY_DIR/work/deploy-repo/deploy
cp *.war $PROJECT_DEPLOY_DIR/work/deploy-repo
cat $PROJECT_DEPLOY_DIR/app-config.sh $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh deploy-config.sh > $PROJECT_DEPLOY_DIR/work/deploy-repo/deploy/config.sh
cp $SCRIPT_PATH/run.sh $PROJECT_DEPLOY_DIR/work/deploy-repo/deploy
cp $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/nginx.conf $PROJECT_DEPLOY_DIR/work/deploy-repo/deploy
cd $PROJECT_DEPLOY_DIR/work/deploy-repo
git init 2>&1 | indent
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git add *.war 2>&1 | indent
git add deploy/* 2>&1 | indent
git commit . -m "push for deployment" 2>&1 | indent
