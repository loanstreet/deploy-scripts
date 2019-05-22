#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
DEPLOY_SCRIPTS_DIR=$HOME/.deploy-scripts

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ ! -d "$PROJECT_DEPLOY_DIR" ]; then
	echo "No project deploy directory specified"
	exit
fi

. $PROJECT_DEPLOY_DIR/app-config.sh

if [ "$1" = "" ]; then
    echo "No environment set"
    exit
else
    PROJECT_ENVIRONMENT="$1"
    if [ ! -f $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh ] || [ "$BUILD" = "" ]; then
        echo "Please initialize deploy/$PROJECT_ENVIRONMENT/config.sh with vars BUILD, PROJECT_ENVIRONMENT, SERVICE_NAME, GIT_REPO, and GIT_BRANCH"
        exit
    fi
    . $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh
fi

WORK_DIR=$PROJECT_DEPLOY_DIR/work
BUILD_REPO=$WORK_DIR/repo/
DEPLOY_REPO=$WORK_DIR/deploy-repo

clean_dirs() {
	if [ -d $WORK_DIR ]; then
		echo "Deleting deployment work dir $WORK_DIR"
		rm -rf $WORK_DIR
	fi
}

clean_dirs

BUILD_REPO=$PROJECT_DEPLOY_DIR/work/repo/
echo "Creating repo to build program at $BUILD_REPO"
mkdir -p $WORK_DIR
git clone --single-branch --depth=1 --branch $GIT_BRANCH $GIT_REPO $BUILD_REPO
cd $BUILD_REPO
echo "Checked out $GIT_BRANCH from $GIT_REPO"

PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $DEPLOY_SCRIPTS_DIR/scripts/$BUILD.sh

if [ ! -d $DEPLOY_REPO ]; then
	echo "No deployment repo created by $BUILD script. exiting"
	exit
fi

TIMESTAMP=$(date +%s)
BARE_REPO_SCRIPT_DIR=/tmp/deployer-$TIMESTAMP

mkdir -p $BARE_REPO_SCRIPT_DIR
cat $PROJECT_DEPLOY_DIR/app-config.sh $PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/config.sh > $BARE_REPO_SCRIPT_DIR/config.sh
cp $SCRIPT_PATH/bare-repo.sh $BARE_REPO_SCRIPT_DIR/
CUSTOM_POST_RECEIVE_HOOK=$PROJECT_DEPLOY_DIR/$PROJECT_ENVIRONMENT/git-hook-post-receive-$BUILD
if [ -f "$CUSTOM_POST_RECEIVE_HOOK" ]; then
	echo "Copying custom post-receive hook $CUSTOM_POST_RECEIVE_HOOK"
	cp $CUSTOM_POST_RECEIVE_HOOK $BARE_REPO_SCRIPT_DIR/
else
	GENERIC_POST_RECEIVE_HOOK=$SCRIPT_PATH/common-git-hooks/git-hook-post-receive-$BUILD
	echo "Copying generic post-receive hook $GENERIC_POST_RECEIVE_HOOK"
	cp $GENERIC_POST_RECEIVE_HOOK $BARE_REPO_SCRIPT_DIR/
fi

echo "Copying scripts to create bare git repo"
scp -r $BARE_REPO_SCRIPT_DIR $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER:/tmp/
ssh -t $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER << EOSSH
cd $BARE_REPO_SCRIPT_DIR && sh ./bare-repo.sh
EOSSH

REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER/home/$DEPLOYMENT_SSH_USER/repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
echo "Deploying $PROJECT_ENVIRONMENT to $REMOTE_GIT_BARE_REPO"

cd $DEPLOY_REPO
git remote add deploy $REMOTE_GIT_BARE_REPO
git push deploy master -f
clean_dirs
