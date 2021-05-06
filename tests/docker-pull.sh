#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh

CONT_ID=$(docker container ls | grep 'django_project:latest' | awk '{print $1}')
if [ "$CONT_ID" != "" ]; then
	docker container stop $CONT_ID
fi

copy_deployment_files 'python' $SCRIPT_PATH/resources/django_project "default" "kubernetes"

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/python-project
SERVICE_NAME="python-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/python-project/deploy"
HOST="localhost:8000"
cp -r $SCRIPT_PATH/../projects/python/template/docker $PROJECT_DEPLOY_DIR/
cp -r $SCRIPT_PATH/../projects/python/template/environments/$PROJECT_ENVIRONMENT/docker $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/
sed -i "s/image:.*$/image: finology\/tech:k8s-test/g" $SCRIPT_PATH/../projects/python/template/environments/$PROJECT_ENVIRONMENT/docker/docker-compose.yml

cat $SCRIPT_PATH/../projects/python/template/environments/$PROJECT_ENVIRONMENT/docker/docker-compose.yml

export DS_DEBUG=true
printf "\nDEPLOYMENT_DIR=$TEST_WORKING_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/python-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\nLINKED_DIRS=\"\"\n" >> deploy/app-config.sh
printf "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT\nGIT_BRANCH=master\nPACKAGE=docker\nPUSH=docker\nPOST_PUSH=docker-pull\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh
cat deploy/environments/default/config.sh
#sed -i 's/    image\: django_project\:latest//g' deploy/environments/default/docker/docker-compose.yml
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR

PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $COPY_PROJECT_DIR
sleep 7
title 'TEST - check web application'
wget "http://$HOST/"
printf 'Checking index page contents ... '
if [ $(grep -c 'The install worked successfully! Congratulations!' index.html) -eq 2 ]; then
	success 'success!'
else
	error 'fail! :('
fi
CONT_ID=$(docker container ls | grep 'k8s-test' | awk '{print $1}')
docker container stop $CONT_ID
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
