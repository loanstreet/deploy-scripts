#!/bin/sh

set -e

# Current script dir
SCRIPT_PATH=$(dirname $(readlink -f $0))
# Deploy scripts installation dir
DEPLOY_SCRIPTS_DIR="$SCRIPT_PATH/../"

# Include deploy-scripts utility functions
. $SCRIPT_PATH/util.sh

# Make sure project directory is known
if [ "$PROJECT_DEPLOY_DIR" = "" ] || [ ! -d "$PROJECT_DEPLOY_DIR" ]; then
	error "No project deploy directory specified"
fi

# Include default env vars
. $SCRIPT_PATH/defaults.sh
# Include env vars for project
. $PROJECT_DEPLOY_DIR/app-config.sh

# Directory for project-specific pre and post build and post deploy scripts
PROJECT_SCRIPTS_DIR=$PROJECT_DEPLOY_DIR/scripts

# Make sure the project environment is set
if [ "$1" = "" ]; then
	error "No environment set"
fi
PROJECT_ENVIRONMENT="$1"

# Check if the DS_DIR in the project has the required files
title "check-files"
check_structure_ver_03 $PROJECT_DEPLOY_DIR $PROJECT_ENVIRONMENT
# Path to the environment specific config.sh
CONFIG_SH_PATH="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/config.sh"
if [ ! -f "$CONFIG_SH_PATH" ]; then
	error "Please initialize $CONFIG_SH_PATH"
fi
# Include vars from environment specific config.sh
. "$CONFIG_SH_PATH"

# Ensure that the minimal no. of vars are set
if [ "$TYPE" = "" ] || [ "$REPO" = "" ] || [ "$DEPLOYMENT_SERVER" = "" ] || [ "PROJECT_NAME" = "" ]; then
	error "Please set the variables TYPE, REPO, PROJECT_NAME, and DEPLOYMENT_SERVER in $CONFIG_SH_PATH"
fi

# Project environment specific directory from which to copy files as-is to be added to the deployment
DEPLOYMENT_ASSETS_DIR="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/assets"

# Working directory to build/prepare and push the deployment
WORK_DIR=$PROJECT_DEPLOY_DIR/.build
if [ "$DS_BUILD_DIR" != "" ]; then
	WORK_DIR="$DS_BUILD_DIR"
fi
# Directory into which project repo deployment branch is checked out
BUILD_REPO=$WORK_DIR/repo
# Directory where files will be assembled for deployment
DEPLOY_PACKAGE_DIR=$WORK_DIR/package

# Clean working directory (WORK_DIR)
ds_clean_dirs() {
	if [ -d $WORK_DIR ]; then
		info "Deleting deployment work dir $WORK_DIR"
		rm -rf $WORK_DIR
	fi
}

# If REPO_TYPE is unset, determine repo type from which to check out by repo url assigned to var REPO
ds_set_repo_type() {
	if [ "$REPO_TYPE" = "" ]; then
		REPO_STR=$(echo $REPO | cut -c -4)
		if [ "$REPO_STR" = "git@" ]; then
			REPO_TYPE="git"
		else
			error "Failed to determine REPO_TYPE for project checkout"
		fi
	fi
}

# If PUSH is unset, determine how to push from var DEPLOYMENT_SERVER
ds_set_push_type() {
	if [ "$PUSH" = "" ]; then
		PUSH_STR=$(echo $DEPLOYMENT_SERVER | cut -c -4)
		if [ "$PUSH_STR" = "git@" ]; then
			PUSH="git"
		else
			info "No PUSH type specified. Deployment not pushed."
		fi
	fi
}

# Directory holding scripts for the type of project to be deployed (configured by var TYPE)
PROJECT_TYPE_DIR="$SCRIPT_PATH/../projects/$TYPE"

DS_DIR="deploy"

# Include any project type config if supplied
PROJECT_TYPE_CONFIG="$PROJECT_TYPE_DIR/installer/config.sh"
if [ -f $PROJECT_TYPE_CONFIG ]; then
	. "$PROJECT_TYPE_CONFIG"
fi

# Initialize working directory
ds_clean_dirs
mkdir -p $WORK_DIR

# Checkout branch to be deployed into repo/ inside working dir
ds_set_repo_type
title "repo: checkout: $REPO_TYPE"
ds_pre_step 'repo' "$PROJECT_SCRIPTS_DIR"
info "Creating repo to build program at $BUILD_REPO"
# Get and run ds_repo_fetch() function for project repo type
. "$SCRIPT_PATH/../stages/repo/$REPO_TYPE.sh"
ds_repo_fetch $REPO $BUILD_REPO
ds_post_step 'repo' "$PROJECT_SCRIPTS_DIR"

# Execute any custom pre-build scripts
# pre_build.sh to be deprecated in favour of pre and post step scripts
if [ -f $PROJECT_SCRIPTS_DIR/pre_build.sh ]; then
	title 'build: pre build script'
	sh $PROJECT_SCRIPTS_DIR/pre_build.sh
fi

# Create directory to place deployment files into
mkdir -p $DEPLOY_PACKAGE_DIR

# Find and execute ds_build() function to build the files for deployment (configured by var BUILD)
if [ "$BUILD" != "" ]; then
	title "build: $BUILD"
	ds_pre_step 'build' "$PROJECT_SCRIPTS_DIR"
	info "Building the project in $BUILD_REPO"
	BUILD_SCRIPTS_PATH="$PROJECT_TYPE_DIR/build/$BUILD.sh"
	if [ ! -f "$BUILD_SCRIPTS_PATH" ]; then
		BUILD_SCRIPTS_PATH="$SCRIPT_PATH/build/$BUILD.sh"
		if [ ! -f "$BUILD_SCRIPTS_PATH" ]; then
			error "No build scripts available for $BUILD on $TYPE"
		fi
	fi
	. $BUILD_SCRIPTS_PATH
	ds_build $BUILD_REPO $DEPLOY_PACKAGE_DIR
	ds_post_step 'build' "$PROJECT_SCRIPTS_DIR"
fi

# Compile all the env vars into a config.sh to be added to the deployment files
mkdir -p "$DEPLOY_PACKAGE_DIR/$DS_DIR"
DEPLOY_CONFIG_SH="$DEPLOY_PACKAGE_DIR/$DS_DIR/config.sh"
ds_cat_file $PROJECT_DEPLOY_DIR/app-config.sh $DEPLOY_CONFIG_SH
ds_cat_file $CONFIG_SH_PATH $DEPLOY_CONFIG_SH

# Include deployment files location in the deployment config
echo "DS_DIR=$DS_DIR" >> "$DEPLOY_CONFIG_SH"
# Include project environment in the deployment config
echo "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT" >> "$DEPLOY_CONFIG_SH"

INCLUDE_RUN_SH=$(echo $RESTART_COMMAND | grep 'run.sh' | wc -l)

# If restart command used run.sh script, include it in the deployment
if [ $INCLUDE_RUN_SH -gt 0 ]; then
	cp $SCRIPT_PATH/run.sh "$DEPLOY_PACKAGE_DIR/$DS_DIR"
	echo "RESTART_COMMAND=\"sh ./$DS_DIR/run.sh restart\"" >> "$DEPLOY_CONFIG_SH"
fi

# Prepare the files for deployment using ds_format() depending on the project format (configured by var FORMAT)
if [ "$FORMAT" != "" ]; then
	title "format: $FORMAT"
	ds_pre_step 'format' "$PROJECT_SCRIPTS_DIR"
	. "$SCRIPT_PATH/../projects/$TYPE/format/$FORMAT.sh"
	ds_format $DEPLOY_PACKAGE_DIR
	ds_post_step 'format' "$PROJECT_SCRIPTS_DIR"
fi
rm -rf "$DEPLOY_PACKAGE_DIR/deploy-config.sh"

# Copy all files under project environment-specific assets/ dir to the deployment
if [ -d "$DEPLOYMENT_ASSETS_DIR" ]; then
	info "Copying assets"
	cp -rL "$DEPLOYMENT_ASSETS_DIR"/* "$DEPLOY_PACKAGE_DIR/$DS_DIR/"
	success "done"
fi

if [ "$PACKAGE" != "" ]; then
	# Package the deployment files in the desired format using ds_package() to be ready for delivery to deployment target
	title "package: $PACKAGE"
	ds_pre_step 'package' "$PROJECT_SCRIPTS_DIR"
	. "$SCRIPT_PATH/../stages/package/$PACKAGE.sh"
	ds_package $DEPLOY_PACKAGE_DIR
	ds_post_step 'package' "$PROJECT_SCRIPTS_DIR"
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

# Run any post-build scripts if they were supplied
# to be deprecated in favour of pre and post step scripts
if [ -f "$DEPLOY_PACKAGE_DIR/deploy/post_build.sh" ]; then
	cd $DEPLOY_PACKAGE_DIR
	title 'build - post build script'
	sh "$DEPLOY_PACKAGE_DIR/deploy/post_build.sh"
fi


cd $BUILD_REPO
# Quit if no target server is specified for delivering the deployment to
if [ "$DEPLOYMENT_SERVER" = "" ]; then
	ds_clean_dirs
	exit
fi

# Push the packaged deployment files using ds_push() to the deployment server
ds_set_push_type
if [ "$PUSH" != "" ]; then
	title "push: $PUSH"
	ds_pre_step 'push' "$PROJECT_SCRIPTS_DIR"
	. "$SCRIPT_PATH/../stages/push/$PUSH.sh"
	ds_push $DEPLOY_PACKAGE_DIR $PROJECT_TYPE_DIR
	ds_post_step 'push' "$PROJECT_SCRIPTS_DIR"
fi

# Run post push tasks using ds_post_push()
if [ "$POST_PUSH" != "" ]; then
	title "post-push: $POST_PUSH"
	ds_pre_step 'post-push' "$PROJECT_SCRIPTS_DIR"
	. "$SCRIPT_PATH/../stages/post-push/$POST_PUSH.sh"
	ds_post_push $DEPLOY_PACKAGE_DIR
	ds_post_step 'post-push' "$PROJECT_SCRIPTS_DIR"
fi

ds_clean_dirs
