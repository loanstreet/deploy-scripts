#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/../scripts/util.sh

if [ "$1" = "" ] || [ ! -f "$1/app-config.sh" ]; then
	error "No old deployment directory supplied"
fi

. "$1/app-config.sh"

PREFIX='deploy'

if [ "$BUILD" = "" ]; then
	error "Corrupt app-config.sh, no BUILD variable found"
elif [ "$BUILD" = "rails" ]; then
	PREFIX='config/deploy'
fi

TIMESTAMP=$(date +%s)
TMP_DEPLOY="/tmp/deploy-scripts-upgrade-$TIMESTAMP"

mkdir -p $TMP_DEPLOY
sh $SCRIPT_PATH/install.sh $BUILD $TMP_DEPLOY --no-post-install
rm -rf $TMP_DEPLOY/$PREFIX/environments/default

cp "$1/app-config.sh" $TMP_DEPLOY/$PREFIX/app-config.sh
if [ -f "$1/requirements.txt" ]; then
	cp "$1/requirements.txt" $TMP_DEPLOY/$PREFIX/requirements.txt
fi

info "Updating environments"

cd "$1"
ENVIRONMENTS=$(ls -d */)

for i in $ENVIRONMENTS; do
	info "Copying $i"
	cp -r "$i" $TMP_DEPLOY/$PREFIX/environments/
	cd "$TMP_DEPLOY/$PREFIX/environments/$i"
	mkdir assets
	if [ -f "nginx.conf" ]; then
		mv nginx.conf assets/
	fi
	if [ -f "uwsgi.ini" ]; then
		mv uwsgi.ini assets/
	fi
	cd "$1"
	success "done"
done

info "Moving new deployment directory to old"
cd "$1/.."
mv deploy .deploy-old
mv $TMP_DEPLOY/$PREFIX ./
success "done"

success "Migrated old deployment structure in $1 to $(cat $SCRIPT_PATH/../.VERSION)"
