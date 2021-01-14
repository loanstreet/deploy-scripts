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
. $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
	DEPLOYMENT_DIR='$HOME/sites'
fi

WORK_DIR=$PROJECT_DEPLOY_DIR/work
DEPLOY_REPO=$WORK_DIR/deploy-repo

cd $WORK_DIR/repo
./mvnw deploy -Dmaven.test.skip=true 2>&1 | indent
title 'build - java - prepare-deployment'
mkdir -p $DEPLOY_REPO
cd $DEPLOY_REPO

if [ "$GIT_PUSH_REMOTE" = "" ] || [ "$GIT_PUSH_BRANCH" = "" ]; then
	error "No git remote or branch specified to push to"
fi

git init 2>&1 | indent
git remote add origin $GIT_PUSH_REMOTE
git config user.name "deployer"
git config user.email "techgroup@loanstreet.com.my"
git fetch
git checkout $GIT_PUSH_BRANCH
git pull origin $GIT_PUSH_BRANCH
cp -r $WORK_DIR/repo/target/maven-repo/* ./
git add . 2>&1 | indent
git commit . -m "commit to repository" 2>&1 | indent
GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push origin $GIT_PUSH_BRANCH
