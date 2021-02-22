ds_exec_step() {
	# Run post push tasks using ds_post_push()
	if [ "$POST_PUSH" != "" ]; then
		title "post-push: $POST_PUSH"
		ds_pre_step 'post-push' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
		. "$SCRIPT_PATH/../steps/post_push/lib/$POST_PUSH.sh"
		ds_post_push $DEPLOY_PACKAGE_DIR
		ds_post_step 'post-push' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
	fi
}