ds_format() {
	if [ "$1" = "" ]; then
		error "format: django: Too few arguments given"
	fi

	cd "$1"

	info "Preparing deployment files for packaging ... "
	git --work-tree=./ --git-dir=../repo/.git checkout -f 2>&1 | indent
	rm -rf "$1/$DS_DIR"/*
	PID_PATH=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/pids/$SERVICE_NAME.pid'
	SOCKET_PATH=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/sockets/$PROJECT_ENVIRONMENT.sock'
	UWSGI_LOG_PATH=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/logs/uwsgi.log'
	COMMAND='cd $DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current'
	echo "PID_PATH=\"$PID_PATH\"" >> deploy-config.sh
	echo "SOCKET_PATH=\"$SOCKET_PATH\"" >> deploy-config.sh
	echo "UWSGI_LOG_PATH=\"$UWSGI_LOG_PATH\"" >> deploy-config.sh
	if [ "$SERVICE_PORT" = "" ]; then
		echo "START_COMMAND=\"$COMMAND && /bin/bash -c 'source venv/bin/activate && uwsgi --ini deploy/uwsgi.ini -s $SOCKET_PATH --pidfile $PID_PATH -d $UWSGI_LOG_PATH' && sleep 5\"" >> deploy-config.sh
	else
		echo "START_COMMAND=\"$COMMAND && /bin/bash -c 'source venv/bin/activate && uwsgi --ini deploy/uwsgi.ini --http :$SERVICE_PORT --pidfile $PID_PATH -d $UWSGI_LOG_PATH' && sleep 5\"" >> deploy-config.sh
	fi

	cat deploy-config.sh >> ./$DS_DIR/config.sh
	success 'done'
}
