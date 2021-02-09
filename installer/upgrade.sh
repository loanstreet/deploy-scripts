#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/../scripts/util.sh

if [ "$1" = "" ] || [ ! -f "$1/app-config.sh" ]; then
	error "No old deployment directory supplied"
fi

DSVER=$(grep 'ver_0.3' "$1/deploy.sh" | wc -l)

if [ $DSVER -ne 1 ]; then
	error "Can only upgrade from ver 0.3 to 0.5"
fi

. "$1/app-config.sh"

PREFIX="deploy"
if [ "$BUILD" = "" ]; then
	error "Corrupt app-config.sh, no BUILD variable found"
elif [ "$BUILD" = "rails" ]; then
	PREFIX='config/deploy-scripts'
fi

TYPE=""
FORMAT=""

if [ "$BUILD" = "java-mvnw" ] || [ "$BUILD" = "java-mvnw-lib" ]; then
	TYPE="java"
	BUILD="mvnw"
	FORMAT="spring-boot"
elif [ "$BUILD" = "python-uwsgi-flask" ]; then
	TYPE="python"
	BUILD=""
	FORMAT="flask"
elif [ "$BUILD" = "python-django" ]; then
	TYPE="python"
	BUILD=""
	FORMAT="django"
elif [ "$BUILD" = "reactjs" ]; then
	TYPE="reactjs"
	BUILD="npm"
elif [ "$BUILD" = "rails" ]; then
	TYPE="rails"
	BUILD=""
	FORMAT="rails"
fi

TIMESTAMP=$(date +%s)
TMP_DEPLOY="/tmp/deploy-scripts-upgrade-$TIMESTAMP"

mkdir -p $TMP_DEPLOY
sh $SCRIPT_PATH/install.sh $TYPE $TMP_DEPLOY --no-post-install
rm -rf $TMP_DEPLOY/$PREFIX/environments/default

NEW_CFG_PATH="$TMP_DEPLOY/$PREFIX/app-config.sh.new"
if [ "$BUILD" != "" ]; then
	echo "BUILD=$BUILD\n" >> $NEW_CFG_PATH
fi
if [ "$FORMAT" != "" ]; then
	echo "FORMAT=$FORMAT\n" >> $NEW_CFG_PATH
fi

while IFS= read -r line
do
	CHECK=$(echo $line | grep "BUILD" | wc -l)
	CHECK_REPO=$(echo $line | grep "GIT_REPO" | wc -l)
	CHECK_SSH_PRM=$(echo $line | grep "SSH_" | wc -l)
	CHECK_DEPLOYMENT_DIR=$(echo $line | grep "DEPLOYMENT_DIR" | wc -l)
	if [ $CHECK -eq 0 ]; then
		if [ $CHECK_REPO -eq 1 ]; then
			echo "REPO=$GIT_REPO" >> $NEW_CFG_PATH
		elif [ $CHECK_SSH_PRM -eq 1 ] || [ $CHECK_DEPLOYMENT_DIR -eq 1 ]; then
			:
		else
			echo $line >> $NEW_CFG_PATH
		fi
	fi
done < "$1/app-config.sh"

if [ "$DEPLOYMENT_SSH_USER" != "" ]; then
	echo "DEPLOYMENT_SERVER_USER=$DEPLOYMENT_SSH_USER" >> $NEW_CFG_PATH
fi
if [ "$DEPLOYMENT_SSH_PORT" != "" ]; then
	echo "DEPLOYMENT_SERVER_PORT=$DEPLOYMENT_SSH_PORT" >> $NEW_CFG_PATH
fi
if [ "$DEPLOYMENT_DIR" != "" ]; then
	NEW_DEPLOYMENT_DIR=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT'
	echo "DEPLOYMENT_DIR='$NEW_DEPLOYMENT_DIR'" >> $NEW_CFG_PATH
fi

mv $NEW_CFG_PATH "$TMP_DEPLOY/$PREFIX/app-config.sh"

info "Moving new deployment directory to old"
cd "$1/.."
if [ -d "$1/../.deploy-old" ]; then
	mv "$1/../.deploy-old" "$1/../.deploy-older"
fi
cp -r deploy .deploy-old
info "Replacing old app-config.sh with new"
mv "$TMP_DEPLOY/$PREFIX/app-config.sh" "$1/app-config.sh"
info "Replacing old deploy.sh with new"
mv "$TMP_DEPLOY/$PREFIX/deploy.sh" "$1/deploy.sh"

success "done"

success "Migrated old deployment structure in $1 to $(cat $SCRIPT_PATH/../.VERSION)"
