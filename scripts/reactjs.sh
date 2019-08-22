#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/util.sh

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ "$PROJECT_ENVIRONMENT" = "" ]; then
	echo "No project deploy directory or environment supplied to rails deploy script"
	exit
fi

. $PROJECT_DEPLOY_DIR/app-config.sh
. $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
        DEPLOYMENT_DIR='$HOME/sites'
fi

title 'build - reactjs - prepare deployment'
mkdir -p $PROJECT_DEPLOY_DIR/work/deploy-repo
cd $PROJECT_DEPLOY_DIR/work/repo
git --work-tree=../deploy-repo --git-dir=.git checkout -f 2>&1 | indent
cd $PROJECT_DEPLOY_DIR/work/deploy-repo/
mkdir -p deploy
cd deploy/
cat $PROJECT_DEPLOY_DIR/app-config.sh $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh > config.sh
cp -r $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/assets/* ./

cd $PROJECT_DEPLOY_DIR/work/deploy-repo
git init 2>&1 | indent
git config color.ui auto
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git add . 2>&1 | indent
git commit . -m "files for deployment" 2>&1 | indent
