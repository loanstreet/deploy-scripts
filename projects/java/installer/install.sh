ds_install () {
	if [ "$1" = "" ]; then
		error "installer: java: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "java"
	infof "Adding java vars to app-config.sh ... "
	echo "BUILD=mvnw\nFORMAT=spring-boot" >> "$1/$DS_DIR/app-config.sh"
	echo 'LINKED_FILES=""' >> "$1/$DS_DIR/app-config.sh"
	echo 'LINKED_DIRS="logs"' >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
