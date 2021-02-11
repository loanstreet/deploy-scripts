ds_install_py_uwsgi() {
	UWSGI_INI=$(cat <<-END
[uwsgi]
module = example.wsgi:application

master = true
processes = 5

chmod-socket = 666
vacuum = true

die-on-term = true
END
	)

	title "installer: python: uwsgi"
	UWSGI_INI_PATH="$1/$DS_DIR/environments/$INSTALL_ENV/assets/uwsgi.ini"
	infof "Creating uwsgi.ini file at $UWSGI_INI_PATH ... "
	printf "$UWSGI_INI" >> "$UWSGI_INI_PATH"
	success "done"
	warning "Configure $UWSGI_INI_PATH if using run.sh script to manage daemon"
}

ds_install () {
	if [ "$1" = "" ]; then
		error "installer: python: Project directory not supplied"
	fi

	ds_create_dir_structure "$1" "$DS_DIR" "python"
	infof "Adding python vars to app-config.sh ... "
	printf "FORMAT=django\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_FILES=\"\"\n" >> "$1/$DS_DIR/app-config.sh"
	printf "LINKED_DIRS=\"venv uploads logs public tmp/sockets tmp/pids\"\n" >> "$1/$DS_DIR/app-config.sh"
	success "done"

	ds_install_py_uwsgi "$1"
}
