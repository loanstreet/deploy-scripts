ds_install () {
	if [ "$1" = "" ]; then
		error "installer: node: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "node"
	infof "Adding reactjs vars to app-config.sh ... "
	printf "FORMAT=node\nLINKED_DIRS=\"logs\"\n" >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
