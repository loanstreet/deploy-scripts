ds_push() {
	if [ "$1" = "" ]; then
		error "push: git: Too few arguments given to ds_push"
	fi

	if [ "$PUSH_DIR" = "" ]; then
		error "Push type PUSH=dir requires a PUSH_DIR variable set to the destination directory"
	fi

	cd "$1"
	info "Copying $PROJECT_ENVIRONMENT to $PUSH_DIR"
	mkdir -p "$PUSH_DIR"
	tar -ch -C "$1/" . | tar -xv -C "$PUSH_DIR"
}
