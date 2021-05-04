ds_package() {
	if [ "$1" = "" ]; then
		error "package: zip: Too few arguments given"
	fi

	cd "$1"

	zip -r "$SERVICE_NAME-$PROJECT_ENVIRONMENT.zip" ./
}
