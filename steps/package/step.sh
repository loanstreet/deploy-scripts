ds_exec_step() {
	if [ "$PACKAGE" != "" ]; then
		# Package the deployment files in the desired format using ds_package() to be ready for delivery to deployment target
		title "package: $PACKAGE"
		ds_pre_step 'package' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
		. "$SCRIPT_PATH/../steps/package/lib/$PACKAGE.sh"
		ds_package $DEPLOY_PACKAGE_DIR
		ds_post_step 'package' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
	fi

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
}