ds_format() {
	if [ "$1" = "" ]; then
		error "format: django: Too few arguments given"
	fi

	cd "$1"

	info "Preparing deployment files for packaging ... "
	git --work-tree=./ --git-dir=../repo/.git checkout -f 2>&1 | indent
	PID_PATH=$DEPLOYMENT_DIR'/current/tmp/pids/$SERVICE_NAME.pid'
	SOCKET_PATH=$DEPLOYMENT_DIR'/current/tmp/sockets/$PROJECT_ENVIRONMENT.sock'
	UWSGI_LOG_PATH=$DEPLOYMENT_DIR'/current/logs/uwsgi.log'
	COMMAND='cd $DEPLOYMENT_DIR/current'
	printf "PID_PATH=\"$PID_PATH\"\n" >> deploy-config.sh
	printf "SOCKET_PATH=\"$SOCKET_PATH\"\n" >> deploy-config.sh
	printf "UWSGI_LOG_PATH=\"$UWSGI_LOG_PATH\"\n" >> deploy-config.sh
	if [ "$SERVICE_PORT" = "" ]; then
		printf "START_COMMAND=\"$COMMAND && /bin/bash -c 'source venv/bin/activate && uwsgi --ini deploy/uwsgi.ini -s $SOCKET_PATH --pidfile $PID_PATH -d $UWSGI_LOG_PATH' && sleep 5\"\n" >> deploy-config.sh
	else
		printf "START_COMMAND=\"$COMMAND && /bin/bash -c 'source venv/bin/activate && uwsgi --ini deploy/uwsgi.ini --http :$SERVICE_PORT --pidfile $PID_PATH -d $UWSGI_LOG_PATH' && sleep 5\"\n" >> deploy-config.sh
	fi

	cat deploy-config.sh >> ./$DS_DIR/config.sh
	success 'done'
}
