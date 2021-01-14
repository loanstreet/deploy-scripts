#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
DEPLOY_SCRIPTS_DIR="$SCRIPT_PATH/../"

# default SSH port
DEPLOYMENT_SSH_PORT=22

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ ! -d "$PROJECT_DEPLOY_DIR" ]; then
	error "No project deploy directory specified"
fi

. $SCRIPT_PATH/util.sh
. $PROJECT_DEPLOY_DIR/app-config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
	DEPLOYMENT_DIR='$HOME/sites'
fi



if [ "$1" = "" ]; then
	error "No environment set"
else
	title "check-files"
	check_structure_ver_03 $PROJECT_DEPLOY_DIR $1
	PROJECT_ENVIRONMENT="$1"
	if [ ! -f $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh ] || [ "$BUILD" = "" ]; then
		error "Please initialize deploy/environments/$PROJECT_ENVIRONMENT/config.sh with vars BUILD, PROJECT_ENVIRONMENT, SERVICE_NAME, GIT_REPO, and GIT_BRANCH"
	fi
	. $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh
fi

PROJECT_SCRIPTS_DIR=$PROJECT_DEPLOY_DIR/scripts
PROJECT_DOCKER_DIR=$PROJECT_DEPLOY_DIR/docker
WORK_DIR=$PROJECT_DEPLOY_DIR/work
BUILD_REPO=$WORK_DIR/repo
# DEPS_DIR=$WORK_DIR/deps
DEPLOY_REPO=$WORK_DIR/deploy-repo

clean_dirs() {
	if [ -d $WORK_DIR ]; then
		info "Deleting deployment work dir $WORK_DIR"
		rm -rf $WORK_DIR
	fi
}

title 'build - prepare'

clean_dirs
mkdir -p $WORK_DIR

# if [ "$DEPENDENCIES" != "" ]; then
# 	info "Building dependent projects"
# 	mkdir -p $DEPS_DIR && cd $DEPS_DIR
# 	DEP_LABELS=$(echo "$DEPENDENCIES" | cut -d";" -f1)
# 	for i in $DEP_LABELS; do
# 		DEP_REPO=$(eval "echo \${${i}_GIT_REPO}")
# 		DEP_BRANCH=$(eval "echo \${${i}_GIT_BRANCH}")
# 		DEP_COMMAND=$(eval "echo \${${i}_BUILD_COMMAND}")
# 		if [ "$DEP_REPO" != "" ] && [ "$DEP_BRANCH" != "" ] && [ "$DEP_COMMAND" != "" ]; then
# 			info "Building git-hosted $i"
# 			mkdir $i
# 			git clone --single-branch --depth=1 --branch $DEP_BRANCH $DEP_REPO $i
# 			cd $i
# 			sh -c "$DEP_COMMAND"
# 		fi
# 	done
# fi

info "Creating repo to build program at $BUILD_REPO"
GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone --progress --single-branch --depth=1 --branch $GIT_BRANCH $GIT_REPO $BUILD_REPO #2>&1 | indent
cd $BUILD_REPO
info "Checked out $GIT_BRANCH from $GIT_REPO"

if [ -f $PROJECT_SCRIPTS_DIR/pre_build.sh ]; then
	title 'build - pre build script'
	sh $PROJECT_SCRIPTS_DIR/pre_build.sh
fi

PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT sh $DEPLOY_SCRIPTS_DIR/scripts/$BUILD.sh

if [ ! -d $DEPLOY_REPO ]; then
	error "No deployment repo created by $BUILD script. Exiting"
else if [ -d $PROJECT_SCRIPTS_DIR ]; then
	cp -r $PROJECT_SCRIPTS_DIR $DEPLOY_REPO/deploy/
	cd $DEPLOY_REPO
	git add deploy/scripts 2>&1 | indent
	git commit . -m "added project scripts to server side deployment" 2>&1 | indent
	info "Copied project deployment scripts to server side deployment"
fi

if [ "$RESOURCE_DIRS" != "" ]; then
	RES_DIRS=$(echo "$RESOURCE_DIRS" | cut -d";" -f1)
	for i in $RES_DIRS; do
		echo "$BUILD_REPO/$i"
		echo "$DEPLOY_REPO/$i"
		mkdir -p "$DEPLOY_REPO/$i"
		cp -r $BUILD_REPO/$i/* $DEPLOY_REPO/$i/
	done
	cd $DEPLOY_REPO
	git add . 2>&1 | indent
	git commit . -m "Added resource directories to deployment" 2>&1 | indent
	info "Copied resource files to deployment"
fi

if [ "$DOCKERIZE" = true ]; then
	copy_docker_files $PROJECT_DEPLOY_DIR $PROJECT_ENVIRONMENT $DEPLOY_REPO

	cd $DEPLOY_REPO
	git add . 2>&1 | indent
	git commit . -m "Added docker files to deployment" 2>&1 | indent
	info "Copied docker files to deployment"
fi

if [ -f $DEPLOY_REPO/deploy/scripts/post_build.sh ]; then
	cd $DEPLOY_REPO
	title 'build - post build script'
	sh deploy/scripts/post_build.sh
fi

cd $BUILD_REPO

if [ "$DEPLOYMENT_SERVER" = "" ]; then
	clean_dirs
	exit
fi

TIMESTAMP=$(date +%s)
BARE_REPO_SCRIPT_DIR=/tmp/deployer-$TIMESTAMP

DEST_REPO=$(echo $DEPLOYMENT_SERVER | cut -c -4)
DEPLOY_BRANCH=master
if [ "$DEST_REPO" != "git@" ]; then
	title 'deploy - bare repo scripts'
	mkdir -p $BARE_REPO_SCRIPT_DIR
	cat $PROJECT_DEPLOY_DIR/app-config.sh $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh > $BARE_REPO_SCRIPT_DIR/config.sh
	cp $SCRIPT_PATH/common-git-hooks/post-receive-utils.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/util.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/bare-repo.sh $BARE_REPO_SCRIPT_DIR/
	CUSTOM_POST_RECEIVE_HOOK=$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/git-hook-post-receive-$BUILD
	if [ -f "$CUSTOM_POST_RECEIVE_HOOK" ]; then
		info "Copying custom post-receive hook $CUSTOM_POST_RECEIVE_HOOK"
		cp $CUSTOM_POST_RECEIVE_HOOK $BARE_REPO_SCRIPT_DIR/
	else
		GENERIC_POST_RECEIVE_HOOK=$SCRIPT_PATH/common-git-hooks/git-hook-post-receive-$BUILD
		info "Copying generic post-receive hook $GENERIC_POST_RECEIVE_HOOK"
		cp $GENERIC_POST_RECEIVE_HOOK $BARE_REPO_SCRIPT_DIR/
	fi

	info "Copying scripts to create bare git repo"
	scp -o StrictHostKeyChecking=no -P$DEPLOYMENT_SSH_PORT -r $BARE_REPO_SCRIPT_DIR $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER:/tmp/ 2>&1 | indent
ssh -o "StrictHostKeyChecking no" -p $DEPLOYMENT_SSH_PORT -t $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER << EOSSH
cd $BARE_REPO_SCRIPT_DIR && sh ./bare-repo.sh
EOSSH
REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER:$DEPLOYMENT_SSH_PORT/~/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
else
REMOTE_GIT_BARE_REPO=$DEPLOYMENT_SERVER
cd $DEPLOY_REPO
git checkout -b $PROJECT_ENVIRONMENT
DEPLOY_BRANCH=$PROJECT_ENVIRONMENT
fi

title 'deploy - push'

info "Deploying $PROJECT_ENVIRONMENT to $REMOTE_GIT_BARE_REPO"

	cd $DEPLOY_REPO
	git remote add deploy $REMOTE_GIT_BARE_REPO 2>&1 | indent
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push deploy $DEPLOY_BRANCH -f
fi
clean_dirs
