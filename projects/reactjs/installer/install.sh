ds_install () {
	if [ "$1" = "" ]; then
		error "installer: reactjs: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "reactjs"
	infof "Adding reactjs vars to app-config.sh ... "
	printf "BUILD=npm\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_FILES=\"src/_config/env.js\"\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_DIRS=\"logs\"\n" >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
