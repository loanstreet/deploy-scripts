ds_install () {
	if [ "$1" = "" ]; then
		error "installer: html: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "html"
	infof "Adding html vars to app-config.sh ... "
	printf "FORMAT=static\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_FILES=\"\"\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_DIRS=\"\"\n" >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
