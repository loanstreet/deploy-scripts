# If REPO_TYPE is unset, determine repo type from which to check out by repo url assigned to var REPO
ds_set_repo_type() {
	if [ "$REPO_TYPE" = "" ]; then
		REPO_STR=$(echo $REPO | cut -c -4)
		if [ "$REPO_STR" = "git@" ]; then
			REPO_TYPE="git"
		else
			error "Failed to determine REPO_TYPE for project checkout"
		fi
	fi
}

ds_exec_step() {
	# Checkout branch to be deployed into repo/ inside working dir
	ds_set_repo_type
	title "repo: checkout: $REPO_TYPE"
	ds_pre_step 'repo' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
	info "Creating repo to build program at $BUILD_REPO"
	# Get and run ds_repo_fetch() function for project repo type
	. "$SCRIPT_PATH/../steps/repo/lib/$REPO_TYPE.sh"
	ds_repo_fetch $REPO $BUILD_REPO
	ds_post_step 'repo' "$PROJECT_SCRIPTS_DIR" "$PROJECT_ENV_SCRIPTS_DIR"
}
