#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))

if [ "$PROJECT_ENVIRONMENT" = "" ]; then
	echo "No PROJECT_ENVIRONMENT supplied to java deploy script"
	exit
fi

. $SCRIPT_PATH/../app-config.sh
. $SCRIPT_PATH/../$PROJECT_ENVIRONMENT/config.sh

cd $SCRIPT_PATH/../work/repo
./mvnw package -Dmaven.test.skip=true
cd target/
WARFILE=$(ls *SNAPSHOT.war | head -n1)
echo "WARFILE=$WARFILE" > deploy-config.sh
PATH_TO_JAR='$HOME/sites'
LOG_DIR='$HOME/sites/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/logs'
PATH_TO_JAR=$PATH_TO_JAR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/$WARFILE

echo "PATH_TO_JAR=\"$PATH_TO_JAR\"" >> deploy-config.sh
echo "LOG_DIR=\"$LOG_DIR\"" >> deploy-config.sh
COMMAND='nohup java -Dspring.profiles.active=$PROJECT_ENVIRONMENT -jar $PATH_TO_JAR --server.port=$SERVICE_PORT /tmp 2>> $LOG_DIR/stderr.log >> $LOG_DIR/stdout.log'
echo "START_COMMAND=\"$COMMAND\"" >> deploy-config.sh
mkdir -p $SCRIPT_PATH/../work/deploy-repo/deploy
cp *.war $SCRIPT_PATH/../work/deploy-repo
cat $SCRIPT_PATH/../app-config.sh $SCRIPT_PATH/../$PROJECT_ENVIRONMENT/config.sh deploy-config.sh > $SCRIPT_PATH/../work/deploy-repo/deploy/config.sh
cp $SCRIPT_PATH/run.sh $SCRIPT_PATH/../work/deploy-repo/deploy
cp $SCRIPT_PATH/../$PROJECT_ENVIRONMENT/nginx.conf $SCRIPT_PATH/../work/deploy-repo/deploy
cd $SCRIPT_PATH/../work/deploy-repo
git init
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git add *.war
git add deploy/*
git commit . -m "push for deployment"
