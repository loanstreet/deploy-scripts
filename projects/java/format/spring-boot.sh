ds_format() {
	if [ "$1" = "" ]; then
		error "format: spring-boot: java: Too few arguments given"
	fi

	cd "$1"
	. ./deploy/config.sh

	if [ "$SERVICE_PORT" = "" ]; then
		error "package: java: config.sh must specify a SERVICE_PORT"
	fi

	PATH_TO_JAR=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/$WARFILE'
	echo "PATH_TO_JAR=\"$PATH_TO_JAR\"" >> deploy-config.sh
	LOG_DIR=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/logs'
	echo "LOG_DIR=\"$LOG_DIR\"" >> deploy-config.sh
	COMMAND='nohup java -Dspring.profiles.active=$PROJECT_ENVIRONMENT -jar $PATH_TO_JAR --server.port=$SERVICE_PORT /tmp 2>> $LOG_DIR/stderr.log >> $LOG_DIR/stdout.log'
	echo "START_COMMAND=\"$COMMAND\"" >> deploy-config.sh

	cat deploy-config.sh >> ./deploy/config.sh
}