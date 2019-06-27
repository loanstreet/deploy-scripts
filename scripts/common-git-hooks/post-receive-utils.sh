#!/bin/sh

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/util.sh
. $SCRIPT_PATH/config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
        DEPLOYMENT_DIR=$HOME/sites
else
	eval DEPLOYMENT_DIR=$DEPLOYMENT_DIR
fi

GIT_BARE_REPO=$HOME/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
DEPLOY_DIR=$DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT
WORK_TREE=$DEPLOY_DIR/releases/$(date +%s)

create_symlinks() {
	mkdir -p $DEPLOY_DIR/shared
	cd $DEPLOY_DIR/current
	if [ "$LINKED_DIRS" != "" ] || [ "$LINKED_FILES" != "" ]; then
		title 'deploy - shared symlinks'
	fi
	if [ "$LINKED_DIRS" != "" ]; then
        	LINK_DIRS=$(echo "$LINKED_DIRS" | cut -d";" -f1)
	        for i in $LINK_DIRS; do
			BASEDIR=$(dirname $i)
			mkdir -p $DEPLOY_DIR/current/$BASEDIR
        	        mkdir -p $DEPLOY_DIR/shared/$i
			printf "Creating symlink $i -> $DEPLOY_DIR/shared/$i ... "
                	ln -sf $DEPLOY_DIR/shared/$i $i
			success "done"
	        done
	fi
	if [ "$LINKED_FILES" != "" ]; then
        	LINK_FILES=$(echo "$LINKED_FILES" | cut -d";" -f1)
	        for j in $LINK_FILES; do
			cd $DEPLOY_DIR/shared
			DIR=$(dirname $j)
			mkdir -p $DIR
			cd $DEPLOY_DIR/current
			printf "Creating symlink $j -> $DEPLOY_DIR/shared/$j ... "
                	ln -s $DEPLOY_DIR/shared/$j $j
			success "done"
			if [ ! -f $DEPLOY_DIR/shared/$j ]; then
				warning "Shared file $j does not exist. Please create it manually."
			fi
	        done
	fi
}

deploy() {

	title 'deploy - post receive hook'

	if [ ! -d $DEPLOY_DIR ]; then
        	echo "Creating $DEPLOY_DIR"
	        mkdir -p $DEPLOY_DIR
	fi

	echo "Creating working directory $WORK_TREE"
	mkdir -p $WORK_TREE

	echo "Checking out working copy"
	git --work-tree=$WORK_TREE --git-dir=$GIT_BARE_REPO checkout -f 2>&1 | indent
	echo "Updating current symlink to $WORK_TREE"
	if [ -L "$DEPLOY_DIR/current" ]; then
		rm $DEPLOY_DIR/current
	fi
	cd $DEPLOY_DIR && ln -sf $WORK_TREE current
	# mkdir -p $DEPLOY_DIR/current/logs

	# create shared resources links
	create_symlinks
}
