structure_error_stop() {
	echo "Error encountered in deploy script structure. Stopping."
	exit
}

check_structure() {
	PROJECT_DIR="$1"
	PROJECT_ENVIRONMENT="$2"
	printf "Project dir $PROJECT_DIR ... "
	if [ ! -d $PROJECT_DIR ]; then
		echo "not found"
		structure_error_stop
	else
		echo "found"
	fi
	printf "app-config.sh ... "
	if [ ! -f "$PROJECT_DIR/app-config.sh" ]; then
                echo "not found"
		structure_error_stop
        else
                echo "found"
		. $PROJECT_DIR
        fi
	printf "Environment $PROJECT_ENVIRONMENT ... "
	if [ ! -d "$PROJECT_DIR/$PROJECT_ENVIRONMENT" ]; then
                echo "not found"
		structure_error_stop
        else
                echo "found"
        fi
	printf "$PROJECT_ENVIRONMENT/config.sh ... "
	if [ ! -f "$PROJECT_DIR/$PROJECT_ENVIRONMENT/config.sh" ]; then
                echo "not found"
		structure_error_stop
        else
                echo "found"
        fi
	. $PROJECT_DIR/app-config.sh
	printf "Custom post-receive hook ... "
	if [ ! -f "$PROJECT_DIR/$PROJECT_ENVIRONMENT/git-hook-post-receive-$BUILD" ]; then
                echo "not found. Will use generic hook"
        else
                echo "found"
        fi
}
