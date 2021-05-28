ds_package() {
	if [ "$1" = "" ]; then
		error "package: docker: Too few arguments given"
	fi

	cd "$1"

	copy_docker_files "$PROJECT_DEPLOY_DIR" $PROJECT_ENVIRONMENT "$1"

	TAG=$(grep 'image:' docker-compose.yml | wc -l)

	if [ $TAG -eq 0 ]; then
		TIMESTAMP=$(date +%Y%m%d%H%M%S)
		SRV_NAME=$(echo $SERVICE_NAME | cut -d"." -f1)
		TAG="$SRV_NAME-$PROJECT_ENVIRONMENT:$TIMESTAMP"
		BUILDSTR=$(grep 'build:' docker-compose.yml)
		if [ "$BUILDSTR" != "" ]; then
			sed -i "s/build\:/image\: $TAG\n$BUILDSTR/g" docker-compose.yml
		fi
		ds_debug_cat "docker-compose.yml"
	else
		TAG=$(grep 'image:' docker-compose.yml | awk '{print $2}')
	fi

	docker-compose build $DOCKER_COMPOSE_OPTS

	cleanup_docker_files
}
