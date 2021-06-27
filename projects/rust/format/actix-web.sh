ds_format() {
	if [ "$1" = "" ]; then
		error "format: actix-web: rust: Too few arguments given"
	fi

	cd "$1"

	printf "Preparing actix-web deployment ... "
	PATH_TO_BIN=$DEPLOYMENT_DIR'/current/bin/$BINPATH'
	printf "PATH_TO_BIN=\"$PATH_TO_BIN\"\n" >> deploy-config.sh
	LOG_DIR=$DEPLOYMENT_DIR'/current/logs'
	printf "LOG_DIR=\"$LOG_DIR\"\n" >> deploy-config.sh
	COMMAND='nohup $PATH_TO_BIN 2>> $LOG_DIR/stderr.log >> $LOG_DIR/stdout.log'
	printf "START_COMMAND=\"$COMMAND\"\n" >> deploy-config.sh

	cat deploy-config.sh >> ./$DS_DIR/config.sh
	success 'done'
}
