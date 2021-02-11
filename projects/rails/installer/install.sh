ds_install () {
	if [ "$1" = "" ]; then
		error "installer: rails: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "rails"
	infof "Adding rails vars to app-config.sh ... "
	printf "FORMAT=rails\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_FILES=\"config/database.yml\"\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_DIRS=\"log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system\"\n" >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
