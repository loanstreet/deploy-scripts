#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
DEPLOY_SCRIPTS_DIR="$SCRIPT_PATH/../"

if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ ! -d "$PROJECT_DEPLOY_DIR" ]; then
	error "No project deploy directory specified"
fi

. $SCRIPT_PATH/util.sh
. $SCRIPT_PATH/defaults.sh
. $PROJECT_DEPLOY_DIR/app-config.sh

PROJECT_SCRIPTS_DIR=$PROJECT_DEPLOY_DIR/scripts
# PROJECT_DOCKER_DIR=$PROJECT_DEPLOY_DIR/docker
WORK_DIR=$PROJECT_DEPLOY_DIR/.build
BUILD_REPO=$WORK_DIR/repo
DEPLOY_PACKAGE_DIR=$WORK_DIR/package
if [ "$1" = "" ]; then
	error "No environment set"
fi
PROJECT_ENVIRONMENT="$1"
DEPLOYMENT_ASSETS_DIR="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/assets/"

ds_clean_dirs() {
	if [ -d $WORK_DIR ]; then
		info "Deleting deployment work dir $WORK_DIR"
		rm -rf $WORK_DIR
	fi
}

ds_set_repo_type() {
	REPO_STR=$(echo $DEPLOYMENT_SERVER | cut -c -4)
	if [ "$REPO_STR" = "git@" ]; then
		REPO_TYPE="git"
	fi
}

title "check-files"
check_structure_ver_03 $PROJECT_DEPLOY_DIR $PROJECT_ENVIRONMENT
CONFIG_SH_PATH="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh"
if [ ! -f $PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh ]; then
	error "Please initialize $CONFIG_SH_PATH"
fi

. "$CONFIG_SH_PATH"

if [ "$TYPE" = "" ] || [ "$REPO" = "" ] || [ "$DEPLOYMENT_SERVER" = "" ] || [ "PROJECT_NAME" = "" ]; then
	error "Please set the variables TYPE, REPO, PROJECT_NAME, and DEPLOYMENT_SERVER in $CONFIG_SH_PATH"
fi

title 'repo - checkout'

ds_clean_dirs
mkdir -p $WORK_DIR

info "Creating repo to build program at $BUILD_REPO"
ds_set_repo_type
. "$SCRIPT_PATH/repo/$REPO_TYPE.sh"
ds_repo_fetch $REPO $BUILD_REPO

if [ -f $PROJECT_SCRIPTS_DIR/pre_build.sh ]; then
	title 'build - pre build script'
	sh $PROJECT_SCRIPTS_DIR/pre_build.sh
fi

if [ "$BUILD" != "" ]; then
	title 'build'
	info "Building the project in $BUILD_REPO"
	BUILD_SCRIPTS_PATH="$SCRIPT_PATH/../projects/$TYPE/build/$BUILD.sh"
	if [ ! -f "$BUILD_SCRIPTS_PATH" ]; then
		BUILD_SCRIPTS_PATH="$SCRIPT_PATH/build/$BUILD.sh"
		if [ ! -f "$BUILD_SCRIPTS_PATH" ]; then
			error "No build scripts available for $BUILD on $TYPE"
		fi
	fi
	. $BUILD_SCRIPTS_PATH
	ds_build $BUILD_REPO $DEPLOY_PACKAGE_DIR
fi

title 'package'
mkdir -p "$DEPLOY_PACKAGE_DIR/deploy"
DEPLOY_CONFIG_SH="$DEPLOY_PACKAGE_DIR/deploy/config.sh"

ds_cat_file $PROJECT_DEPLOY_DIR/app-config.sh $DEPLOY_CONFIG_SH
ds_cat_file $CONFIG_SH_PATH $DEPLOY_CONFIG_SH

. "$SCRIPT_PATH/../projects/$TYPE/format/$FORMAT.sh"
ds_format $DEPLOY_PACKAGE_DIR

cp $SCRIPT_PATH/run.sh "$DEPLOY_PACKAGE_DIR/deploy"
cp -rL "$DEPLOYMENT_ASSETS_DIR/*" "$DEPLOY_PACKAGE_DIR/deploy"

title 'package'
. "$SCRIPT_PATH/package/$PACKAGE.sh"
ds_package $DEPLOY_PACKAGE_DIR

if [ -d $PROJECT_SCRIPTS_DIR ]; then
	cp -r $PROJECT_SCRIPTS_DIR "$DEPLOY_PACKAGE_DIR/deploy"
	cd $DEPLOY_PACKAGE_DIR
	git add deploy/scripts 2>&1 | indent
	git commit . -m "added project scripts to server side deployment" 2>&1 | indent
	info "Copied project deployment scripts to server side deployment"
fi

# if [ "$RESOURCE_DIRS" != "" ]; then
# 	RES_DIRS=$(echo "$RESOURCE_DIRS" | cut -d";" -f1)
# 	for i in $RES_DIRS; do
# 		echo "$BUILD_REPO/$i"
# 		echo "$DEPLOY_REPO/$i"
# 		mkdir -p "$DEPLOY_REPO/$i"
# 		cp -r $BUILD_REPO/$i/* $DEPLOY_REPO/$i/
# 	done
# 	cd $DEPLOY_REPO
# 	git add . 2>&1 | indent
# 	git commit . -m "Added resource directories to deployment" 2>&1 | indent
# 	info "Copied resource files to deployment"
# fi

# if [ "$DOCKERIZE" = true ]; then
# 	copy_docker_files $PROJECT_DEPLOY_DIR $PROJECT_ENVIRONMENT $DEPLOY_REPO

# 	cd $DEPLOY_REPO
# 	git add . 2>&1 | indent
# 	git commit . -m "Added docker files to deployment" 2>&1 | indent
# 	info "Copied docker files to deployment"
# fi

if [ -f "$DEPLOY_PACKAGE_DIR/deploy/post_build.sh" ]; then
	cd $DEPLOY_PACKAGE_DIR
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
