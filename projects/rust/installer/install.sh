ds_install () {
	if [ "$1" = "" ]; then
		error "installer: rust: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "rust"
	infof "Adding rust vars to app-config.sh ... "
	printf "BUILD=cargo\nFORMAT=actix-web\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_FILES=\"\"\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_DIRS=\"logs\"\n" >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
