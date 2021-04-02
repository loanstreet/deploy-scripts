#!/bin/sh

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/util.sh
. $SCRIPT_PATH/post-deploy-utils.sh
. $SCRIPT_PATH/config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
		DEPLOYMENT_DIR=$HOME/sites/$SERVICE_NAME/$PROJECT_ENVIRONMENT
else
	eval DEPLOYMENT_DIR=$DEPLOYMENT_DIR
fi

GIT_BARE_REPO=$HOME/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
DEPLOY_DIR=$DEPLOYMENT_DIR
WORK_TREE=$DEPLOY_DIR/releases/$(date +%s)

deploy() {
	title 'remote: deploy'
	create_deploy_dir

	echo "Checking out working copy"
	git --work-tree=$WORK_TREE --git-dir=$GIT_BARE_REPO checkout -f 2>&1 | indent

	update_symlinks
}
