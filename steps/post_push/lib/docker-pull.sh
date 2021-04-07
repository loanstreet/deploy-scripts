ds_post_push() {
	if [ "$1" = "" ]; then
		error "post-push: docker-pull: Too few arguments given to ds_post_push"
	fi

	cd "$1"

	if [ "$DEPLOYMENT_SERVER" = "" ] || [ "$DEPLOYMENT_SERVER_USER" = "" ]; then
		error "post-push: docker-pull: Please set DEPLOYMENT_SERVER and DEPLOYMENT_SERVER_USER to perform server side docker image pull"
	fi

	cd "$1"
	if [ ! -f "docker-compose.yml" ]; then
		error "post-push: docker-pull: No docker-compose.yml generated during build to push to server"
	fi

	. "$SCRIPT_PATH/../steps/push/lib/git-bare-resources/util.sh"

	ds_create_bare_repo "$1" "$SCRIPT_PATH/../steps/post_push/lib/docker-pull-resources/post-receive-hook"

	# Do this more cleanly
	mv deploy ../ && mv docker-compose.yml ../ && rm -rf ./* && mv ../deploy ./ && mv ../docker-compose.yml ./

	if [ "$DOCKER_REGISTRY" != "" ]; then
		REGISTRY_PREFIX=$(echo $DOCKER_REGISTRY | sed 's/^[^//]*\/\///g')
		sed -i "s/image:[^a-zA-Z0-9]*/image: $REGISTRY_PREFIX\//g" docker-compose.yml
	fi

	. "$SCRIPT_PATH/../steps/package/lib/git-resources/util.sh"

	ds_package_as_git_repo "$1"

	info "Deploying docker-compose.yml to $DEPLOYMENT_SERVER"
	REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER:$DEPLOYMENT_SERVER_PORT/~/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
	git remote add deploy $REMOTE_GIT_BARE_REPO 2>&1 | indent
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push -u deploy $DEPLOY_BRANCH -f

	success "done"
}