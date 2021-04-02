ds_push() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "push: git-bare: Too few arguments given to ds_push"
	fi

	cd "$1"

	REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER:$DEPLOYMENT_SERVER_PORT/~/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git

	info "Deploying $PROJECT_ENVIRONMENT to $REMOTE_GIT_BARE_REPO"

	cd "$1"

	POST_RECEIVE_HOOK="$2/push/git-bare/post-receive-hook"
	ENV_POST_RECEIVE_HOOK="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/post-receive"
	PROJECT_POST_RECEIVE_HOOK="$PROJECT_DEPLOY_DIR/post-receive"
	if [ -f "$ENV_POST_RECEIVE_HOOK" ]; then
		POST_RECEIVE_HOOK="$ENV_POST_RECEIVE_HOOK"
	elif [ -f "$PROJECT_POST_RECEIVE_HOOK" ]; then
		POST_RECEIVE_HOOK="$PROJECT_POST_RECEIVE_HOOK"
	fi

	. "$SCRIPT_PATH/../steps/push/lib/git-bare-resources/util.sh"

	ds_create_bare_repo "$1" "$POST_RECEIVE_HOOK"

	git remote add deploy $REMOTE_GIT_BARE_REPO 2>&1 | indent
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push -u deploy $DEPLOY_BRANCH -f
}
