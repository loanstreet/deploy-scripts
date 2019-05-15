#!/bin/sh

SCRIPT_PATH=$(dirname $(readlink -f $0))

if [ "$PROJECT_ENVIRONMENT" = "" ]; then
	echo "No PROJECT_ENVIRONMENT supplied to java deploy script"
	exit
fi

. $SCRIPT_PATH/app-config.sh
. $SCRIPT_PATH/$PROJECT_ENVIRONMENT/config.sh

cd $SCRIPT_PATH/../
./mvnw package -Dmaven.test.skip=true
cd target/
WARFILE=$(ls *SNAPSHOT.war | head -n1)
echo "WARFILE=$WARFILE" > deploy-config.sh
PATH_TO_JAR='$HOME/sites'
PATH_TO_JAR=$PATH_TO_JAR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/$WARFILE
echo "PATH_TO_JAR=\"$PATH_TO_JAR\"" >> deploy-config.sh
COMMAND='nohup java -jar $PATH_TO_JAR -Dspring.profiles.active=$PROJECT_ENVIRONMENT --server.port=$SERVICE_PORT /tmp 2>> /dev/null >> /dev/null'
echo "START_COMMAND=\"$COMMAND\"" >> deploy-config.sh
mkdir -p $SCRIPT_PATH/repo/deploy
cp *.war $SCRIPT_PATH/repo/
cat $SCRIPT_PATH/app-config.sh $SCRIPT_PATH/$PROJECT_ENVIRONMENT/config.sh deploy-config.sh > $SCRIPT_PATH/repo/deploy/config.sh
cp $SCRIPT_PATH/run.sh $SCRIPT_PATH/repo/deploy/
cd $SCRIPT_PATH/repo
git init
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git add *.war
git add deploy/config.sh
git add deploy/run.sh
git commit . -m "push for deployment"
