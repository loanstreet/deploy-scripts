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
	PREFIX='config/deploy'
fi

TIMESTAMP=$(date +%s)
TMP_DEPLOY="/tmp/deploy-scripts-upgrade-$TIMESTAMP"

mkdir -p $TMP_DEPLOY
cp -r "$1/"* "$TMP_DEPLOY/"

NEW_CFG_PATH="$TMP_DEPLOY/app-config.sh.new"

while IFS= read -r line
do
	CHECK=$(echo $line | grep "BUILD" | wc -l)
	CHECK_REPO=$(echo $line | grep "GIT_REPO" | wc -l)
	CHECK_SSH_PRM=$(echo $line | grep "SSH_" | wc -l)
	if [ $CHECK -eq 0 ]; then
		if [ $CHECK_REPO -eq 1 ]; then
			echo "REPO=$GIT_REPO" >> $NEW_CFG_PATH
		elif [ $CHECK_SSH_PRM -eq 1 ]; then
			:
		else
			echo $line >> $NEW_CFG_PATH
		fi
	else
		if [ "$BUILD" = "java-mvnw" ] || [ "$BUILD" = "java-mvnw-lib" ]; then
			echo "TYPE=java\nBUILD=mvnw\nFORMAT=spring-boot\n" >> $NEW_CFG_PATH
		elif [ "$BUILD" = "python-uwsgi-flask" ]; then
			echo "TYPE=python\nFORMAT=flask\n" >> $NEW_CFG_PATH
		elif [ "$BUILD" = "python-django" ]; then
			echo "TYPE=python\nFORMAT=django\n" >> $NEW_CFG_PATH
		elif [ "$BUILD" = "reactjs" ]; then
			echo "TYPE=reactjs\nBUILD=npm\n" >> $NEW_CFG_PATH
		elif [ "$BUILD" = "rails" ]; then
			echo "TYPE=rails\nFORMAT=rails\n" >> $NEW_CFG_PATH
		fi
	fi
done < "$TMP_DEPLOY/app-config.sh"

if [ "$DEPLOYMENT_SSH_USER" != "" ]; then
	echo "DEPLOYMENT_SERVER_USER=$DEPLOYMENT_SSH_USER" >> $NEW_CFG_PATH
fi
if [ "$DEPLOYMENT_SSH_PORT" != "" ]; then
	echo "DEPLOYMENT_SERVER_PORT=$DEPLOYMENT_SSH_PORT" >> $NEW_CFG_PATH
fi

info "Replacing old app-config.sh with new"
mv $NEW_CFG_PATH "$TMP_DEPLOY/app-config.sh"

info "Moving new deployment directory to old"
cd "$1/.."
if [ -d "$1/../.deploy-old" ]; then
	mv "$1/../.deploy-old" "$1/../.deploy-older"
fi
mv deploy .deploy-old
mkdir deploy
mv $TMP_DEPLOY/* $1/
success "done"

success "Migrated old deployment structure in $1 to $(cat $SCRIPT_PATH/../.VERSION)"
