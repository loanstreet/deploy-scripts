ds_push() {
	if [ "$1" = "" ]; then
		error "push: git: Too few arguments given to ds_push"
	fi

	cd "$1"
	if [ "$DEPLOY_BRANCH" = "" ]; then
		DEPLOY_BRANCH=$PROJECT_ENVIRONMENT
	fi
	git checkout -b $DEPLOY_BRANCH
	info "Deploying $PROJECT_ENVIRONMENT to $DEPLOYMENT_SERVER"
	git remote add deploy $DEPLOYMENT_SERVER 2>&1 | indent
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push -u deploy $DEPLOY_BRANCH -f
}
