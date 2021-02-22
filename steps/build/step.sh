ds_exec_step() {
	# Execute any custom pre-build scripts
	# pre_build.sh to be deprecated in favour of pre and post step scripts
	if [ -f $PROJECT_SCRIPTS_DIR/pre_build.sh ]; then
		title 'build: pre build script'
		sh $PROJECT_SCRIPTS_DIR/pre_build.sh
	fi

	# Find and execute ds_build() function to build the files for deployment (configured by var BUILD)
	if [ "$BUILD" != "" ]; then
		title "build: $BUILD"
		ds_pre_step 'build' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
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
		ds_post_step 'build' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
	fi
}
