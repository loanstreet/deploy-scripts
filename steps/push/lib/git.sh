ds_push() {
	if [ "$1" = "" ]; then
		error "push: git: Too few arguments given to ds_push"
	fi

	cd "$1"
	if [ "$DEPLOY_BRANCH" = "" ]; then
		DEPLOY_BRANCH=$PROJECT_ENVIRONMENT
	fi
	git checkout -b $DEPLOY_BRANCH
	SERVER_LIST=$(echo $DEPLOYMENT_SERVER | cut -d";" -f1)
	for b in $SERVER_LIST; do
		info "Deploying $PROJECT_ENVIRONMENT to $b"
		git remote add deploy $b 2>&1 | indent
		GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push -u deploy $DEPLOY_BRANCH -f
		git remote remove deploy 2>&1 | indent
	fi
}
