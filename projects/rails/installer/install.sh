ds_install () {
	if [ "$1" = "" ]; then
		error "installer: rails: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "rails"
	infof "Adding rails vars to app-config.sh ... "
	echo "FORMAT=rails" >> "$1/$DS_DIR/app-config.sh"
	echo 'LINKED_FILES="config/database.yml"' >> "$1/$DS_DIR/app-config.sh"
	echo 'LINKED_DIRS="log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system"' >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
