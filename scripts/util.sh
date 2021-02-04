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
	echo "\n" >> "$2"
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
	printf "Custom post-receive hook ... "
	if [ "$DEPLOYMENT_SERVER" != "" ] && [ ! -f "$PROJECT_DIR/$PROJECT_ENVIRONMENT/git-hook-post-receive-$BUILD" ]; then
		warning "not found. Will use generic hook"
	else
		success "found"
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

	if [ "$DOCKER_ADD_SSH_KEY" != "" ]; then
		DOCKER_ADD_SSH_PUBLIC_KEY="$DOCKER_ADD_SSH_KEY.pub"
		if [ -f "$DOCKER_ADD_SSH_KEY" ] && [ -f "$DOCKER_ADD_SSH_KEY.pub" ]; then
			info "Copying keys ... "
			info "\t$DOCKER_ADD_SSH_KEY"
			info "\t$DOCKER_ADD_SSH_PUBLIC_KEY"
			cp "$DOCKER_ADD_SSH_KEY" $DESTINATION_DIR
			cp "$DOCKER_ADD_SSH_PUBLIC_KEY" $DESTINATION_DIR
			success "done"
		fi
	fi
}
