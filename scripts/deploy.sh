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

# Make sure the project environment is set
if [ "$1" = "" ]; then
	error "No environment set"
fi
PROJECT_ENVIRONMENT="$1"

# Directory for project-specific pre and post build and post deploy scripts
PROJECT_SCRIPTS_DIR="$PROJECT_DEPLOY_DIR/scripts"
# Directory for environment-specific pre and post build and post deploy scripts
PROJECT_ENV_SCRIPTS_DIR="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/scripts"

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

DS_DIR_EXPR=$(echo $DS_DIR | sed 's/\//\\\//g')
PROJECT_DIR=$(echo $PROJECT_DEPLOY_DIR | sed -e "s/\/$DS_DIR_EXPR$//")

# Create directory to place deployment files into
mkdir -p $DEPLOY_PACKAGE_DIR

# Include step order
. $SCRIPT_PATH/steps.sh

ds_get_steps
debug "Running steps: $STEPS"

STEP_ORDER=$(echo "$STEPS" | cut -d";" -f1)
for i in $STEP_ORDER; do
	STEP_DIR="$SCRIPT_PATH/../steps/$i"
	PROJECT_STEP_FILE="$PROJECT_SCRIPTS_DIR/steps/$i.sh"
	ENV_STEP_FILE="$PROJECT_ENV_SCRIPTS_DIR/steps/$i.sh"
	if [ -d "$STEP_DIR" ]; then
		. "$STEP_DIR/step.sh"
	elif [ -f "$ENV_STEP_FILE" ]; then
		. "$ENV_STEP_FILE"
	elif [ -f "$PROJECT_STEP_FILE" ]; then
		. "$PROJECT_STEP_FILE"
	fi
	debug "step: $i"
	ds_exec_step
done

ds_clean_dirs
