ds_package() {
	if [ "$1" = "" ]; then
		error "package: docker: Too few arguments given"
	fi

	cd "$1"

	copy_docker_files "$PROJECT_DEPLOY_DIR" $PROJECT_ENVIRONMENT "$1"

	docker-compose build
}
