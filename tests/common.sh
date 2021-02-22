#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/../scripts/util.sh

if [ "$USER" = "" ]; then
	export USER="root"
fi

DS_DEBUG=true

cd $SCRIPT_PATH/../
COPY_PROJECT_DIR="/tmp/deploy-scripts/projects"
TEST_WORKING_DIR="/tmp/deploy-scripts/test"

copy_deployment_files() {
	title "TEST - copy $1 project"
	rm -rf $COPY_PROJECT_DIR
	mkdir -p $COPY_PROJECT_DIR
	printf "Copying project to $COPY_PROJECT_DIR/ ... "
	cp -r "$2" "$COPY_PROJECT_DIR/$1-project"
	success 'done'
	echo "Initializing git repo in $COPY_PROJECT_DIR/$1-project"
	cd $COPY_PROJECT_DIR/$1-project
	git init
	git add .
	git config user.email "techgroup@loanstreet.com.my"
	git config user.name "Loanstreet Tech"
	git commit . -m "test commit"
	cd $SCRIPT_PATH/../
	IENV="default"
	if [ "$3" != "" ]; then
		IENV="$3"
	fi
	if [ "$3" = "docker" ] || [ "$4" = "docker" ]; then
		INSTALL_ENV="$IENV" sh installer/install.sh "$1" "$COPY_PROJECT_DIR/$1-project" --docker
	elif [ "$3" = "kubernetes" ] || [ "$4" = "kubernetes" ]; then
		INSTALL_ENV="$IENV" sh installer/install.sh "$1" "$COPY_PROJECT_DIR/$1-project" --docker --kubernetes
	else
		INSTALL_ENV="$IENV" sh installer/install.sh "$1" "$COPY_PROJECT_DIR/$1-project"
	fi
}

copy_deployment_files_template() {
	title "TEST - copy $1 project"
	rm -rf $COPY_PROJECT_DIR
	mkdir -p $COPY_PROJECT_DIR
	printf "Copying project to $COPY_PROJECT_DIR/ ... "
	cp -r "$2" "$COPY_PROJECT_DIR/$1-project"
	success 'done'
	echo "Initializing git repo in $COPY_PROJECT_DIR/$1-project"
	cd $COPY_PROJECT_DIR/$1-project
	git init
	git add .
	git config user.email "techgroup@loanstreet.com.my"
	git config user.name "Loanstreet Tech"
	git commit . -m "test commit"
	cd $SCRIPT_PATH/../
	sh installer/install.sh "$1" "$COPY_PROJECT_DIR/$1-project"
}

add_project_step() {
	info "Adding project step"
	echo "$1/scripts/steps"
	mkdir -p "$1/scripts/steps"
	echo "$3" > "$1/scripts/steps/$2.sh"
}

add_env_step() {
	info "Adding env step"
	echo "$1/scripts/steps"
	mkdir -p "$1/scripts/steps"
	echo "$3" > "$1/scripts/steps/$2.sh"
}
