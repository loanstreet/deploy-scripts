ds_exec_step() {
	# Compile all the env vars into a config.sh to be added to the deployment files
	title "repo: files: copy"
	DEPLOY_FILES_DIR="$DEPLOY_PACKAGE_DIR/$DS_DIR"
	mkdir -p "$DEPLOY_FILES_DIR"
	DEPLOY_CONFIG_SH="$DEPLOY_FILES_DIR/config.sh"
	ds_cat_file $PROJECT_DEPLOY_DIR/app-config.sh $DEPLOY_CONFIG_SH
	ds_cat_file $CONFIG_SH_PATH $DEPLOY_CONFIG_SH

	# Copy other files from local system
	ds_copy_local_files "$DEPLOY_FILES_DIR" "$COPY_FILES"

	# Include deployment files location in the deployment config
	printf "DS_DIR=$DS_DIR\n" >> "$DEPLOY_CONFIG_SH"
	# Include project environment in the deployment config
	printf "PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT\n" >> "$DEPLOY_CONFIG_SH"
	# Include deployment directory in the deployment config
	printf "DEPLOYMENT_DIR=$DEPLOYMENT_DIR\n" >> "$DEPLOY_CONFIG_SH"

	INCLUDE_RUN_SH=$(echo $RESTART_COMMAND | grep 'run.sh' | wc -l)

	# If restart command used run.sh script, include it in the deployment
	if [ $INCLUDE_RUN_SH -gt 0 ]; then
		cp -v $SCRIPT_PATH/../steps/push/lib/post-deploy/run.sh "$DEPLOY_PACKAGE_DIR/$DS_DIR"
		printf "RESTART_COMMAND=\"sh ./$DS_DIR/run.sh restart\"\n" >> "$DEPLOY_CONFIG_SH"
	fi

	# Prepare the files for deployment using ds_format() depending on the project format (configured by var FORMAT)
	if [ "$FORMAT" != "" ]; then
		title "format: $FORMAT"
		ds_pre_step 'format' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
		. "$SCRIPT_PATH/../projects/$TYPE/format/$FORMAT.sh"
		ds_format $DEPLOY_PACKAGE_DIR
		ds_post_step 'format' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
	fi
	rm -rf "$DEPLOY_PACKAGE_DIR/deploy-config.sh"

	# Copy all files under project environment-specific assets/ dir to the deployment
	if [ -d "$DEPLOYMENT_ASSETS_DIR" ]; then
		EMPTY_CHECK=$(ls $DEPLOYMENT_ASSETS_DIR/ | wc -l)
		if [ $EMPTY_CHECK -gt 0 ]; then
			info "Copying assets ... "
			tar -ch -C "$DEPLOYMENT_ASSETS_DIR/" . | tar -xv -C "$DEPLOY_PACKAGE_DIR/$DS_DIR"
			success "done"
		fi
	fi
}
