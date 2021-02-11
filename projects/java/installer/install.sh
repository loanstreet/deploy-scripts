ds_install () {
	if [ "$1" = "" ]; then
		error "installer: java: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "java"
	infof "Adding java vars to app-config.sh ... "
	printf "BUILD=mvnw\nFORMAT=spring-boot\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_FILES=\"\"\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_DIRS=\"logs\"\n" >> "$1/$DS_DIR/app-config.sh"
	success "done"
}
