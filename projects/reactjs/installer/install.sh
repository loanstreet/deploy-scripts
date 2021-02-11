ds_install () {
	if [ "$1" = "" ]; then
		error "installer: reactjs: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "reactjs"
	infof "Adding reactjs vars to app-config.sh ... "
	echo "BUILD=npm" >> "$1/$DS_DIR/app-config.sh"
	echo 'LINKED_FILES="src/_config/env.js"' >> "$1/$DS_DIR/app-config.sh"
	echo 'LINKED_DIRS="logs"' >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
