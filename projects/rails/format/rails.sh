ds_format() {
	if [ "$1" = "" ]; then
		error "format: rails: Too few arguments given"
	fi

	cd "$1"

	info "Preparing deployment files for packaging ... "
	git --work-tree=./ --git-dir=../repo/.git checkout -f 2>&1 | indent
	PID_PATH=$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/pids/$SERVICE_NAME.pid'
	SOCKET_PATH='unix://'$DEPLOYMENT_DIR'/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/tmp/sockets/$SERVICE_NAME.sock'
	if [ "$SERVICE_PORT" = "" ]; then
		COMMAND='$HOME/.rbenv/bin/rbenv exec bundle exec puma -C $DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/config/puma.rb --environment=$PROJECT_ENVIRONMENT --bind=$SOCKET_PATH --pidfile=$PID_PATH --daemon && sleep 3'
	else
		COMMAND='$HOME/.rbenv/bin/rbenv exec bundle exec puma -C $DEPLOYMENT_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT/current/config/puma.rb --environment=$PROJECT_ENVIRONMENT -p $SERVICE_PORT --pidfile=$PID_PATH --daemon && sleep 3'
	fi
	echo "PID_PATH=\"$PID_PATH\"" >> deploy-config.sh
	echo "SOCKET_PATH=\"$SOCKET_PATH\"" >> deploy-config.sh
	echo "START_COMMAND=\"$COMMAND\"" >> deploy-config.sh

	cat deploy-config.sh >> ./$INSTALL_DIR/config.sh
	success 'done'
}
