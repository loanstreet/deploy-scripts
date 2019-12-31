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

WORK_DIR=$PROJECT_DEPLOY_DIR/work
BUILD_REPO=$WORK_DIR/repo/
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
git clone --progress --single-branch --depth=1 --branch $GIT_BRANCH $GIT_REPO $BUILD_REPO #2>&1 | indent
cd $BUILD_REPO
info "Checked out $GIT_BRANCH from $GIT_REPO"

PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT sh $DEPLOY_SCRIPTS_DIR/scripts/$BUILD.sh

if [ ! -d $DEPLOY_REPO ]; then
	error "No deployment repo created by $BUILD script. Exiting"
fi

if [ "$DEPLOYMENT_SERVER" = "" ]; then
	clean_dirs
	exit
fi

title 'deploy - bare repo scripts'
TIMESTAMP=$(date +%s)
BARE_REPO_SCRIPT_DIR=/tmp/deployer-$TIMESTAMP

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
scp -P$DEPLOYMENT_SSH_PORT -r $BARE_REPO_SCRIPT_DIR $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER:/tmp/ 2>&1 | indent
ssh -p $DEPLOYMENT_SSH_PORT -t $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER << EOSSH
cd $BARE_REPO_SCRIPT_DIR && sh ./bare-repo.sh
EOSSH

title 'deploy - push'
REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER:$DEPLOYMENT_SSH_PORT/~/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
info "Deploying $PROJECT_ENVIRONMENT to $REMOTE_GIT_BARE_REPO"

	cd $DEPLOY_REPO
	git remote add deploy $REMOTE_GIT_BARE_REPO 2>&1 | indent
	git push deploy master -f
fi
clean_dirs
