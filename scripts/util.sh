indent() { sed 's/.*\r//g; s/^/  /'; }

line() {
	printf -- "\033[1;36m--------------------------------------------------------------------------------"
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

error() {
	printf "\033[1;31m$1\033[0m\n"
	exit
}

warning() {
	printf "\033[1;33m$1\033[0m\n"
}

structure_error_stop() {
	error "Error encountered in deploy script structure. Stopping."
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
