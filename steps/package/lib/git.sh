ds_package() {
	if [ "$1" = "" ]; then
		error "package: git: Too few arguments given"
	fi

	cd "$1"

	if [ "$DOCKERIZE" = "true" ]; then
		copy_docker_files "$PROJECT_DEPLOY_DIR" $PROJECT_ENVIRONMENT "$1"
	fi

	. "$SCRIPT_PATH/../steps/package/lib/git-resources/util.sh"

	ds_package_as_git_repo "$1"
}
