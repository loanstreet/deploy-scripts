#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh

copy_deployment_files 'python' $SCRIPT_PATH/resources/django_project "default" "kubernetes"

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/python-project
SERVICE_NAME="python-deploy-test"
PROJECT_ENVIRONMENT="default"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/python-project/deploy"
HOST="deploy-scripts.dev.finology.com.my"
cp -r $SCRIPT_PATH/../projects/python/template/docker $PROJECT_DEPLOY_DIR/
cp -r $SCRIPT_PATH/../projects/python/template/environments/$PROJECT_ENVIRONMENT/docker $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/

printf "\nKUBERNETES_NGINX_SERVICE_HOST=\"deploy-scripts.finology.com.my\"\nDS_DEBUG=true\nDEPLOYMENT_DIR=$TEST_WORKING_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/python-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\nLINKED_DIRS=\"\"\n" >> deploy/app-config.sh
printf "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT\nGIT_BRANCH=master\nDOCKER_DELETE_LOCAL_IMAGE=true\nDOCKER_REGISTRY=https://dockerhub.finology.com.my\nPACKAGE=docker\nPUSH=docker\nPOST_PUSH=kubernetes\nKUBERNETES_CLUSTER=dev\nKUBERNETES_TLS=true\nKUBERNETES_INGRESS=ingress-dev-letsencrypt-prod\nKUBERNETES_NGINX_SERVICE_HOST=$HOST\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh
cat deploy/environments/default/config.sh
#sed -i 's/    image\: django_project\:latest//g' deploy/environments/default/docker/docker-compose.yml
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR

PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $COPY_PROJECT_DIR
sleep 40
title 'TEST - check web application'
wget "https://$HOST/"
printf 'Checking index page contents ... '
if [ $(grep -c 'The install worked successfully! Congratulations!' index.html) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
export KUBECONFIG="$HOME/.kube/dev.yaml"
kubectl delete service "python-deploy-test-default"
kubectl delete deployment "python-deploy-test-default"
rm -rf $HOME/.kube/sites/dev/letsencrypt-staging/*deploy-scripts.finology.com.my
rm -rf $HOME/.kube/sites/dev/*deploy-scripts.finology.com.my
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
