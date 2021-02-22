ds_exec_step() {
	# Push the packaged deployment files using ds_push() to the deployment server
	ds_set_push_type
	if [ "$PUSH" != "" ]; then
		title "push: $PUSH"
		ds_pre_step 'push' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
		. "$SCRIPT_PATH/../steps/push/lib/$PUSH.sh"
		ds_push $DEPLOY_PACKAGE_DIR $PROJECT_TYPE_DIR
		ds_post_step 'push' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
	fi
}