ds_push() {
	if [ "$1" = "" ]; then
		error "push: docker: Too few arguments given to ds_push"
	fi

	cd "$1"
	DOCKER_IMAGE=$(grep 'image:' docker-compose.yml | awk '{print $2}')
	docker --config $DOCKER_HOME login $DOCKER_REGISTRY
	if [ "$DOCKER_REGISTRY" != "" ]; then
		DOCKER_HOST=$(echo "$DOCKER_REGISTRY" | awk -F/ '{print $3}')
		DOCKER_LABEL=$(echo "$DOCKER_REGISTRY" | sed -e 's/^http:\/\///g' -e 's/^https:\/\///g')
		IMAGE_TAG="$DOCKER_LABEL/$DOCKER_IMAGE"
		docker tag $DOCKER_IMAGE "$IMAGE_TAG"
	else
		IMAGE_TAG="$DOCKER_IMAGE"
	fi
	info "Pushing $DOCKER_IMAGE"
	docker --config $DOCKER_HOME push $IMAGE_TAG

	if [ "$DOCKER_DELETE_LOCAL_IMAGE" = "true" ]; then
		info "Deleting $DOCKER_IMAGE from local repository"
		docker image rm -f "$IMAGE_TAG"
		if [ "$IMAGE_TAG" != "$DOCKER_IMAGE" ]; then
			docker image rm -f "$DOCKER_IMAGE"
		fi
	fi
}
