ds_push() {
	if [ "$1" = "" ]; then
		error "push: docker: Too few arguments given to ds_push"
	fi

	cd "$1"
	if [ "$DOCKER_REGISTRY" = "" ]; then
		error "No DOCKER_REGISTRY var set for PUSH=docker"
	fi
	DOCKER_IMAGE=$(grep 'image:' docker-compose.yml | awk '{print $2}')
	docker --config $DOCKER_HOME login $DOCKER_REGISTRY
	DOCKER_HOST=$(echo "$DOCKER_REGISTRY" | awk -F/ '{print $3}')
	DOCKER_LABEL=$(echo "$DOCKER_REGISTRY" | sed -e 's/^http:\/\///g' -e 's/^https:\/\///g')
	IMAGE_TAG="$DOCKER_LABEL/$DOCKER_IMAGE"
	docker tag $DOCKER_IMAGE "$IMAGE_TAG"
	info "Pushing $DOCKER_IMAGE to $DOCKER_HOST"
	docker push $IMAGE_TAG

	if [ "$DOCKER_DELETE_LOCAL_IMAGE" = "true" ]; then
		info "Deleting $DOCKER_IMAGE from local repository"
		docker image rm -f "$IMAGE_TAG" "$DOCKER_IMAGE"
	fi
}
