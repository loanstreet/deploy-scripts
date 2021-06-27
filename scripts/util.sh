indent() { sed 's/.*\r//g; s/^/  /'; }

line() {
	printf "\033[1;36m"
	if [ "$TERM" = "" ] || [ "$TERM" = "dumb" ]; then
		printf -- "------------------------------------------------------------------------"
	else
		printf %"$(tput cols)"s |tr " " "-"
	fi
	printf "\033[0m\n"
}

title() {
	line
	printf "\033[1;36m  $1\033[0m\n"
	line
}

info() {
	printf "\033[0m$1\n"
}

infof() {
	printf "\033[0m$1"
}

success() {
	printf "\033[1;32m$1\033[0m\n"
}

debug() {
	if [ "$DS_DEBUG" = "true" ]; then
		printf "\033[1;35m$1\033[0m\n"
	fi
}

error() {
	printf "\033[1;31m$1\033[0m\n"
	exit 1
}

warning() {
	printf "\033[1;33m$1\033[0m\n"
}

structure_error_stop() {
	error "Error encountered in deploy script structure. Stopping."
}

ds_cat_file() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "ds_cat_file: Need a source and a destination file"
	fi
	cat "$1" >> "$2"
	printf "\n" >> "$2"
}

check_structure() {
	PROJECT_DIR="$1"
	PROJECT_ENVIRONMENT="$2"
	# MSG=""
	printf "Project dir $PROJECT_DIR ... "
	if [ ! -d $PROJECT_DIR ]; then
		error "not found"
		structure_error_stop
	else
		success "found"
	fi
	printf "app-config.sh ... "
	if [ ! -f "$PROJECT_DIR/app-config.sh" ]; then
				error "not found"
		structure_error_stop
		else
				success "found"
		fi
	printf "Environment $PROJECT_ENVIRONMENT ... "
	if [ ! -d "$PROJECT_DIR/$PROJECT_ENVIRONMENT" ]; then
				error "not found"
		structure_error_stop
		else
				success "found"
		fi
	printf "$PROJECT_ENVIRONMENT/config.sh ... "
	if [ ! -f "$PROJECT_DIR/$PROJECT_ENVIRONMENT/config.sh" ]; then
				error "not found"
		structure_error_stop
		else
				success "found"
		fi
	. $PROJECT_DIR/app-config.sh
	printf "Custom post-receive hook ... "
	if [ ! -f "$PROJECT_DIR/$PROJECT_ENVIRONMENT/git-hook-post-receive-$BUILD" ]; then
				warning "not found. Will use generic hook"
		else
				success "found"
		fi
}

check_structure_ver_03() {
	PROJECT_DIR="$1"
	PROJECT_ENVIRONMENT="$2"
	# MSG=""
	printf "Project dir $PROJECT_DIR ... "
	if [ ! -d $PROJECT_DIR ]; then
		error "not found"
		structure_error_stop
	else
		success "found"
	fi
	printf "app-config.sh ... "
	if [ ! -f "$PROJECT_DIR/app-config.sh" ]; then
		error "not found"
		structure_error_stop
	else
		success "found"
	fi
	printf "Environment $PROJECT_ENVIRONMENT ... "
	if [ ! -d "$PROJECT_DIR/environments/$PROJECT_ENVIRONMENT" ]; then
		error "not found"
		structure_error_stop
	else
		success "found"
	fi
	printf "$PROJECT_ENVIRONMENT/config.sh ... "
	if [ ! -f "$PROJECT_DIR/environments/$PROJECT_ENVIRONMENT/config.sh" ]; then
		error "not found"
		structure_error_stop
	else
		success "found"
	fi
	. $PROJECT_DIR/app-config.sh
	# printf "Custom post-receive hook ... "
	# if [ "$DEPLOYMENT_SERVER" != "" ] && [ ! -f "$PROJECT_DIR/$PROJECT_ENVIRONMENT/git-hook-post-receive-$BUILD" ]; then
	# 	warning "not found. Will use generic hook"
	# else
	# 	success "found"
	# fi
}

ds_pre_step() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		return
	fi
	CUR=$(pwd)
	PRE_STEP_SCRIPT="$2/$1.sh"
	HOOK_SCRIPT_DIR="$2"
	if [ "$3" != "" ] && [ -f "$3/$1.sh" ]; then
		PRE_STEP_SCRIPT="$3/$1.sh"
		HOOK_SCRIPT_DIR="$3"
	fi
	if [ -f "$PRE_STEP_SCRIPT" ]; then
		. "$PRE_STEP_SCRIPT"
		DEFINED=$(grep 'ds_pre' $PRE_STEP_SCRIPT | awk '{print $1}')
		if [ "$DEFINED" != "" ]; then
			cd $HOOK_SCRIPT_DIR
			info "Pre-$1 script:"
			ds_pre
			info "End pre-$1 script:"
			cd $CUR
		fi
	fi
}

ds_post_step() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		return
	fi
	CUR=$(pwd)
	POST_STEP_SCRIPT="$2/$1.sh"
	HOOK_SCRIPT_DIR="$2"
	if [ "$3" != "" ] && [ -f "$3/$1.sh" ]; then
		POST_STEP_SCRIPT="$3/$1.sh"
		HOOK_SCRIPT_DIR="$3"
	fi
	if [ -f "$POST_STEP_SCRIPT" ]; then
		. "$POST_STEP_SCRIPT"
		DEFINED=$(grep 'ds_post' $PRE_STEP_SCRIPT | awk '{print $1}')
		if [ "$DEFINED" != "" ]; then
			cd $HOOK_SCRIPT_DIR
			info "Post-$1 script:"
			ds_post
			info "End post-$1 script:"
			cd $CUR
		fi
	fi
}

ds_debug_cat() {
	if [ "$1" = "" ]; then
		return
	fi
	CONT=$(cat $1)
	debug "$CONT"
}

ds_debug_exec() {
	if [ "$1" = "" ]; then
		return
	fi
	CONT=$(sh -c "$1")
	debug "$CONT"
}

ds_copy_local_files() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		return
	fi

	LOCAL_FILES_COPY_DIR="$1/files"
	mkdir -p "$LOCAL_FILES_COPY_DIR"
	if [ "$2" != "" ]; then
			COPY_FILE_LIST=$(echo "$2" | cut -d";" -f1)
			for i in $COPY_FILE_LIST; do
				cp -rv $i $LOCAL_FILES_COPY_DIR/
			done
	fi
}

copy_docker_files() {
	PROJECT_DIR="$1"
	PROJECT_ENVIRONMENT="$2"
	DESTINATION_DIR="$3"

	debug "$PROJECT_DIR/$PROJECT_ENVIRONMENT"
	if [ ! -d "$PROJECT_DIR/environments/$PROJECT_ENVIRONMENT" ]; then
		error "Environment directory for $PROJECT_ENVIRONMENT not found"
		structure_error_stop
	fi

	if [ ! -d "$DESTINATION_DIR" ]; then
		error "Deploy repo dir $DESTINATION_DIR not found"
		structure_error_stop
	fi

	PROJECT_DOCKERFILE_PATH="$PROJECT_DIR/docker/Dockerfile"
	PROJECT_DOCKER_COMPOSE_PATH="$PROJECT_DIR/docker/docker-compose.yml"
	DOCKERFILE_PATH="$PROJECT_DIR/environments/$PROJECT_ENVIRONMENT/docker/Dockerfile"
	DOCKER_COMPOSE_PATH="$PROJECT_DIR/environments/$PROJECT_ENVIRONMENT/docker/docker-compose.yml"

	if [ -f "$DOCKERFILE_PATH" ]; then
		info "Copying Dockerfile $DOCKERFILE_PATH to $DESTINATION_DIR"
		cp $DOCKERFILE_PATH $DESTINATION_DIR
	elif [ -f "$PROJECT_DOCKERFILE_PATH" ]; then
		info "Copying generic Dockerfile $PROJECT_DOCKERFILE_PATH to $DESTINATION_DIR"
		cp $PROJECT_DOCKERFILE_PATH $DESTINATION_DIR
	else
		error "No Dockerfile found"
		structure_error_stop
	fi

	if [ -f "$DOCKER_COMPOSE_PATH" ]; then
			info "Copying docker-compose file $DOCKER_COMPOSE_PATH to $DESTINATION_DIR"
			cp $DOCKER_COMPOSE_PATH $DESTINATION_DIR
	elif [ -f "$PROJECT_DOCKER_COMPOSE_PATH" ]; then
			info "Copying generic docker-compose file $PROJECT_DOCKER_COMPOSE_PATH to $DESTINATION_DIR"
			cp $PROJECT_DOCKER_COMPOSE_PATH $DESTINATION_DIR
	else
			error "No docker-compose.yml found"
			structure_error_stop
	fi

	KEY_DESTINATION_DIR="$DESTINATION_DIR/$DS_DIR/files"
	mkdir -p "$KEY_DESTINATION_DIR"

	if [ "$DOCKER_ADD_SSH_KEY" != "" ]; then
		DOCKER_ADD_SSH_PUBLIC_KEY="$DOCKER_ADD_SSH_KEY.pub"
		if [ -f "$DOCKER_ADD_SSH_KEY" ] && [ -f "$DOCKER_ADD_SSH_KEY.pub" ]; then
			info "Copying keys ... "
			cp -v "$DOCKER_ADD_SSH_KEY" $KEY_DESTINATION_DIR/id_rsa
			cp -v "$DOCKER_ADD_SSH_PUBLIC_KEY" $KEY_DESTINATION_DIR/id_rsa.pub
			success "done"
		fi
	fi

	if [ "$PACKAGE_DOCKERIGNORE" != "false" ]; then
		DOCKERIGNORE_FILE="$DESTINATION_DIR/.dockerignore"
		if [ ! -f "$DOCKERIGNORE_FILE" ]; then
			printf "Dockerfile\ndocker-compose.yml\n" >> $DOCKERIGNORE_FILE
		fi
	fi
}

cleanup_docker_files() {
	KEY_DESTINATION_DIR="$DESTINATION_DIR/$DS_DIR/files"
	rm -rf "$KEY_DESTINATION_DIR/id_rsa" "$KEY_DESTINATION_DIR/id_rsa.pub"
}

copy_local_project_for_build() {
	if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]; then
		error "Insufficient args supplied to copy_local_project_for_build"
	fi
	mkdir -p $2
	cd $1 && tar -cf "$3/project.tar" . && cd $3
	tar -xf project.tar -C $2/
	cd $1
}
