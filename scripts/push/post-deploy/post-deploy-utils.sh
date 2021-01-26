create_symlinks() {
	mkdir -p $DEPLOY_DIR/shared
	cd $DEPLOY_DIR/current
	if [ "$LINKED_DIRS" != "" ] || [ "$LINKED_FILES" != "" ]; then
		title 'remote: shared symlinks'
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

exec_post_deploy() {
	if [ ! -f $DEPLOY_DIR/current/deploy/scripts/post_deploy.sh ]; then
		return
	fi

	cd $DEPLOY_DIR/current
	title 'remote: post deploy script'
	sh deploy/scripts/post_deploy.sh
}

post_startup() {
	if [ ! -f $DEPLOY_DIR/current/deploy/scripts/post_startup.sh ]; then
		return
	fi

	cd $DEPLOY_DIR/current
	title 'remote: post startup script'
	sh deploy/scripts/post_startup.sh
}

delete_old_releases() {
	cd $WORK_TREE/../

	if [ "$RELEASE_COUNT" = "" ]; then
		RELEASE_COUNT=5
	fi

	printf "Deleting releases older than last $RELEASE_COUNT ... "

	ls -t1 | tail -n +$RELEASE_COUNT | xargs rm -rf

	success "done"

	cd $DEPLOY_DIR/current
}

create_deploy_dir() {
	if [ ! -d $DEPLOY_DIR ]; then
			echo "Creating $DEPLOY_DIR"
			mkdir -p $DEPLOY_DIR
	fi

	echo "Creating deployment directory $WORK_TREE"
	mkdir -p $WORK_TREE
}

update_symlinks() {
	echo "Updating current symlink to $WORK_TREE"
	if [ -L "$DEPLOY_DIR/current" ]; then
		rm $DEPLOY_DIR/current
	fi
	cd $DEPLOY_DIR && ln -sf $WORK_TREE current

	# create shared resources links
	create_symlinks

	delete_old_releases

	exec_post_deploy
}

restart_application() {
	cd $DEPLOY_DIR/current
	# To be fixed later
	if [ -f "./config/deploy/config.sh" ]; then
		. ./config/deploy/config.sh
	else
		. ./deploy/config.sh
	fi
	if [ "$RESTART_COMMAND" != "" ]; then
		title 'remote: starting application'
		echo "Restarting application"
		sh -c "$RESTART_COMMAND"
	fi
}
