ds_push() {
	if [ "$1" = "" ]; then
		error "push: docker: Too few arguments given to ds_push"
	fi

	cd "$1"
	if [ "$DOCKER_REGISTRY" = "" ]; then
		error "No DOCKER_REGISTRY var set for PUSH=docker"
	fi
	DOCKER_IMAGE=$(grep 'image:' docker-compose.yml | awk '{print $2}')
	docker login $DOCKER_REGISTRY
	DOCKER_HOST=$(echo "$DOCKER_REGISTRY" | awk -F/ '{print $3}')
	docker tag $DOCKER_IMAGE "$DOCKER_HOST/$DOCKER_IMAGE"
	info "Pushing $DOCKER_IMAGE to $DOCKER_HOST"
	docker push "$DOCKER_HOST/$DOCKER_IMAGE"
}
